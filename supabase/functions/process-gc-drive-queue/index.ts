/**
 * ConeCTEA — Edge Function: process-gc-drive-queue
 *
 * Processador da fila private.gc_drive_files_to_delete.
 * Consome itens pending, chama o GAS separado de descarte seguro
 * via HMAC-SHA256 e marca o resultado.
 *
 * PROTEÇÃO:
 *   - NÃO aceita chamada do Flutter (sem verify_jwt do usuário).
 *   - Protegida por chave do worker no header x-worker-key.
 *   - Nunca retorna file_id, URL do Drive ou dados pessoais.
 *
 * SECRETS UTILIZADOS:
 *   - SUPABASE_URL (automático)
 *   - SUPABASE_SERVICE_ROLE_KEY (automático)
 *   - GC_DRIVE_WORKER_KEY (chave secreta exigida no header x-worker-key)
 *   - GC_DRIVE_DISCARD_GAS_URL (URL de deploy do GAS de descarte)
 *   - GC_DRIVE_DISCARD_SIGNING_KEY (chave HMAC de assinatura)
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

declare const Deno: any;
declare const crypto: any;

const BATCH_LIMIT = 10;

const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const FILE_ID_REGEX = /^[A-Za-z0-9_-]+$/;
const VALID_REASONS = new Set([
  "request_approved",
  "request_rejected",
  "request_cancelled",
  "request_expired",
  "document_replaced"
]);

// Erros que consideramos fatais (não devem retentar)
const FATAL_ERRORS = new Set([
  "gas_auth_failed",
  "gas_invalid_payload",
  "drive_permission_denied"
]);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-worker-key",
};

interface ResolveResult {
  ok: boolean;
  finalStatus?: "processed" | "pending" | "failed";
}

// ──────────────────────────────────────────────────────────────
// Handler principal
// ──────────────────────────────────────────────────────────────

export async function handler(req: Request): Promise<Response> {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Aceitar apenas POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "method_not_allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    // 1. Validar segredo interno GC_DRIVE_WORKER_KEY
    const workerKey = Deno.env.get("GC_DRIVE_WORKER_KEY") ?? "";
    if (!workerKey) {
      console.error("[process-gc-drive-queue] Configuração de chave de proteção ausente.");
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const providedKey = req.headers.get("x-worker-key") ?? "";
    if (!providedKey || providedKey !== workerKey) {
      return new Response(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Validar configuração de ambiente
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const gasDiscardUrl = Deno.env.get("GC_DRIVE_DISCARD_GAS_URL") ?? "";
    const gasSigningKey = Deno.env.get("GC_DRIVE_DISCARD_SIGNING_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey || !gasDiscardUrl || !gasSigningKey) {
      console.error("[process-gc-drive-queue] Parâmetros de ambiente incompletos.");
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Instanciar cliente Supabase com service_role
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // 4. Liberar itens travados em processing (stale lock recovery)
    const { error: unlockError } = await supabaseAdmin.rpc(
      "conectea_unlock_stale_gc_drive_items_v1"
    );

    if (unlockError) {
      console.error("[process-gc-drive-queue] Falha na limpeza de travas expiradas.");
    }

    // 5. Gerar locked_by seguro com UUID/CorrelationId
    const correlationId = crypto.randomUUID();
    const lockedBy = `worker:${correlationId}`;

    // 6. Buscar e bloquear itens pending
    const { data: pendingItems, error: lockError } = await supabaseAdmin.rpc(
      "conectea_lock_gc_drive_pending_v1",
      { p_limit: BATCH_LIMIT, p_locked_by: lockedBy }
    );

    if (lockError) {
      console.error("[process-gc-drive-queue] Falha ao recuperar lote pendente.");
      return new Response(
        JSON.stringify({ error: "temporarily_unavailable" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let processedCount = 0;
    let retryCount = 0;
    let failedCount = 0;

    if (Array.isArray(pendingItems) && pendingItems.length > 0) {
      for (const item of pendingItems) {
        // Validação defensiva de formato do item
        if (
          !item ||
          typeof item !== "object" ||
          typeof item.id !== "string" ||
          !UUID_REGEX.test(item.id) ||
          typeof item.file_id !== "string" ||
          item.file_id.length < 10 ||
          item.file_id.length > 256 ||
          !FILE_ID_REGEX.test(item.file_id) ||
          typeof item.source_id !== "string" ||
          !UUID_REGEX.test(item.source_id) ||
          typeof item.reason !== "string" ||
          !VALID_REASONS.has(item.reason)
        ) {
          console.error("[process-gc-drive-queue] Item descartado por formato inválido.");
          
          if (item && typeof item.id === "string" && UUID_REGEX.test(item.id)) {
            const res = await resolveItem(supabaseAdmin, item.id, false, lockedBy, "gas_invalid_payload");
            if (res.ok) {
              if (res.finalStatus === "processed") processedCount++;
              else if (res.finalStatus === "pending") retryCount++;
              else if (res.finalStatus === "failed") failedCount++;
            }
          }
          continue;
        }

        const { id, file_id, source_id, reason } = item;

        try {
          const timestamp = new Date().toISOString();
          const action = "secure_discard_v1";

          // String canônica estruturada para HMAC
          const canonicalString = `${action}|${file_id}|${source_id}|${reason}|${timestamp}`;
          const signature = await computeHmacHex(gasSigningKey, canonicalString);

          const gasPayload = {
            action,
            file_id,
            request_id: source_id,
            reason,
            timestamp,
            signature,
          };

          // Chamada segura para o GAS Separado
          let gasResponse: any;
          try {
            const fetchResult = await fetch(gasDiscardUrl, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(gasPayload),
              redirect: "follow",
            });

            gasResponse = await fetchResult.json();
          } catch (_fetchErr) {
            // Falha de rede/timeout -> erro temporário
            const res = await resolveItem(supabaseAdmin, id, false, lockedBy, "gas_unavailable");
            if (res.ok) {
              if (res.finalStatus === "processed") processedCount++;
              else if (res.finalStatus === "pending") retryCount++;
              else if (res.finalStatus === "failed") failedCount++;
            }
            continue;
          }

          // Validar estritamente o formato da resposta do GAS
          if (
            !gasResponse ||
            typeof gasResponse !== "object" ||
            typeof gasResponse.success !== "boolean" ||
            (gasResponse.success === true && gasResponse.status !== "trashed") ||
            (gasResponse.success === false && typeof gasResponse.error !== "string")
          ) {
            console.error("[process-gc-drive-queue] Resposta inválida ou corrompida do GAS.");
            const res = await resolveItem(supabaseAdmin, id, false, lockedBy, "unknown_error");
            if (res.ok) {
              if (res.finalStatus === "processed") processedCount++;
              else if (res.finalStatus === "pending") retryCount++;
              else if (res.finalStatus === "failed") failedCount++;
            }
            continue;
          }

          if (gasResponse.success === true) {
            // Sucesso absoluto
            const res = await resolveItem(supabaseAdmin, id, true, lockedBy);
            if (res.ok) {
              if (res.finalStatus === "processed") processedCount++;
              else if (res.finalStatus === "pending") retryCount++;
              else if (res.finalStatus === "failed") failedCount++;
            }
          } else {
            // Mapeamento estrito de erros do GAS para a whitelist de RPC
            let errorCode = "unknown_error";
            if (gasResponse.error === "file_not_found") {
              errorCode = "drive_file_not_found";
            } else if (gasResponse.error === "permission_denied") {
              errorCode = "drive_permission_denied";
            } else if (gasResponse.error === "auth_failed") {
              errorCode = "gas_auth_failed";
            } else if (gasResponse.error === "replay_rejected") {
              errorCode = "gas_replay_rejected";
            } else if (gasResponse.error === "invalid_payload") {
              errorCode = "gas_invalid_payload";
            } else if (gasResponse.error === "drive_error") {
              errorCode = "drive_error";
            }

            // Tratar file_not_found como sucesso idempotente (processed)
            if (errorCode === "drive_file_not_found") {
              const res = await resolveItem(supabaseAdmin, id, true, lockedBy);
              if (res.ok) {
                if (res.finalStatus === "processed") processedCount++;
                else if (res.finalStatus === "pending") retryCount++;
                else if (res.finalStatus === "failed") failedCount++;
              }
            } else {
              // Resolver como falha temporária ou permanente
              const res = await resolveItem(supabaseAdmin, id, false, lockedBy, errorCode);
              if (res.ok) {
                if (res.finalStatus === "processed") processedCount++;
                else if (res.finalStatus === "pending") retryCount++;
                else if (res.finalStatus === "failed") failedCount++;
              }
            }
          }

        } catch (itemErr) {
          console.error("[process-gc-drive-queue] Exceção técnica na execução do item.");
          try {
            const res = await resolveItem(supabaseAdmin, id, false, lockedBy, "worker_unavailable");
            if (res.ok) {
              if (res.finalStatus === "processed") processedCount++;
              else if (res.finalStatus === "pending") retryCount++;
              else if (res.finalStatus === "failed") failedCount++;
            }
          } catch (_resolveErr) {
            // Se falhar a comunicação de banco, o unlock_stale agirá preventivamente
          }
        }
      }
    }

    // 7. Retornar resposta limpa sem vazar dados sensíveis
    return new Response(
      JSON.stringify({
        success: true,
        processed_count: processedCount,
        retry_count: retryCount,
        failed_count: failedCount
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("[process-gc-drive-queue] Falha grave no handler do processador.");
    return new Response(
      JSON.stringify({ error: "internal_error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Utilitários auxiliares
// ──────────────────────────────────────────────────────────────

/**
 * Invoca a RPC de resolução no banco de dados.
 * Retorna ok: true e o finalStatus gravado se a gravação transacional foi bem-sucedida.
 */
