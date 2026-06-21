import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  generateOtp,
  generateHmacSha256,
  encryptAes256Gcm
} from "../start-email-change-otp/crypto_material.ts";
import { sendExistingEmailChangeOtp } from "../send-email-change-otp/delivery.ts";
import { createCorrelationId } from "../send-email-change-otp/signing.ts";

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

    // 4. Validar o corpo do request (estrito)
    // O reenvio não deve receber current_password, new_email, otp ou session_id do cliente
    let body: any = {};
    if (req.body) {
      try {
        body = await req.json();
      } catch (e) {
        // ignorar
      }
    }

    const forbiddenKeys = [
      "user_id", "auth_user_id", "session_id", "session_hmac", "cycle_id", "challenge_id",
      "otp", "code", "code_hmac", "destination_hmac", "ciphertext", "nonce", "auth_tag",
      "idempotency_key", "service_role", "current_password", "new_email"
    ];

    for (const key of forbiddenKeys) {
      if (key in body) {
        return new Response(
          JSON.stringify({ error: "invalid_request" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Instanciar Supabase Admin com a service role para operações internas seguras (envio)
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      console.error(`[Correlation ID: ${correlationId}] SUPABASE_SERVICE_ROLE_KEY ausente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // Limpeza de ciclos expirados
    const { error: cleanupError } = await supabaseAdmin.rpc(
      "conectea_cleanup_expired_email_change_cycles_v1",
      { p_user_id: authUserId }
    );

    if (cleanupError) {
      console.error(`[Correlation ID: ${correlationId}] Falha na limpeza de ciclos expirados.`);
    }

    // 5. Gerar Novo OTP localmente
    const otp = generateOtp();
    const hmacKeyV1 = Deno.env.get("CONECTEA_CODE_HMAC_KEY_V1");
    const decryptionKeyV1 = Deno.env.get("CONECTEA_DECRYPTION_KEY_V1");

    if (!hmacKeyV1 || !decryptionKeyV1) {
      console.error(`[Correlation ID: ${correlationId}] Chaves criptográficas ausentes no ambiente.`);
      return new Response(
        JSON.stringify({ error: "configuration_error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const codeHmacStr = await generateHmacSha256({
      secretKeyBase64Url: hmacKeyV1,
      domainPrefix: "conectea:email_change:code:v1:",
      message: otp
    });

    const otpEnc = await encryptAes256Gcm({
      plainText: otp,
      keyBase64Url: decryptionKeyV1,
      keyVersion: 1
    });

    // 6. Chamar RPC conectea_resend_email_change_otp_v1 via supabaseClient autenticado
    const { data: resendData, error: resendError } = await supabaseClient.rpc(
      "conectea_resend_email_change_otp_v1",
      {
        p_code_hmac: codeHmacStr,
        p_code_hmac_key_version: 1,
        p_code_ciphertext: otpEnc.ciphertext,
        p_code_nonce: otpEnc.nonce,
        p_code_auth_tag: otpEnc.authTag,
        p_code_encryption_algorithm: "aes-256-gcm",
        p_code_encryption_key_version: 1
      }
    );

    if (resendError || !resendData) {
      console.error(`[Correlation ID: ${correlationId}] Falha de RPC resend_otp.`, resendError);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const resendResult = resendData.result;

    if (resendResult === "unauthorized") {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (resendResult === "no_active_cycle") {
      return new Response(
        JSON.stringify({ error: "no_active_cycle" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (resendResult === "expired_cycle") {
      return new Response(
        JSON.stringify({ error: "expired_cycle" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (resendResult === "max_resends_reached") {
      return new Response(
        JSON.stringify({ error: "max_resends_reached" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (resendResult === "cooldown_active") {
      return new Response(
        JSON.stringify({ 
          error: "cooldown_active",
          resend_available_at: resendData.resend_available_at 
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (resendResult !== "success") {
      console.error(`[Correlation ID: ${correlationId}] Erro desconhecido no reenvio: ${resendResult}`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Envio do E-mail Reutilizando delivery.ts via Supabase Admin (para acesso seguro a dados internos)
    try {
      const deliveryResult = await sendExistingEmailChangeOtp({
        supabaseAdmin,
        authUserId,
        cycleId: resendData.cycle_id,
        challengeId: resendData.challenge_id,
        correlationId
      });

      if (deliveryResult.body?.status === "sent" || deliveryResult.body?.status === "already_sent") {
        return new Response(
          JSON.stringify({
            ok: true,
            status: "success",
            masked_email: resendData.masked_email,
            send_sequence: resendData.send_sequence,
            message: "O código foi reenviado com sucesso.",
            expires_at: deliveryResult.body?.expires_at,
            resend_available_at: deliveryResult.body?.resend_available_at
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      } else {
        console.error(`[Correlation ID: ${correlationId}] Erro ao enviar e-mail no reenvio: status inesperado.`);
        return new Response(
          JSON.stringify({ error: "send_failed" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } catch (_deliveryErr) {
      console.error(`[Correlation ID: ${correlationId}] Erro de exception ao chamar sendExistingEmailChangeOtp.`);
      return new Response(
        JSON.stringify({ error: "send_failed" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

  } catch (err: any) {
    console.error(`[Correlation ID: ${correlationId}] Exceção não tratada:`, err);
    return new Response(
      JSON.stringify({ error: "unknown_error" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

serve(handler);
