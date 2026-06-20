import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  normalizeEmail,
  maskEmail,
  generateOtp,
  generateHmacSha256,
  encryptAes256Gcm
} from "./crypto_material.ts";
import { sendExistingEmailChangeOtp } from "../send-email-change-otp/delivery.ts";
import { createCorrelationId } from "../send-email-change-otp/signing.ts";

declare const Deno: any;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/**
 * Decodifica de forma segura a claim do JWT para obter o session_id já validado.
 */
function getSessionIdFromJwt(authHeader: string): string {
  const token = authHeader.substring(7); // Remove "Bearer "
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new Error("invalid_jwt_format");
  }
  const payloadJson = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
  const payload = JSON.parse(payloadJson);
  const sessionId = payload.session_id;
  if (!sessionId) {
    throw new Error("session_id_missing");
  }
  return sessionId;
}

/**
 * Computa uma chave de idempotência determinística no formato UUID v4 a partir de dados estáveis da requisição.
 */
async function createDeterministicIdempotencyKey(params: {
  userId: string;
  sessionId: string;
  newEmail: string;
  secretKeyBase64Url: string;
}): Promise<string> {
  const rawHmac = await generateHmacSha256({
    secretKeyBase64Url: params.secretKeyBase64Url,
    domainPrefix: "conectea:email_change:idempotency_uuid:v1:",
    message: `${params.userId}:${params.sessionId}:${params.newEmail}`
  });
  const hex = rawHmac.substring(0, 32);
  const part1 = hex.substring(0, 8);
  const part2 = hex.substring(8, 12);
  const part3 = "4" + hex.substring(13, 16); // versão 4
  const part4 = "8" + hex.substring(17, 20); // variante RFC4122
  const part5 = hex.substring(20, 32);
  return `${part1}-${part2}-${part3}-${part4}-${part5}`;
}

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

  const correlationId = createCorrelationId();

  try {
    // 3. Validar cabeçalho Authorization
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

    // Instancia cliente anon para validar token
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

    const authUserId = user.id;

    // Extrair o session_id de forma segura a partir do JWT validado
    let sessionId: string;
    try {
      sessionId = getSessionIdFromJwt(authHeader);
    } catch (_err) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Validar o corpo do request (estrito)
    const body = await req.json();

    // Rejeitar se contiver qualquer chave proibida/interna
    const forbiddenKeys = [
      "user_id", "auth_user_id", "session_id", "session_hmac", "cycle_id", "challenge_id",
      "otp", "code", "code_hmac", "destination_hmac", "ciphertext", "nonce", "auth_tag",
      "idempotency_key", "service_role"
    ];

    for (const key of forbiddenKeys) {
      if (key in body) {
        return new Response(
          JSON.stringify({ error: "invalid_request" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Apenas "current_password" e "new_email" devem estar no body
    const allowedKeys = ["current_password", "new_email"];
    const bodyKeys = Object.keys(body);
    const hasInvalidKeys = bodyKeys.some(k => !allowedKeys.includes(k));
    if (hasInvalidKeys || bodyKeys.length !== 2) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { current_password, new_email } = body;
    if (
      typeof current_password !== "string" ||
      current_password.trim() === "" ||
      typeof new_email !== "string"
    ) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Normalizar o novo e-mail
    let normalizedEmail: string;
    try {
      normalizedEmail = normalizeEmail(new_email);
    } catch (err: any) {
      const isLengthErr = err.message === "invalid_email_length";
      return new Response(
        JSON.stringify({ error: isLengthErr ? "invalid_request" : "destination_invalid" }),
        { status: isLengthErr ? 400 : 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const emailMasked = maskEmail(normalizedEmail);

    // 6. Computar HMAC da sessão e chave de idempotência determinística
    const sessionHmacKey = Deno.env.get("CONECTEA_SESSION_HMAC_KEY_V1");
    const idempotencySecretKey = Deno.env.get("CONECTEA_IDEMPOTENCY_SECRET_KEY");

    if (!sessionHmacKey || !idempotencySecretKey) {
      console.error(`[Correlation ID: ${correlationId}] Chaves HMAC ausentes no ambiente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const sessionHmac = await generateHmacSha256({
      secretKeyBase64Url: sessionHmacKey,
      domainPrefix: "conectea:email_change:reauth_session:v1:",
      message: sessionId
    });

    const idempotencyKey = await createDeterministicIdempotencyKey({
      userId: authUserId,
      sessionId,
      newEmail: normalizedEmail,
      secretKeyBase64Url: idempotencySecretKey
    });

    // Instanciar Supabase Admin com a service role
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      console.error(`[Correlation ID: ${correlationId}] SUPABASE_SERVICE_ROLE_KEY ausente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // 7. Chamar RPC conectea_start_email_change_reauth_attempt_v1
    const { data: startData, error: startError } = await supabaseAdmin.rpc(
      "conectea_start_email_change_reauth_attempt_v1",
      {
        p_user_id: authUserId,
        p_session_id: sessionId,
        p_session_hmac: sessionHmac,
        p_session_hmac_key_version: 1,
        p_idempotency_key: idempotencyKey
      }
    );

    if (startError || !startData) {
      console.error(`[Correlation ID: ${correlationId}] Falha de RPC start_attempt.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const startResult = startData.result;

    if (startResult === "reauth_blocked") {
      return new Response(
        JSON.stringify({ error: "reauth_blocked" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (startResult === "attempt_in_progress") {
      return new Response(
        JSON.stringify({ error: "try_again_later" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (startResult === "session_invalid" || startResult === "invalid_request") {
      return new Response(
        JSON.stringify({ error: startResult === "session_invalid" ? "unauthorized" : "invalid_request" }),
        { status: startResult === "session_invalid" ? 401 : 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const attemptId = startData.attempt_id;
    const shouldAuthenticate = startData.should_authenticate;

    // Se já foi finalizado e reconciliado como sucesso
    if (startResult === "reused" && startData.attempt_state === "succeeded") {
      return new Response(
        JSON.stringify({ error: "try_again_later" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!shouldAuthenticate) {
      return new Response(
        JSON.stringify({ error: "try_again_later" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Autenticar senha atual em memória
    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { persistSession: false, autoRefreshToken: false }
    });

    const currentEmail = user.email;
    if (!currentEmail) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: signInData, error: signInError } = await authClient.auth.signInWithPassword({
      email: currentEmail,
      password: current_password
    });

    // Best effort sign out
    if (signInData?.session) {
      try {
        await authClient.auth.signOut();
      } catch (_err) {
        // Ignorado em modo best-effort
      }
    }

    if (!signInError && signInData?.user && signInData.user.id !== authUserId) {
      await supabaseAdmin.rpc("conectea_finalize_email_change_reauth_failure_v1", {
        p_attempt_id: attemptId,
        p_user_id: authUserId,
        p_session_id: sessionId,
        p_session_hmac: sessionHmac,
        p_session_hmac_key_version: 1,
        p_result: "technical_failure",
        p_failed_technical_code_private: "auth_internal_error"
      });

      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (signInError) {
      const isCredentialError =
        signInError.status === 400 ||
        signInError.message.includes("Invalid login credentials") ||
        signInError.message.includes("invalid_credentials");

      if (isCredentialError) {
        // Notificar falha de credenciais ao banco
        await supabaseAdmin.rpc("conectea_finalize_email_change_reauth_failure_v1", {
          p_attempt_id: attemptId,
          p_user_id: authUserId,
          p_session_id: sessionId,
          p_session_hmac: sessionHmac,
          p_session_hmac_key_version: 1,
          p_result: "invalid_credentials",
          p_failed_technical_code_private: null
        });

        return new Response(
          JSON.stringify({ error: "invalid_credentials" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      } else {
        // Notificar erro técnico ao banco
        await supabaseAdmin.rpc("conectea_finalize_email_change_reauth_failure_v1", {
          p_attempt_id: attemptId,
          p_user_id: authUserId,
          p_session_id: sessionId,
          p_session_hmac: sessionHmac,
          p_session_hmac_key_version: 1,
          p_result: "technical_failure",
          p_failed_technical_code_private: "auth_unavailable"
        });

        return new Response(
          JSON.stringify({ error: "temporarily_unavailable" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 9. Senha válida: Gerar material criptográfico
    const otp = generateOtp();

    const destinationHmacKey = Deno.env.get("CONECTEA_DESTINATION_HMAC_KEY_V1");
    const codeHmacKey = Deno.env.get("CONECTEA_CODE_HMAC_KEY_V1");
    const decryptionKeyV1 = Deno.env.get("CONECTEA_DECRYPTION_KEY_V1");

    if (!destinationHmacKey || !codeHmacKey || !decryptionKeyV1) {
      console.error(`[Correlation ID: ${correlationId}] Chaves de criptografia ausentes no ambiente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const destinationHmac = await generateHmacSha256({
      secretKeyBase64Url: destinationHmacKey,
      domainPrefix: "conectea:email_change:destination:v1:",
      message: normalizedEmail
    });

    const codeHmac = await generateHmacSha256({
      secretKeyBase64Url: codeHmacKey,
      domainPrefix: "conectea:email_change:code:v1:",
      message: otp
    });

    const destEnc = await encryptAes256Gcm({
      plainText: normalizedEmail,
      keyBase64Url: decryptionKeyV1,
      keyVersion: 1
    });

    const otpEnc = await encryptAes256Gcm({
      plainText: otp,
      keyBase64Url: decryptionKeyV1,
      keyVersion: 1
    });

    // 10. Chamar RPC conectea_finalize_email_change_reauth_success_v1
    const { data: finalizeData, error: finalizeError } = await supabaseAdmin.rpc(
      "conectea_finalize_email_change_reauth_success_v1",
      {
        p_attempt_id: attemptId,
        p_user_id: authUserId,
        p_session_id: sessionId,
        p_session_hmac: sessionHmac,
        p_session_hmac_key_version: 1,

        p_destination_email_normalized: normalizedEmail,
        p_destination_hmac: destinationHmac,
        p_destination_hmac_key_version: 1,
        p_destination_masked: emailMasked,
        p_destination_ciphertext: destEnc.ciphertext,
        p_destination_nonce: destEnc.nonce,
        p_destination_auth_tag: destEnc.authTag,
        p_destination_encryption_algorithm: "aes-256-gcm",
        p_destination_encryption_key_version: 1,

        p_code_hmac: codeHmac,
        p_code_hmac_key_version: 1,
        p_code_ciphertext: otpEnc.ciphertext,
        p_code_nonce: otpEnc.nonce,
        p_code_auth_tag: otpEnc.authTag,
        p_code_encryption_algorithm: "aes-256-gcm",
        p_code_encryption_key_version: 1
      }
    );

    if (finalizeError || !finalizeData) {
      console.error(`[Correlation ID: ${correlationId}] Falha de RPC finalize_success.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const finalizeResult = finalizeData.result;

    if (finalizeResult === "destination_conflict") {
      return new Response(
        JSON.stringify({ error: "destination_conflict" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (finalizeResult === "flow_already_exists" || finalizeResult === "protocol_already_exists") {
      return new Response(
        JSON.stringify({ error: "flow_already_exists" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (finalizeResult === "destination_same_as_current") {
      return new Response(
        JSON.stringify({ error: "destination_same_as_current" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (finalizeResult !== "finalized_success") {
      return new Response(
        JSON.stringify({ error: "try_again_later" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 11. Se finalize_success retornar que deve enviar
    if (finalizeData.should_send === true) {
      try {
        const deliveryResult = await sendExistingEmailChangeOtp({
          supabaseAdmin,
          authUserId,
          cycleId: finalizeData.cycle_id,
          challengeId: finalizeData.challenge_id,
          correlationId
        });

        // Se deu sucesso de entrega
        if (deliveryResult.body?.status === "sent" || deliveryResult.body?.status === "already_sent") {
          return new Response(
            JSON.stringify({
              status: "otp_send_started",
              email_masked: emailMasked,
              resend_available_in_seconds: 60
            }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        } else {
          // Entrega temporariamente falha
          return new Response(
            JSON.stringify({ error: "try_again_later" }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      } catch (_deliveryErr) {
        console.error(`[Correlation ID: ${correlationId}] Erro ao chamar sendExistingEmailChangeOtp.`);
        return new Response(
          JSON.stringify({ error: "try_again_later" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // should_send === false (reuso ou envio sob demanda não aplicável)
    return new Response(
      JSON.stringify({
        status: "otp_send_started",
        email_masked: emailMasked,
        resend_available_in_seconds: 60
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (_err) {
    console.error(`[Correlation ID: ${correlationId}] Erro interno no Handler.`);
    return new Response(
      JSON.stringify({ error: "internal_server_error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

if ((import.meta as any).main) {
  serve(handler);
}
