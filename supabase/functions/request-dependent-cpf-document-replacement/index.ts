import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const FILE_ID_REGEX = /^[A-Za-z0-9_-]+$/;

function getSafeErrorMessage(errorCode: string): { status: number, message: string } {
  switch (errorCode) {
    case "method_not_allowed":
      return { status: 405, message: "Método de requisição não suportado." };
    case "unauthorized":
    case "unauthenticated":
      return { status: 401, message: "Sessão expirada ou usuário não autenticado." };
    case "invalid_parameters":
      return { status: 400, message: "Parâmetros da solicitação inválidos ou ausentes." };
    case "forbidden":
      return { status: 403, message: "Acesso negado: privilégios de administrador insuficientes." };
    case "not_found":
      return { status: 404, message: "Solicitação administrativa não encontrada." };
    case "invalid_status":
      return { status: 400, message: "Esta solicitação não está em análise ou sob a trava operacional." };
    case "expired":
      return { status: 400, message: "Esta solicitação já expirou." };
    case "missing_document":
    case "invalid_document_reference":
      return { status: 400, message: "Documento sob auditoria indisponível ou inválido." };
    case "discard_not_configured":
      return { status: 500, message: "Serviço de descarte de documentos não configurado." };
    case "discard_timeout":
      return { status: 504, message: "O descarte no Google Drive excedeu o tempo limite." };
    case "discard_auth_failed":
      return { status: 500, message: "Falha de autenticação com o provedor de descarte." };
    case "discard_failed":
      return { status: 500, message: "Não foi possível remover o documento no Google Drive." };
    case "rollback_failed":
      return {
        status: 500,
        message: "Não foi possível reverter a trava operacional da solicitação. Avise o suporte técnico."
      };
    case "commit_after_discard_failed":
      return { status: 500, message: "O documento foi descartado, mas não foi possível concluir a atualização da solicitação. Avise o suporte técnico." };
    case "invalid_request":
      return { status: 400, message: "Não foi possível validar a solicitação de reenvio do documento." };
    default:
      return { status: 500, message: "Não foi possível solicitar reenvio de documento neste momento." };
  }
}

function safeLog({ correlationId, stage, code, httpStatus }: { correlationId: string, stage: string, code?: string, httpStatus?: number }) {
  const parts = [`[Correlation ID: ${correlationId}] stage=${stage}`];
  if (code) parts.push(`code=${code}`);
  if (httpStatus) parts.push(`httpStatus=${httpStatus}`);
  console.error(parts.join(' '));
}

async function computeHmacHex(key: string, data: string): Promise<string> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(key);
  const msgData = encoder.encode(data);

  const cryptoKey = await (crypto as any).subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await (crypto as any).subtle.sign("HMAC", cryptoKey, msgData);
  const hashArray = Array.from(new Uint8Array(signature));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

async function executeRollbackSafe(
  supabaseAdmin: any,
  requestId: string,
  adminUserId: string,
  errorCode: string,
  correlationId: string
): Promise<boolean> {
  try {
    const { data, error } = await supabaseAdmin.rpc("conectea_admin_rollback_dependent_cpf_document_replacement_v1", {
      p_request_id: requestId,
      p_admin_user_id: adminUserId,
      p_error_code: errorCode
    });

    if (error || !data || data.success !== true) {
      safeLog({ correlationId, stage: "rollback_failed_rpc", code: error?.code ?? "unknown" });
      return false;
    }
    return true;
  } catch (err) {
    safeLog({ correlationId, stage: "rollback_failed_exception", code: "internal_error" });
    return false;
  }
}

