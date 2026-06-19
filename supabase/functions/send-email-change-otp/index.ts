import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { decryptAesGcmSeparatedTag } from "./crypto.ts";
import {
  sha256Hex,
  buildSignatureBase,
  loadHmacKeyFromBase64UrlEnv,
  signHmacSha256Hex,
  createGasIdempotencyKey,
  createCorrelationId
} from "./signing.ts";

declare const Deno: any;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export async function handler(req: Request): Promise<Response> {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 2. Aceita apenas POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "method_not_allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  // 3. Gerar Correlation ID operacional para rastreio
  const correlationId = createCorrelationId();

  try {
    // 4. Validar JWT no cabeçalho Authorization
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error(`[Correlation ID: ${correlationId}] Configuração de ambiente ausente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia cliente anon para validar o token
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // O auth_user_id derivado do JWT é nossa autoridade
    const authUserId = user.id;

    // 5. Ler parâmetros operacionais mínimos do body e validar chaves proibidas
    const body = await req.json();

    if ("user_id" in body || "auth_user_id" in body) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { cycle_id, challenge_id } = body;

    if (!cycle_id || !challenge_id) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Instanciar Supabase Admin client com service role
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      console.error(`[Correlation ID: ${correlationId}] SUPABASE_SERVICE_ROLE_KEY ausente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // 7. Invocar claim do envio do OTP no banco
    const { data: claimData, error: claimError } = await supabaseAdmin.rpc(
      "conectea_claim_email_change_challenge_delivery_v1",
      {
        p_user_id: authUserId,
        p_cycle_id: cycle_id,
        p_challenge_id: challenge_id
      }
    );

    if (claimError || !claimData) {
      console.error(`[Correlation ID: ${correlationId}] Falha de execução da RPC de claim.`);
      return new Response(
        JSON.stringify({ error: "claim_failed" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Se o banco negou o claim (por lease ativo, cutoff expirado etc.), retorna sanitizado
    if (claimData.claimed !== true) {
      return new Response(
        JSON.stringify({ claimed: false, result: claimData.result }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Descriptografar e-mail de destino e código OTP em memória
    let decryptedEmail: string;
    let decryptedOtp: string;

    try {
      decryptedEmail = await decryptAesGcmSeparatedTag({
        ciphertext: claimData.destination_ciphertext,
        nonce: claimData.destination_nonce,
        authTag: claimData.destination_auth_tag,
        keyVersion: claimData.destination_encryption_key_version
      });

      decryptedOtp = await decryptAesGcmSeparatedTag({
        ciphertext: claimData.code_ciphertext,
        nonce: claimData.code_nonce,
        authTag: claimData.code_auth_tag,
        keyVersion: claimData.code_encryption_key_version
      });
    } catch (_decryptErr) {
      console.error(`[Correlation ID: ${correlationId}] Falha na integridade ou descriptografia do material do OTP.`);
      return new Response(
        JSON.stringify({ claimed: false, error: "decrypt_failed" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 9. Montar assunto, corpo do e-mail e obter chave de idempotência opaca
    const subject = "Confirmação de Alteração de E-mail — ConeCTEA";
    const bodyText = `Olá!\n\nVocê solicitou a alteração do seu e-mail no aplicativo ConeCTEA.\nCódigo de Confirmação: ${decryptedOtp}\n\nEste código expira em 15 minutos.\nSe você não solicitou essa alteração, ignore este e-mail.`;

    const idempotencySecretKey = await loadHmacKeyFromBase64UrlEnv("CONECTEA_IDEMPOTENCY_SECRET_KEY");
    const idempotencyKey = await createGasIdempotencyKey({
      secretKey: idempotencySecretKey,
      purpose: "email_change",
      challengeId: challenge_id,
      sendSequence: claimData.send_sequence
    });

    // 10. Montar payload do GAS (sem material criptográfico do banco)
    const gasPayload = {
      purpose: "email_change",
      idempotency_key: idempotencyKey,
      send_sequence: claimData.send_sequence,
      recipient_email: decryptedEmail,
      subject: subject,
      body_text: bodyText,
      correlation_id: correlationId
    };

    const canonicalPayload = canonicalizeObject(gasPayload);
    const bodySha256 = await sha256Hex(canonicalPayload);
    const timestamp = new Date().toISOString();
    const kid = Deno.env.get("CONECTEA_EDGE_GAS_SIGNING_KID") ?? "kid_default";

    // 11. Computar assinatura simétrica HMAC-SHA256
    const baseString = buildSignatureBase({
      method: "POST",
      logicalPath: "email-change/send-otp/v1",
      version: "1",
      kid: kid,
      timestamp: timestamp,
      bodySha256: bodySha256
    });

    const signingKey = await loadHmacKeyFromBase64UrlEnv("CONECTEA_EDGE_GAS_SIGNING_KEY");
    const signature = await signHmacSha256Hex({ key: signingKey, baseString });

    const envelope = {
      meta: {
        signature_version: "1",
        signature_kid: kid,
        signature_timestamp: timestamp,
        logical_path: "email-change/send-otp/v1",
        payload_sha256: bodySha256,
        signature: signature,
        correlation_id: correlationId
      },
      payload: gasPayload
    };

    const envelopeString = JSON.stringify(envelope);

    // 12. Fazer requisição síncrona HTTP ao GAS com envelope e headers mínimos
    const gasUrl = Deno.env.get("CONECTEA_GAS_URL") ?? "";
    const headers = {
      "Content-Type": "application/json"
    };

    const abortController = new AbortController();
    const timeoutId = setTimeout(() => abortController.abort(), 20000);

    let gasResponse: Response;
    try {
      gasResponse = await fetch(gasUrl, {
        method: "POST",
        headers: headers,
        body: envelopeString,
        signal: abortController.signal
      });
    } catch (_fetchErr) {
      console.warn(`[Correlation ID: ${correlationId}] Timeout ou erro de rede ao chamar o GAS.`);
      return new Response(
        JSON.stringify({ claimed: true, status: "failed_temporary", error: "gas_network_failure" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } finally {
      clearTimeout(timeoutId);
    }

    if (!gasResponse.ok) {
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status HTTP inválido: ${gasResponse.status}`);
      return new Response(
        JSON.stringify({ claimed: true, status: "failed_temporary", error: "gas_http_failure" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const gasResult = await gasResponse.json();
    const rawGasStatus = gasResult?.status;
    const fencingToken = claimData.delivery_attempts;

    const whitelist = [
      "sent",
      "already_sent",
      "failed_pre_send_invalid_destination",
      "attempt_reserved",
      "ambiguous_attempted",
      "temporary_failure",
      "invalid_signature",
      "invalid_request"
    ];

    const isKnown = typeof rawGasStatus === "string" && whitelist.includes(rawGasStatus);

    if (!isKnown) {
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status desconhecido. Sem consolidação.`);
      return new Response(
        JSON.stringify({ claimed: true, status: "failed_temporary", error: "gas_unknown_status" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const gasStatus = rawGasStatus;

    if (gasStatus === "invalid_signature" || gasStatus === "invalid_request") {
      console.warn(`[Correlation ID: ${correlationId}] GAS recusou a requisição (${gasStatus}). Sem consolidação.`);
      return new Response(
        JSON.stringify({ claimed: true, status: "failed_temporary", error: `gas_${gasStatus}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 13. Mapeamento de consolidação conforme regras
    if (gasStatus === "sent" || gasStatus === "already_sent") {
      // Chamar RPC mark_sent no banco
      const { error: markErr } = await supabaseAdmin.rpc(
        "conectea_mark_email_change_challenge_sent_v1",
        {
          p_user_id: authUserId,
          p_cycle_id: cycle_id,
          p_challenge_id: challenge_id,
          p_expected_delivery_attempts: fencingToken
        }
      );
      if (markErr) {
        console.error(`[Correlation ID: ${correlationId}] Falha de consolidação mark_sent no banco.`);
      }
      return new Response(
        JSON.stringify({ claimed: true, status: "sent" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (gasStatus === "failed_pre_send_invalid_destination") {
      // Chamar RPC mark_failed no banco com motivo restrito
      const { error: markErr } = await supabaseAdmin.rpc(
        "conectea_mark_email_change_challenge_failed_v1",
        {
          p_user_id: authUserId,
          p_cycle_id: cycle_id,
          p_challenge_id: challenge_id,
          p_expected_delivery_attempts: fencingToken,
          p_failure_reason_private: "invalid_destination_permanent"
        }
      );
      if (markErr) {
        console.error(`[Correlation ID: ${correlationId}] Falha de consolidação mark_failed no banco.`);
      }
      return new Response(
        JSON.stringify({ claimed: true, status: "failed_permanent", reason: "invalid_destination_permanent" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Para qualquer outra resposta temporária (attempt_reserved, ambiguous_attempted etc.) da whitelist,
    // não chamamos consolidador. O banco permanece em sending permitindo retry.
    console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status temporário: ${gasStatus}. Sem consolidação.`);
    return new Response(
      JSON.stringify({ claimed: true, status: "failed_temporary", reason: gasStatus }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error(`[Correlation ID: ${correlationId}] Erro interno na Edge Function.`);
    return new Response(
      JSON.stringify({ error: "internal_server_error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

export function canonicalizeObject(obj: any): string {
  if (obj === null || typeof obj !== "object") {
    return JSON.stringify(obj);
  }
  if (Array.isArray(obj)) {
    const parts: string[] = [];
    for (let i = 0; i < obj.length; i++) {
      parts.push(canonicalizeObject(obj[i]));
    }
    return "[" + parts.join(",") + "]";
  }
  const keys = Object.keys(obj).sort();
  const parts: string[] = [];
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const val = obj[key];
    parts.push(JSON.stringify(key) + ":" + canonicalizeObject(val));
  }
  return "{" + parts.join(",") + "}";
}

if ((import.meta as any).main) {
  serve(handler);
}
