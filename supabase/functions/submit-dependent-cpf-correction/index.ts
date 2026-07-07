import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  normalizeCpf,
  generateHmacSha256,
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

    if (body === null || typeof body !== "object" || Array.isArray(body)) {
      safeEdgeLog({ correlationId, stage: "invalid_body", code: "not_an_object" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Rejeitar se contiver qualquer chave proibida/interna
    const forbiddenKeys = [
      "user_id", "auth_user_id", "new_cpf_hmac", "ciphertext", "nonce", "auth_tag",
      "key_version", "algorithm", "status", "document_state", "document_reference",
      "protocol_number", "service_role", "url", "document_url", "file_url", "file_id",
      "document_file_id", "hmac", "cpf_hmac"
    ];

    for (const key of forbiddenKeys) {
      if (key in body) {
        safeEdgeLog({ correlationId, stage: "forbidden_key_present", code: key });
        return new Response(
          JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Apenas "request_id" e "new_cpf" devem estar no body
    const allowedKeys = ["request_id", "new_cpf"];
    const bodyKeys = Object.keys(body);
    const hasInvalidKeys = bodyKeys.some(k => !allowedKeys.includes(k));

    if (hasInvalidKeys || !body.new_cpf || !body.request_id) {
      safeEdgeLog({ correlationId, stage: "missing_required_fields" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { new_cpf, request_id } = body;

    if (typeof new_cpf !== "string" || typeof request_id !== "string") {
      safeEdgeLog({ correlationId, stage: "invalid_field_type" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validação UUID básico
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(request_id)) {
      safeEdgeLog({ correlationId, stage: "invalid_request_id" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validação e normalização do CPF
    let normalizedCpf: string;
    try {
      normalizedCpf = normalizeCpf(new_cpf);
    } catch (_err) {
      safeEdgeLog({ correlationId, stage: "invalid_new_cpf" });
      return new Response(
        JSON.stringify({ error: "invalid_request", correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Obter chave do HMAC do ambiente
    const cpfHmacKey = Deno.env.get("CONECTEA_CPF_HMAC_KEY_V1");

    if (!cpfHmacKey) {
      safeEdgeLog({ correlationId, stage: "missing_crypto_env" });
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable", correlation_id: correlationId }),
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
        JSON.stringify({ error: "temporarily_unavailable", correlation_id: correlationId }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Instanciar Supabase Admin com a service role
    const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceRole) {
      safeEdgeLog({ correlationId, stage: "missing_service_role" });
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable", correlation_id: correlationId }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRole);

    // 8. Executar a RPC no schema public
    const { data: rpcData, error: rpcError } = await supabaseAdmin.rpc(
      "conectea_submit_dependent_cpf_correction_v1",
      {
        p_request_id: request_id,
        p_user_id: authUserId,
        p_new_cpf_clear: normalizedCpf,
        p_new_cpf_hmac: cpfHmacStr
      }
    );

    if (rpcError) {
      safeEdgeLog({ correlationId, stage: "rpc_transport_error", rpcCode: rpcError.code });
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable", correlation_id: correlationId }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!rpcData) {
      safeEdgeLog({ correlationId, stage: "rpc_empty_response" });
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable", correlation_id: correlationId }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { success, error_code, status } = rpcData;

    if (success === true) {
      return new Response(
        JSON.stringify({
          success: true,
          status: status
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      const codeToLog = typeof error_code === "string" ? error_code : "unknown";

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

      // Mapeamento seguro de erros
      const safeErrors = [
        "invalid_request", "unauthenticated", "forbidden", "not_found", "member_not_found",
        "invalid_status", "expired", "invalid_cpf", "account_cpf_conflict", "cpf_in_use",
        "reservation_unavailable", "unavailable"
      ];

      const mappedError = safeErrors.includes(error_code) ? error_code : "unavailable";

      return new Response(
        JSON.stringify({
          success: false,
          error: mappedError,
          correlation_id: correlationId
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

  } catch (_err) {
    safeEdgeLog({ correlationId, stage: "unexpected_handler_error" });
    return new Response(
      JSON.stringify({ error: "internal_error", correlation_id: correlationId }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

serve(handler);
