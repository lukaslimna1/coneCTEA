import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  normalizeCpf,
  generateHmacSha256,
  encryptAes256Gcm,
  createCorrelationId
} from "../create-cpf-change-request/crypto_material.ts";

declare const Deno: any;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function safeEdgeLog({ correlationId, stage, code, rpcCode, sqlstate, constraint, table, column, datatype }: { correlationId: string, stage: string, code?: string, rpcCode?: string, sqlstate?: string, constraint?: string, table?: string, column?: string, datatype?: string }) {
  const parts = [`[Correlation ID: ${correlationId}] stage=${stage}`];
  if (code) parts.push(`code=${code}`);
  if (rpcCode) parts.push(`rpcCode=${rpcCode}`);
  if (sqlstate) parts.push(`sqlstate=${sqlstate}`);
  if (constraint) parts.push(`constraint=${constraint}`);
  if (table) parts.push(`table=${table}`);
  if (column) parts.push(`column=${column}`);
  if (datatype) parts.push(`datatype=${datatype}`);
  console.error(parts.join(' '));
}

export async function handler(req: Request): Promise<Response> {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const correlationId = createCorrelationId();

  // 2. Aceita apenas POST
  if (req.method !== "POST") {
    safeEdgeLog({ correlationId, stage: "invalid_method" });
    return new Response(
      JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  let hasValidFileIdForCleanup = false;

  try {
    // 3. Validar cabeçalho Authorization (JWT)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      safeEdgeLog({ correlationId, stage: "unauthenticated_user", code: "missing_header" });
      return new Response(
        JSON.stringify({ error: "unauthorized", correlation_id: correlationId }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey) {
      safeEdgeLog({ correlationId, stage: "missing_supabase_env" });
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable", correlation_id: correlationId }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia cliente anon para validar token JWT
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      safeEdgeLog({ correlationId, stage: "unauthenticated_user", code: "invalid_token" });
      return new Response(
        JSON.stringify({ error: "unauthorized", correlation_id: correlationId }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const authUserId = user.id;

    // 4. Validar o corpo do request (estrito)
    let body: any;
    try {
      body = await req.json();
    } catch (_err) {
      safeEdgeLog({ correlationId, stage: "invalid_body", code: "json_parse_error" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validação estrita de tipo de body
    if (body === null || typeof body !== "object" || Array.isArray(body)) {
      safeEdgeLog({ correlationId, stage: "invalid_body", code: "not_an_object" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Detecção antecipada de file_id para cleanup seguro do documento
    // (antes de qualquer validação que possa rejeitar o request)
    if (
      typeof body.file_id === "string" &&
      /^[a-zA-Z0-9_-]{10,256}$/.test(body.file_id) &&
      !body.file_id.includes("http") &&
      !body.file_id.includes("drive.google") &&
      !body.file_id.includes("/") &&
      !body.file_id.includes("?") &&
      !body.file_id.includes("&")
    ) {
      hasValidFileIdForCleanup = true;
    }

    // Rejeitar se contiver qualquer chave proibida/interna
    const forbiddenKeys = [
      "user_id", "auth_user_id", "new_cpf_hmac", "ciphertext", "nonce", "auth_tag",
      "key_version", "algorithm", "status", "document_state", "document_reference",
      "protocol_number", "service_role", "url", "document_url", "file_url"
    ];

    for (const key of forbiddenKeys) {
      if (key in body) {
        safeEdgeLog({ correlationId, stage: "forbidden_key_present", code: key });
        return new Response(
          JSON.stringify({ error: "invalid_request", should_cleanup_upload: hasValidFileIdForCleanup, correlation_id: correlationId }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Apenas "member_id", "new_cpf" e "file_id" devem estar no body
    const allowedKeys = ["member_id", "new_cpf", "file_id"];
    const bodyKeys = Object.keys(body);
    const hasInvalidKeys = bodyKeys.some(k => !allowedKeys.includes(k));

    // Deve conter os três campos obrigatórios
    if (hasInvalidKeys || !body.member_id || !body.new_cpf || !body.file_id) {
      safeEdgeLog({ correlationId, stage: "missing_required_fields" });
      return new Response(
        JSON.stringify({ error: "invalid_request", should_cleanup_upload: hasValidFileIdForCleanup, correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { member_id, new_cpf, file_id } = body;

    if (typeof member_id !== "string" || typeof new_cpf !== "string" || typeof file_id !== "string") {
      safeEdgeLog({ correlationId, stage: "invalid_field_type" });
      return new Response(
        JSON.stringify({ error: "invalid_request", should_cleanup_upload: hasValidFileIdForCleanup, correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validação estrita do member_id (UUID v4)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(member_id)) {
      safeEdgeLog({ correlationId, stage: "invalid_member_id" });
      return new Response(
        JSON.stringify({ error: "invalid_request", should_cleanup_upload: hasValidFileIdForCleanup, correlation_id: correlationId }),
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
      safeEdgeLog({ correlationId, stage: "invalid_file_id" });
      return new Response(
        JSON.stringify({ error: "invalid_request", should_cleanup_upload: hasValidFileIdForCleanup, correlation_id: correlationId }),
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
      safeEdgeLog({ correlationId, stage: "invalid_new_cpf" });
      return new Response(
        JSON.stringify({
          error: "invalid_request",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Obter chaves criptográficas do ambiente
    const cpfHmacKey = Deno.env.get("CONECTEA_CPF_HMAC_KEY_V1");
    const decryptionKeyV1 = Deno.env.get("CONECTEA_DECRYPTION_KEY_V1");

    if (!cpfHmacKey || !decryptionKeyV1) {
      safeEdgeLog({ correlationId, stage: "missing_crypto_env" });
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Computar HMAC do CPF
    let cpfHmacStr: string;
    try {
      cpfHmacStr = await generateHmacSha256({
        secretKeyBase64Url: cpfHmacKey,
        domainPrefix: "conectea:dependent_cpf_change:new_cpf:v1:",
        message: normalizedCpf
      });
    } catch (error: any) {
      const allowed = ["missing_secret_key", "invalid_key_format", "invalid_key_length", "hmac_generation_failed"];
      const code = allowed.includes(error.message) ? error.message : "hmac_failed";
      safeEdgeLog({ correlationId, stage: "hmac_failed", code });
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Criptografar o payload AES-256-GCM
    const nowIso = new Date().toISOString();
    const payloadObj = {
      version: 1,
      type: "dependent_cpf_change_request",
      member_id: member_id,
      new_cpf: normalizedCpf,
      file_id: file_id,
      created_at: nowIso
    };

    let encResult: any;
    try {
      encResult = await encryptAes256Gcm({
        plainText: JSON.stringify(payloadObj),
        keyBase64Url: decryptionKeyV1,
        keyVersion: 1
      });
    } catch (error: any) {
      const allowed = ["missing_encryption_key", "invalid_key_format", "invalid_key_length", "encrypt_failed"];
      const code = allowed.includes(error.message) ? error.message : "encryption_failed";
      safeEdgeLog({ correlationId, stage: "encryption_failed", code });
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Instanciar Supabase Admin com a service role
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      safeEdgeLog({ correlationId, stage: "missing_service_role" });
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia o cliente admin padrão apontando para o schema público 'public'
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // 9. Executar a RPC wrapper no schema public
    const { data: rpcData, error: rpcError } = await supabaseAdmin.rpc(
      "conectea_create_dependent_cpf_change_request_v1",
      {
        p_user_id: authUserId,
        p_member_id: member_id,
        p_new_cpf_clear: normalizedCpf,
        p_new_cpf_hmac: cpfHmacStr,
        p_document_file_id: file_id,
        p_ciphertext: encResult.ciphertext,
        p_nonce: encResult.nonce,
        p_auth_tag: encResult.authTag,
        p_algorithm: "aes-256-gcm",
        p_key_version: 1
      }
    );

    if (rpcError) {
      safeEdgeLog({ correlationId, stage: "rpc_transport_error", rpcCode: rpcError.code });
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!rpcData) {
      safeEdgeLog({ correlationId, stage: "rpc_empty_response" });
      return new Response(
        JSON.stringify({
          error: "temporarily_unavailable",
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
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
      const safeLogCodes = [
        "active_request_exists", "member_not_found", "forbidden",
        "account_cpf_flow_required", "invalid_request", "unavailable", "internal_error"
      ];
      const codeToLog = (typeof error_code === "string" && safeLogCodes.includes(error_code))
        ? error_code
        : "unknown";

      const sanitizeLog = (val: any) => {
        if (typeof val === 'string' && val.length <= 120 && /^[a-zA-Z0-9_\-\.]+$/.test(val)) {
          return val;
        }
        return undefined;
      };

      safeEdgeLog({
        correlationId,
        stage: "rpc_business_error",
        code: codeToLog,
        sqlstate: sanitizeLog(rpcData.sqlstate),
        constraint: sanitizeLog(rpcData.constraint),
        table: sanitizeLog(rpcData.table),
        column: sanitizeLog(rpcData.column),
        datatype: sanitizeLog(rpcData.datatype)
      });

      // Mapeamento seguro de erros de lógica/negócio retornados pelo banco
      const safeErrorCodes = [
        "active_request_exists",
        "member_not_found",
        "forbidden",
        "account_cpf_flow_required",
        "invalid_request",
        "unavailable"
      ];
      const mappedError = safeErrorCodes.includes(error_code)
        ? error_code
        : "unavailable";

      return new Response(
        JSON.stringify({
          success: false,
          error: mappedError,
          should_cleanup_upload: hasValidFileIdForCleanup,
          correlation_id: correlationId
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

  } catch (_err) {
    safeEdgeLog({ correlationId, stage: "unexpected_handler_error" });
    return new Response(
      JSON.stringify({
        error: "internal_error",
        should_cleanup_upload: hasValidFileIdForCleanup,
        correlation_id: correlationId
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

if ((import.meta as any).main) {
  serve(handler);
}
