import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const FILE_ID_REGEX = /^[A-Za-z0-9_-]{10,256}$/;

function getSafeErrorMessage(errorCode: string): { status: number; message: string } {
  switch (errorCode) {
    case "method_not_allowed":
      return { status: 405, message: "Método de requisição não suportado." };
    case "unauthorized":
    case "unauthenticated":
      return { status: 401, message: "Acesso não autorizado." };
    case "forbidden":
      return { status: 403, message: "Acesso negado: privilégios insuficientes." };
    case "invalid_parameters":
    case "invalid_request":
      return { status: 400, message: "Parâmetros da solicitação inválidos ou ausentes." };
    case "not_found":
      return { status: 404, message: "Solicitação de alteração de CPF não encontrada." };
    case "invalid_status":
      return { status: 400, message: "Esta solicitação não está em estado válido para expiração." };
    case "not_expired":
      return { status: 400, message: "Esta solicitação ainda não atingiu a data/hora de expiração." };
    case "invalid_document_state":
      return { status: 400, message: "Estado documental da solicitação é incoerente." };
    case "missing_review_data":
      return { status: 400, message: "Dados confidenciais de revisão indisponíveis." };
    case "discard_not_configured":
      return { status: 500, message: "Serviço de descarte de documentos não configurado." };
    case "discard_timeout":
      return { status: 504, message: "O descarte no Google Drive excedeu o tempo limite." };
    case "discard_auth_failed":
      return { status: 500, message: "Falha de autenticação com o provedor de descarte." };
    case "discard_failed":
      return { status: 500, message: "Não foi possível remover o documento no Google Drive." };
    case "rollback_failed":
      return { status: 500, message: "Erro ao reverter a trava transacional da expiração." };
    case "commit_failed":
      return { status: 500, message: "Não foi possível consolidar a expiração da solicitação." };
    case "commit_after_discard_failed":
      return { status: 500, message: "Documento removido no Drive, mas falhou a consolidação da expiração." };
    default:
      return { status: 500, message: "Não foi possível processar a expiração neste momento." };
  }
}

