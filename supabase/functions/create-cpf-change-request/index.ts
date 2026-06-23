import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  normalizeCpf,
  generateHmacSha256,
  encryptAes256Gcm,
  createCorrelationId
} from "./crypto_material.ts";

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
      JSON.stringify({ error: "invalid_request" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const correlationId = createCorrelationId();
  let hasValidFileIdForCleanup = false;

  try {
    // 3. Validar cabeçalho Authorization (JWT)
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
      console.error(`[Correlation ID: ${correlationId}] Configuração de ambiente Supabase ausente.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia cliente anon para validar token JWT
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
    let body: any;
    try {
      body = await req.json();
    } catch (_err) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validação estrita de tipo de body
    if (body === null || typeof body !== "object" || Array.isArray(body)) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Rejeitar se contiver qualquer chave proibida/interna
    const forbiddenKeys = [
      "user_id", "auth_user_id", "new_cpf_hmac", "ciphertext", "nonce", "auth_tag",
      "key_version", "algorithm", "status", "document_state", "document_reference",
      "protocol_number", "service_role", "url", "document_url", "file_url"
    ];

    for (const key of forbiddenKeys) {
      if (key in body) {
        return new Response(
          JSON.stringify({ error: "invalid_request" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Apenas "new_cpf", "file_id" e "justification" (opcional) devem estar no body
    const allowedKeys = ["new_cpf", "file_id", "justification"];
    const bodyKeys = Object.keys(body);
    const hasInvalidKeys = bodyKeys.some(k => !allowedKeys.includes(k));
    
    // Deve conter no mínimo "new_cpf" e "file_id"
    if (hasInvalidKeys || !body.new_cpf || !body.file_id) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { new_cpf, file_id, justification } = body;

    if (typeof new_cpf !== "string" || typeof file_id !== "string") {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validação estrita do file_id (Regex correspondente à tabela do banco de dados)
    const fileIdRegex = /^[a-zA-Z0-9_-]{10,256}$/;
    if (
      !fileIdRegex.test(file_id) ||
      file_id.includes("http") ||
      file_id.includes("drive.google") ||
      file_id.includes("/") ||
      file_id.includes("?") ||
      file_id.includes("&")
    ) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sinalizar que recebemos um file_id sintaticamente válido
    hasValidFileIdForCleanup = true;

    // Validação e normalização do CPF
    let normalizedCpf: string;
    try {
      normalizedCpf = normalizeCpf(new_cpf);
    } catch (_err) {
      return new Response(
        JSON.stringify({
          error: "invalid_request",
          should_cleanup_upload: hasValidFileIdForCleanup
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Normalização da justificativa
    let normalizedJustification = "";
    if (justification !== undefined && justification !== null) {
      if (typeof justification !== "string") {
        return new Response(
          JSON.stringify({
            error: "invalid_request",
            should_cleanup_upload: hasValidFileIdForCleanup
          }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      normalizedJustification = justification.trim();
      if (normalizedJustification.length > 1000) {
        return new Response(
          JSON.stringify({
            error: "invalid_request",
            should_cleanup_upload: hasValidFileIdForCleanup
          }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 5. Obter chaves criptográficas do ambiente
    const cpfHmacKey = Deno.env.get("CONECTEA_CPF_HMAC_KEY_V1");
    const decryptionKeyV1 = Deno.env.get("CONECTEA_DECRYPTION_KEY_V1");

    if (!cpfHmacKey || !decryptionKeyV1) {
      console.error(`[Correlation ID: ${correlationId}] Chaves criptográficas ausentes no ambiente.`);
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Computar HMAC do CPF
    const cpfHmacStr = await generateHmacSha256({
      secretKeyBase64Url: cpfHmacKey,
      domainPrefix: "conectea:cpf_change:new_cpf:v1:",
      message: normalizedCpf
    });

    // 7. Criptografar o payload AES-256-GCM
    const nowIso = new Date().toISOString();
    const payloadObj = {
      version: 1,
      type: "cpf_change_request",
      new_cpf: normalizedCpf,
      file_id: file_id,
      justification: normalizedJustification,
      created_at: nowIso
    };

    const encResult = await encryptAes256Gcm({
      plainText: JSON.stringify(payloadObj),
      keyBase64Url: decryptionKeyV1,
      keyVersion: 1
    });

    // 8. Instanciar Supabase Admin com a service role
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      console.error(`[Correlation ID: ${correlationId}] SUPABASE_SERVICE_ROLE_KEY ausente.`);
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia o cliente apontando para o schema 'private'
    const supabaseAdminPrivate = createClient(supabaseUrl, supabaseServiceRole, {
      db: { schema: "private" }
    });

    // 9. Executar a RPC no schema private
    const { data: rpcData, error: rpcError } = await supabaseAdminPrivate.rpc(
      "conectea_create_cpf_change_request_v1",
      {
        p_user_id: authUserId,
        p_new_cpf_clear: normalizedCpf,
        p_new_cpf_hmac: cpfHmacStr,
        p_justification: normalizedJustification,
        p_ciphertext: encResult.ciphertext,
        p_nonce: encResult.nonce,
        p_auth_tag: encResult.authTag,
        p_algorithm: "aes-256-gcm",
        p_key_version: 1
      }
    );

    if (rpcError || !rpcData) {
      console.error(`[Correlation ID: ${correlationId}] Erro de execução da RPC no Supabase.`);
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { success, error_code, request_id, protocol_number } = rpcData;

    if (success === true) {
      return new Response(
        JSON.stringify({
          success: true,
          request_id: request_id,
          protocol_number: protocol_number
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // Mapeamento seguro de erros de lógica/negócio retornados pelo banco
      const mappedError = error_code === "active_request_exists" 
        ? "active_request_exists" 
        : (error_code === "unavailable" || error_code === "invalid_request" ? error_code : "unavailable");

      return new Response(
        JSON.stringify({
          success: false,
          error: mappedError,
          should_cleanup_upload: hasValidFileIdForCleanup
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

  } catch (_err) {
    console.error(`[Correlation ID: ${correlationId}] Erro inesperado no handler da Edge Function.`);
    return new Response(
      JSON.stringify({
        error: "internal_error",
        should_cleanup_upload: hasValidFileIdForCleanup
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

if ((import.meta as any).main) {
  serve(handler);
}
