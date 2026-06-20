import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { generateHmacSha256 } from "../start-email-change-otp/crypto_material.ts";
import { decryptAesGcmSeparatedTag } from "../send-email-change-otp/crypto.ts";
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

    // Extrair o session_id de forma segura a partir do JWT
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

    // Apenas "otp" deve estar no body
    const bodyKeys = Object.keys(body);
    if (bodyKeys.length !== 1 || bodyKeys[0] !== "otp") {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { otp } = body;
    if (typeof otp !== "string" || !/^[0-9]{6}$/.test(otp)) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Carregar chaves criptográficas do ambiente
    const sessionHmacKey = Deno.env.get("CONECTEA_SESSION_HMAC_KEY_V1");
    const codeHmacKey = Deno.env.get("CONECTEA_CODE_HMAC_KEY_V1");

    if (!sessionHmacKey || !codeHmacKey) {
      console.error(`[Correlation ID: ${correlationId}] Chaves HMAC ausentes no ambiente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Derivar sessionHmac e codeHmac
    const sessionHmac = await generateHmacSha256({
      secretKeyBase64Url: sessionHmacKey,
      domainPrefix: "conectea:email_change:reauth_session:v1:",
      message: sessionId
    });

    const codeHmac = await generateHmacSha256({
      secretKeyBase64Url: codeHmacKey,
      domainPrefix: "conectea:email_change:code:v1:",
      message: otp
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

    // 7. Chamar RPC conectea_confirm_email_change_otp_v1
    const { data: confirmData, error: confirmError } = await supabaseAdmin.rpc(
      "conectea_confirm_email_change_otp_v1",
      {
        p_user_id: authUserId,
        p_session_id: sessionId,
        p_session_hmac: sessionHmac,
        p_session_hmac_key_version: 1,
        p_code_hmac: codeHmac,
        p_code_hmac_key_version: 1
      }
    );

    if (confirmError || !confirmData) {
      console.error(`[Correlation ID: ${correlationId}] Falha de RPC confirm_otp.`);
      return new Response(
        JSON.stringify({ error: "internal_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const confirmResult = confirmData.result;

    if (confirmResult === "flow_not_found" || confirmResult === "unauthorized") {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (confirmResult === "otp_expired") {
      return new Response(
        JSON.stringify({ error: "otp_expired" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (confirmResult === "otp_attempts_exceeded") {
      return new Response(
        JSON.stringify({ error: "otp_attempts_exceeded" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (confirmResult === "otp_invalid") {
      return new Response(
        JSON.stringify({
          error: "otp_invalid",
          attempts_remaining: confirmData.attempts_remaining
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (confirmResult !== "otp_valid") {
      return new Response(
        JSON.stringify({ error: "internal_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. OTP Válido: Executar a alteração de e-mail no Supabase Auth em Deno
    const requestId = confirmData.request_id;
    const protocolNumber = confirmData.protocol_number;

    let newEmailClear: string;
    try {
      newEmailClear = await decryptAesGcmSeparatedTag({
        ciphertext: confirmData.destination_ciphertext,
        nonce: confirmData.destination_nonce,
        authTag: confirmData.destination_auth_tag,
        keyVersion: confirmData.destination_encryption_key_version
      });
    } catch (_decryptErr) {
      console.error(`[Correlation ID: ${correlationId}] Falha ao descriptografar e-mail de destino.`);
      
      // Consolidar falha de criptografia no banco de dados
      await supabaseAdmin.rpc("conectea_consolidate_email_change_failure_v1", {
        p_request_id: requestId,
        p_user_id: authUserId,
        p_failure_code: "decrypt_failed",
        p_failure_reason: "Falha de descriptografia no backend"
      });

      return new Response(
        JSON.stringify({ error: "internal_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Efetiva a alteração cadastral no Supabase Auth usando o cliente admin
    const { data: updateData, error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      authUserId,
      { email: newEmailClear }
    );

    if (updateError || !updateData) {
      console.error(`[Correlation ID: ${correlationId}] Falha ao atualizar e-mail no Supabase Auth.`);

      // Consolidar a falha de atualização do Auth no banco de dados de forma sanitizada (sem expor mensagens brutas que possam conter emails/tokens)
      await supabaseAdmin.rpc("conectea_consolidate_email_change_failure_v1", {
        p_request_id: requestId,
        p_user_id: authUserId,
        p_failure_code: "auth_update_failed",
        p_failure_reason: "Erro de atualizacao cadastral no Supabase Auth"
      });

      return new Response(
        JSON.stringify({ error: "auth_update_failed" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 9. Atualização com sucesso: Consolidar a gravação no banco de dados
    const { data: consolidateData, error: consolidateError } = await supabaseAdmin.rpc(
      "conectea_consolidate_email_change_success_v1",
      {
        p_request_id: requestId,
        p_user_id: authUserId,
        p_new_email_clear: newEmailClear
      }
    );

    if (consolidateError || !consolidateData || consolidateData.result !== "consolidated_success") {
      console.error(`[Correlation ID: ${correlationId}] Falha crítica ao consolidar alteração de e-mail no banco de dados.`);
      return new Response(
        JSON.stringify({ error: "internal_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 10. Retornar resposta pública sanitizada de sucesso
    return new Response(
      JSON.stringify({
        status: "success",
        protocol_number: protocolNumber
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (_err) {
    console.error(`[Correlation ID: ${correlationId}] Erro interno no Handler de confirmação.`);
    return new Response(
      JSON.stringify({ error: "internal_error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

if ((import.meta as any).main) {
  serve(handler);
}