function safeLog({ correlationId, stage, code, httpStatus }: { correlationId: string; stage: string; code?: string; httpStatus?: number }) {
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
  previousStatus: string,
  errorCode: string,
  correlationId: string
): Promise<boolean> {
  try {
    const { data, error } = await supabaseAdmin.rpc("conectea_system_rollback_dependent_cpf_expiration_v1", {
      p_request_id: requestId,
      p_previous_status: previousStatus,
      p_error_code: errorCode
    });

    if (error || !data || data.success !== true) {
      safeLog({ correlationId, stage: "rollback_failed_rpc", code: error?.code ?? "unknown" });
      return false;
    }
    return true;
  } catch (_err) {
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
  let previousStatus = "";
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
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      safeLog({ correlationId, stage: "missing_env", code: "internal_error", httpStatus: 500 });
      const { message } = getSafeErrorMessage("internal_error");
      return new Response(
        JSON.stringify({ success: false, error_code: "internal_error", message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Autorização estrita server-to-server (exige exclusivamente a SUPABASE_SERVICE_ROLE_KEY no Bearer)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      safeLog({ correlationId, stage: "unauthenticated_request", code: "missing_header", httpStatus: 401 });
      const { message } = getSafeErrorMessage("unauthorized");
      return new Response(
        JSON.stringify({ success: false, error_code: "unauthorized", message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();
    if (token !== supabaseServiceKey) {
      safeLog({ correlationId, stage: "unauthorized_request", code: "forbidden", httpStatus: 403 });
      const { message } = getSafeErrorMessage("forbidden");
      return new Response(
        JSON.stringify({ success: false, error_code: "forbidden", message }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Validar payload de entrada
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

    if (
      body === null || 
      typeof body !== "object" || 
      Array.isArray(body) || 
      typeof body.request_id !== "string" || 
      !UUID_REGEX.test(body.request_id)
    ) {
      safeLog({ correlationId, stage: "invalid_payload", code: "invalid_parameters", httpStatus: 400 });
      const { message } = getSafeErrorMessage("invalid_parameters");
      return new Response(
        JSON.stringify({ success: false, error_code: "invalid_parameters", message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    requestId = body.request_id;

    // Instancia cliente admin com service_role para executar as RPCs de sistema (server-to-server only)
    supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // 3. FASE 1: Chamar PREPARE no banco
    const { data: prepareData, error: prepareTransportError } = await supabaseAdmin.rpc(
      "conectea_system_prepare_dependent_cpf_expiration_v1",
      {
        p_request_id: requestId
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

    // A. Tratamento Idempotente se já estiver expirada
    if (prepareData.document_action === "already_expired" || prepareData.status === "expired") {
      return new Response(
        JSON.stringify({
          success: true,
          request_id: requestId,
          status: "expired",
          message: "Solicitação já estava expirada."
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    prepareSucceeded = true;
    previousStatus = prepareData.previous_status ?? "";
    const documentAction = prepareData.document_action ?? "";
    const documentFileId = prepareData.document_file_id;

    // 4. Caso A: Expiração Sem Documento Pendente (no_document)
    if (documentAction === "no_document") {
      const { data: commitNoDocData, error: commitNoDocError } = await supabaseAdmin.rpc(
        "conectea_system_commit_dependent_cpf_expiration_v1",
        {
          p_request_id: requestId,
          p_previous_status: previousStatus,
          p_document_action: "no_document"
        }
      );

      if (commitNoDocError || !commitNoDocData || commitNoDocData.success !== true) {
        const commitErrCode = commitNoDocData?.error_code ?? "commit_failed";
        safeLog({ correlationId, stage: "commit_nodoc_failed", code: commitErrCode });

        // Tenta rollback seguro para não deixar trava operando solta
        await executeRollbackSafe(supabaseAdmin, requestId, previousStatus, commitErrCode, correlationId);

        const { status, message } = getSafeErrorMessage("commit_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "commit_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          request_id: requestId,
          status: "expired",
          message: "Solicitação expirada com sucesso."
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Caso B: Expiração Com Descarte de Documento Obrigatório (discard_required)
    if (documentAction !== "discard_required") {
      safeLog({ correlationId, stage: "invalid_document_action", code: "invalid_document_state", httpStatus: 400 });
      await executeRollbackSafe(supabaseAdmin, requestId, previousStatus, "invalid_document_action", correlationId);
      const { status, message } = getSafeErrorMessage("invalid_document_state");
      return new Response(
        JSON.stringify({ success: false, error_code: "invalid_document_state", message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validar document_file_id retornado internamente pelo prepare
    if (
      typeof documentFileId !== "string" || 
      documentFileId.trim() === "" || 
      documentFileId.length < 10 || 
      documentFileId.length > 256 || 
      !FILE_ID_REGEX.test(documentFileId)
    ) {
      safeLog({ correlationId, stage: "invalid_document_file_id", code: "invalid_document_state", httpStatus: 400 });
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, previousStatus, "invalid_document_file_id", correlationId);
      if (!rollbackOk) {
        const { status, message } = getSafeErrorMessage("rollback_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "rollback_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      const { status, message } = getSafeErrorMessage("invalid_document_state");
      return new Response(
        JSON.stringify({ success: false, error_code: "invalid_document_state", message }),
        { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // FASE 2: Descarte no GAS do Drive
    const gasDiscardUrl = Deno.env.get("GC_DRIVE_DISCARD_GAS_URL") ?? "";
    const gasSigningKey = Deno.env.get("GC_DRIVE_DISCARD_SIGNING_KEY") ?? "";

    if (!gasDiscardUrl || !gasSigningKey) {
      safeLog({ correlationId, stage: "missing_gas_config", code: "discard_not_configured", httpStatus: 500 });
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, previousStatus, "discard_not_configured", correlationId);
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
    const reason = "request_expired";

    // Submissão canônica para assinatura HMAC-SHA256
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
          // Trata file_not_found como sucesso idempotente mesmo se resposta HTTP for não-2xx
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

    // Se o descarte falhar no GAS: executa rollback seguro
    if (!isDiscardOk) {
      safeLog({ correlationId, stage: "gas_discard_failed", code: gasErrorCode, httpStatus: 400 });
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, previousStatus, gasErrorCode, correlationId);
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

    // 6. FASE 3: Chamar COMMIT (GAS confirmou a exclusão física no Drive)
    const { data: commitData, error: commitTransportError } = await supabaseAdmin.rpc(
      "conectea_system_commit_dependent_cpf_expiration_v1",
      {
        p_request_id: requestId,
        p_previous_status: previousStatus,
        p_document_action: "discard_required"
      }
    );

    if (commitTransportError) {
      safeLog({ correlationId, stage: "commit_transport_error", code: commitTransportError.code });
      
      // Tentativa de retry imediato para mitigar falha transitória de conexão
      const { data: retryCommitData, error: retryCommitTransportError } = await supabaseAdmin.rpc(
        "conectea_system_commit_dependent_cpf_expiration_v1",
        {
          p_request_id: requestId,
          p_previous_status: previousStatus,
          p_document_action: "discard_required"
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

    // 7. Retorno final de sucesso
    return new Response(
      JSON.stringify({
        success: true,
        request_id: requestId,
        status: "expired",
        message: "Solicitação expirada com sucesso."
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (_err) {
    safeLog({ correlationId, stage: "unexpected_error", code: "internal_error" });

    if (prepareSucceeded && !discardConfirmed && supabaseAdmin && requestId && previousStatus) {
      const rollbackOk = await executeRollbackSafe(supabaseAdmin, requestId, previousStatus, "unexpected_handler_error", correlationId);
      if (!rollbackOk) {
        const { status, message } = getSafeErrorMessage("rollback_failed");
        return new Response(
          JSON.stringify({ success: false, error_code: "rollback_failed", message }),
          { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    if (discardConfirmed) {
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
