import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  decryptAes256Gcm,
  createCorrelationId
} from "./crypto_material.ts";

declare const Deno: any;
declare const EdgeRuntime: any;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export async function handler(req: Request): Promise<Response> {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 2. Aceitar apenas POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "invalid_request" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const correlationId = createCorrelationId();

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

    // Instancia o cliente anon com o token JWT do cabeçalho para validar a identidade do usuário
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

    // Apenas "request_id" é permitido no body
    const bodyKeys = Object.keys(body);
    if (bodyKeys.length !== 1 || !body.request_id || typeof body.request_id !== "string") {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const requestId = body.request_id;

    // Validar se request_id é um UUID válido
    const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
    if (!uuidRegex.test(requestId)) {
      return new Response(
        JSON.stringify({ error: "invalid_request" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Instanciar cliente Supabase com a service_role para ler tabelas privadas
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseServiceKey) {
      console.error(`[Correlation ID: ${correlationId}] SUPABASE_SERVICE_ROLE_KEY ausente.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // 6. Chamar a RPC para obter o payload criptografado
    const { data: payloadRows, error: payloadError } = await supabaseAdmin.rpc(
      "conectea_get_cpf_change_cancel_payload_v1",
      {
        p_user_id: authUserId,
        p_request_id: requestId
      }
    );

    if (payloadError) {
      console.error(`[Correlation ID: ${correlationId}] Erro ao buscar payload da RPC.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!Array.isArray(payloadRows)) {
      console.error(`[Correlation ID: ${correlationId}] Retorno inválido do banco (não é array).`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (payloadRows.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "not_found_or_not_cancelable"
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (payloadRows.length !== 1) {
      console.error(`[Correlation ID: ${correlationId}] Retorno inesperado do banco (múltiplas linhas).`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const payloadRow = payloadRows[0];
    if (payloadRow === null || typeof payloadRow !== "object" || Array.isArray(payloadRow)) {
      console.error(`[Correlation ID: ${correlationId}] Linha de payload inválida ou nula.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { ciphertext, nonce, auth_tag, algorithm, key_version } = payloadRow;

    if (
      typeof ciphertext !== "string" ||
      typeof nonce !== "string" ||
      typeof auth_tag !== "string" ||
      typeof algorithm !== "string" ||
      typeof key_version !== "number"
    ) {
      console.error(`[Correlation ID: ${correlationId}] Tipos inválidos nos campos do payload Row.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Validar metadados da criptografia
    if (algorithm !== "aes-256-gcm" || key_version !== 1) {
      console.error(`[Correlation ID: ${correlationId}] Algoritmo ou versão de chave inválida no banco.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Obter a chave de descriptografia do ambiente
    const decryptionKey = Deno.env.get("CONECTEA_DECRYPTION_KEY_V1") ?? "";
    if (!decryptionKey) {
      console.error(`[Correlation ID: ${correlationId}] CONECTEA_DECRYPTION_KEY_V1 ausente.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 9. Descriptografar e validar o payload descriptografado
    let decryptedText: string;
    try {
      decryptedText = await decryptAes256Gcm({
        ciphertext,
        nonce,
        authTag: auth_tag,
        keyBase64Url: decryptionKey
      });
    } catch (decryptErr) {
      console.error(`[Correlation ID: ${correlationId}] Falha na descriptografia da solicitação.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let payloadObj: any;
    try {
      payloadObj = JSON.parse(decryptedText);
    } catch (_err) {
      console.error(`[Correlation ID: ${correlationId}] Erro ao parsear payload JSON descriptografado.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validar estrutura interna do payload
    if (
      !payloadObj ||
      payloadObj.version !== 1 ||
      payloadObj.type !== "cpf_change_request" ||
      typeof payloadObj.file_id !== "string"
    ) {
      console.error(`[Correlation ID: ${correlationId}] Payload descriptografado inválido.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const fileId = payloadObj.file_id;

    // Validar regex do file_id para impedir injeção SQL ou caminhos inválidos antes de mandar para o banco
    const fileIdRegex = /^[a-zA-Z0-9_-]{10,256}$/;
    if (!fileIdRegex.test(fileId)) {
      console.error(`[Correlation ID: ${correlationId}] Formato inválido do file_id extraído.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 10. Chamar a RPC transacional de cancelamento
    const { data: cancelResult, error: cancelError } = await supabaseAdmin.rpc(
      "conectea_cancel_cpf_change_request_v1",
      {
        p_user_id: authUserId,
        p_request_id: requestId,
        p_file_id: fileId
      }
    );

    if (cancelError || !cancelResult) {
      console.error(`[Correlation ID: ${correlationId}] Erro ao invocar RPC de cancelamento.`);
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (
      typeof cancelResult !== "object" ||
      Array.isArray(cancelResult) ||
      typeof cancelResult.success !== "boolean" ||
      (cancelResult.error_code !== undefined && cancelResult.error_code !== null && typeof cancelResult.error_code !== "string")
    ) {
      console.error(`[Correlation ID: ${correlationId}] Formato inesperado no retorno da RPC de cancelamento.`);
      return new Response(
        JSON.stringify({
          success: false,
          error: "unavailable"
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { success, error_code } = cancelResult;

    if (success === true) {
      // Disparo automático e assíncrono (best-effort) do processador de descarte
      try {
        const workerKey = Deno.env.get("GC_DRIVE_WORKER_KEY") ?? "";
        if (workerKey) {
          const triggerWorkerPromise = (async () => {
            try {
              const workerUrl = `${supabaseUrl}/functions/v1/process-gc-drive-queue`;
              const response = await fetch(workerUrl, {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  "x-worker-key": workerKey,
                },
              });
              if (!response.ok) {
                console.error("[cancel-cpf-change-request] Falha ao acionar worker de descarte (status não-ok).");
              } else {
                console.log("[cancel-cpf-change-request] Worker de descarte acionado com sucesso.");
              }
            } catch (_err) {
              console.error("[cancel-cpf-change-request] Erro técnico sanitizado ao acionar worker de descarte.");
            }
          })();

          // Utilizar EdgeRuntime.waitUntil para execução assíncrona pós-resposta
          if (typeof EdgeRuntime !== "undefined" && EdgeRuntime.waitUntil) {
            EdgeRuntime.waitUntil(triggerWorkerPromise);
          } else {
            triggerWorkerPromise.catch(() => {});
          }
        } else {
          console.error("[cancel-cpf-change-request] Chave de worker indisponível no ambiente.");
        }
      } catch (_triggerErr) {
        console.error("[cancel-cpf-change-request] Falha sanitizada ao agendar acionamento de descarte.");
      }

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // Mapear erros de lógica retornados
      const mappedError = error_code === "not_found"
        ? "not_found"
        : (error_code === "invalid_status" ? "invalid_status" : "unavailable");

      return new Response(
        JSON.stringify({
          success: false,
          error: mappedError
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

  } catch (err) {
    console.error(`[Correlation ID: ${correlationId}] Erro inesperado no cancelamento.`);
    return new Response(
      JSON.stringify({ error: "internal_error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

if ((import.meta as any).main) {
  serve(handler);
}