export async function handler(req: Request): Promise<Response> {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const correlationId = (crypto as any).randomUUID();
  let prepareSucceeded = false;
  let discardConfirmed = false;
  let requestId = "";
  let adminUserId = "";
  let supabaseAdmin: any = null;

  // Aceita apenas POST
  if (req.method !== "POST") {
    safeLog({ correlationId, stage: "invalid_method", code: "method_not_allowed", httpStatus: 405 });
    const { message } = getSafeErrorMessage("method_not_allowed");
    return new Response(
      JSON.stringify({ success: false, error_code: "method_not_allowed", message }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    // 1. Validar cabeçalho Authorization (JWT)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      safeLog({ correlationId, stage: "unauthenticated_user", code: "missing_header", httpStatus: 401 });
      const { message } = getSafeErrorMessage("unauthorized");
      return new Response(
        JSON.stringify({ success: false, error_code: "unauthorized", message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
      safeLog({ correlationId, stage: "missing_env", code: "internal_error", httpStatus: 500 });
      const { message } = getSafeErrorMessage("internal_error");
      return new Response(
        JSON.stringify({ success: false, error_code: "internal_error", message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Instancia cliente anon para validar token JWT do admin
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      safeLog({ correlationId, stage: "unauthenticated_user", code: "invalid_token", httpStatus: 401 });
      const { message } = getSafeErrorMessage("unauthorized");
      return new Response(
        JSON.stringify({ success: false, error_code: "unauthorized", message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    adminUserId = user.id;

    // 2. Validar payload
    let body: any;
    try {
      body = await req.json();
    } catch (_err) {
      safeLog({ correlationId, stage: "invalid_body", code: "invalid_parameters", httpStatus: 400 });
      const { message } = getSafeErrorMessage("invalid_parameters");
      return new Response(
        JSON.stringify({ success: false, error_code: "invalid_parameters", message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (body === null || typeof body !== "object" || Array.isArray(body) || typeof body.request_id !== "string" || !UUID_REGEX.test(body.request_id)) {
      safeLog({ correlationId, stage: "invalid_payload", code: "invalid_parameters", httpStatus: 400 });
      const { message } = getSafeErrorMessage("invalid_parameters");
      return new Response(
        JSON.stringify({ success: false, error_code: "invalid_parameters", message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    requestId = body.request_id;

    // Instancia cliente admin com service_role
    supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // 3. FASE 1: Chamar PREPARE
    const { data: prepareData, error: prepareTransportError } = await supabaseAdmin.rpc(
      "conectea_admin_prepare_dependent_cpf_document_replacement_v1",
      {
        p_request_id: requestId,
        p_admin_user_id: adminUserId
      }
    );

    if (prepareTransportError) {
      safeLog({ correlationId, stage: "prepare_transport_error", code: prepareTransportError.code, httpStatus: 500 });
      const { message } = getSafeErrorMessage("internal_error");
      return new Response(
        JSON.stringify({ success: false, error_code: "internal_error", message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!prepareData || prepareData.success !== true) {
      const dbErrorCode = prepareData?.error_code ?? "internal_error";
      safeLog({ correlationId, stage: "prepare_business_error", code: dbErrorCode, httpStatus: 400 });
      const { status, message } = getSafeErrorMessage(dbErrorCode);
      return new Response(
        JSON.stringify({ success: false, error_code: dbErrorCode, message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    prepareSucceeded = true;
    const documentFileId = prepareData.document_file_id;

    // 4. Validar o document_file_id retornado internamente (não deve conter caracteres estranhos)
    if (
      typeof documentFileId !== "string" || 
      documentFileId.trim() === "" || 
      documentFileId.length < 10 || 
      documentFileId.length > 256 || 
      !FILE_ID_REGEX.test(documentFileId)
    ) {
      safeLog({ correlationId, stage: "invalid_document_file_id", code: "invalid_document_reference", httpStatus: 400 });
      
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, adminUserId, "invalid_document_file_id", correlationId);
      if (!rollbackOk) {
        const { status, message } = getSafeErrorMessage("rollback_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "rollback_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { status, message } = getSafeErrorMessage("invalid_document_reference");
      return new Response(
        JSON.stringify({ success: false, error_code: "invalid_document_reference", message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. FASE 2: Descarte imediato no GAS do Drive
    const gasDiscardUrl = Deno.env.get("GC_DRIVE_DISCARD_GAS_URL") ?? "";
    const gasSigningKey = Deno.env.get("GC_DRIVE_DISCARD_SIGNING_KEY") ?? "";

    if (!gasDiscardUrl || !gasSigningKey) {
      safeLog({ correlationId, stage: "missing_gas_config", code: "discard_not_configured", httpStatus: 500 });
      
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, adminUserId, "discard_not_configured", correlationId);
      if (!rollbackOk) {
        const { status, message } = getSafeErrorMessage("rollback_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "rollback_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { status, message } = getSafeErrorMessage("discard_not_configured");
      return new Response(
        JSON.stringify({ success: false, error_code: "discard_not_configured", message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const timestamp = new Date().toISOString();
    const action = "secure_discard_v1";
    const reason = "document_replaced";

    // String canônica para HMAC
    const canonicalString = `${action}|${documentFileId}|${requestId}|${reason}|${timestamp}`;
    const signature = await computeHmacHex(gasSigningKey, canonicalString);

    const gasPayload = {
      action,
      file_id: documentFileId,
      request_id: requestId,
      reason,
      timestamp,
      signature
    };

    // Chamada segura com timeout de 15 segundos
    let gasResponse: any = null;
    let isDiscardOk = false;
    let gasErrorCode = "";
    let gasHttpOk = false;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    try {
      const fetchResult = await fetch(gasDiscardUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(gasPayload),
        redirect: "follow",
        signal: controller.signal,
      });

      gasHttpOk = fetchResult.ok;

      try {
        gasResponse = await fetchResult.json();
      } catch (_jsonErr) {
        gasResponse = null;
      }
    } catch (fetchErr: any) {
      if (fetchErr.name === "AbortError") {
        gasErrorCode = "discard_timeout";
      } else {
        gasErrorCode = "discard_failed";
      }
    } finally {
      clearTimeout(timeoutId);
    }

    // Validação de sucesso da chamada do GAS
    if (!gasErrorCode) {
      if (gasResponse && typeof gasResponse === "object") {
        const errType = gasResponse.error ?? gasResponse.error_code;

        if (gasHttpOk) {
          if (gasResponse.success === true && gasResponse.status === "trashed") {
            isDiscardOk = true;
          } else if (errType === "file_not_found") {
            isDiscardOk = true;
          } else if (errType === "auth_failed") {
            gasErrorCode = "discard_auth_failed";
          } else {
            gasErrorCode = "discard_failed";
          }
        } else {
          // Aceita file_not_found como sucesso sob idempotência mesmo se HTTP for diferente de 2xx
          if (errType === "file_not_found") {
            isDiscardOk = true;
          } else if (errType === "auth_failed") {
            gasErrorCode = "discard_auth_failed";
          } else {
            gasErrorCode = "discard_failed";
          }
        }
      } else {
        gasErrorCode = "discard_failed";
      }
    }

    if (!isDiscardOk) {
      safeLog({ correlationId, stage: "gas_discard_failed", code: gasErrorCode, httpStatus: 400 });
      
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, adminUserId, gasErrorCode, correlationId);
      if (!rollbackOk) {
        const { status, message } = getSafeErrorMessage("rollback_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "rollback_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { status, message } = getSafeErrorMessage(gasErrorCode);
      return new Response(
        JSON.stringify({ success: false, error_code: gasErrorCode, message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    discardConfirmed = true;

    // 6. FASE 3: Chamar COMMIT (GAS deletou o arquivo com sucesso)
    const { data: commitData, error: commitTransportError } = await supabaseAdmin.rpc(
      "conectea_admin_commit_dependent_cpf_document_replacement_v1",
      {
        p_request_id: requestId,
        p_admin_user_id: adminUserId,
        p_document_file_id: documentFileId
      }
    );

    if (commitTransportError) {
      safeLog({ correlationId, stage: "commit_transport_error", code: commitTransportError.code });
      
      // Tentativa imediata de retry de transporte para mitigar intercorrências de rede
      const { data: retryCommitData, error: retryCommitTransportError } = await supabaseAdmin.rpc(
        "conectea_admin_commit_dependent_cpf_document_replacement_v1",
        {
          p_request_id: requestId,
          p_admin_user_id: adminUserId,
          p_document_file_id: documentFileId
        }
      );

      if (retryCommitTransportError || !retryCommitData || retryCommitData.success !== true) {
        safeLog({ correlationId, stage: "commit_retry_failed", code: retryCommitTransportError?.code ?? "unknown" });
        const { status, message } = getSafeErrorMessage("commit_after_discard_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "commit_after_discard_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } else if (!commitData || commitData.success !== true) {
      const commitErrorCode = commitData?.error_code ?? "commit_failed";
      safeLog({ correlationId, stage: "commit_business_error", code: commitErrorCode });
      const { status, message } = getSafeErrorMessage("commit_after_discard_failed");
      return new Response(
        JSON.stringify({ success: false, error_code: "commit_after_discard_failed", message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Sucesso!
    return new Response(
      JSON.stringify({
        success: true,
        request_id: requestId,
        status: "waiting_document_replacement",
        message: "Reenvio de documento solicitado."
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    safeLog({ correlationId, stage: "unexpected_error", code: "internal_error" });

    if (prepareSucceeded && !discardConfirmed && supabaseAdmin && requestId && adminUserId) {
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, adminUserId, "unexpected_handler_error", correlationId);
      if (!rollbackOk) {
        const { status, message } = getSafeErrorMessage("rollback_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "rollback_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    if (discardConfirmed) {
      // Se o arquivo foi apagado no Drive mas ocorreu erro inesperado antes de retornar a resposta de sucesso
      const { status, message } = getSafeErrorMessage("commit_after_discard_failed");
      return new Response(
        JSON.stringify({ success: false, error_code: "commit_after_discard_failed", message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { status, message } = getSafeErrorMessage("internal_error");
    return new Response(
      JSON.stringify({ success: false, error_code: "internal_error", message }),
      { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

serve(handler);