async function resolveItem(
  supabaseAdmin: any,
  itemId: string,
  success: boolean,
  lockedBy: string,
  errorCode?: string
): Promise<ResolveResult> {
  try {
    if (!itemId) return { ok: false };
    const { data, error } = await supabaseAdmin.rpc(
      "conectea_resolve_gc_drive_item_v1",
      {
        p_id: itemId,
        p_success: success,
        p_locked_by: lockedBy,
        p_error_code: errorCode ?? null,
      }
    );

    if (error) {
      console.error("[process-gc-drive-queue] Falha operacional de RPC.");
      return { ok: false };
    }

    if (data && typeof data === "object" && data.success === true) {
      const finalStatus = data.final_status;
      if (finalStatus === "processed" || finalStatus === "pending" || finalStatus === "failed") {
        return { ok: true, finalStatus };
      }
    }

    return { ok: false };
  } catch (err) {
    console.error("[process-gc-drive-queue] Exceção técnica na RPC.");
    return { ok: false };
  }
}

/**
 * Calcula HMAC-SHA256 e retorna em hexadecimal lowercase.
 */
async function computeHmacHex(key: string, data: string): Promise<string> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(key);
  const msgData = encoder.encode(data);

  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("HMAC", cryptoKey, msgData);
  const hashArray = Array.from(new Uint8Array(signature));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}
