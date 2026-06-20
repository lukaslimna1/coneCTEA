import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { decryptAesGcmSeparatedTag, decodeBase64UrlStrict } from "./crypto.ts";
import {
  sha256Hex,
  buildSignatureBase,
  loadHmacKeyFromBase64UrlEnv,
  signHmacSha256Hex,
  createGasIdempotencyKey
} from "./signing.ts";

declare const Deno: any;

export interface DeliveryParams {
  supabaseAdmin: SupabaseClient;
  authUserId: string;
  cycleId: string;
  challengeId: string;
  correlationId: string;
}

export interface DeliveryResult {
  httpStatus: number;
  body: any;
}

export async function sendExistingEmailChangeOtp(params: DeliveryParams): Promise<DeliveryResult> {
  const { supabaseAdmin, authUserId, cycleId, challengeId, correlationId } = params;

  try {
    // 1. Validação Preflight de Configurações Críticas
    const gasUrl = Deno.env.get("CONECTEA_GAS_URL");
    const kid = Deno.env.get("CONECTEA_EDGE_GAS_SIGNING_KID");
    const signingKeyBase64Url = Deno.env.get("CONECTEA_EDGE_GAS_SIGNING_KEY");
    const idempotencySecretKeyBase64Url = Deno.env.get("CONECTEA_IDEMPOTENCY_SECRET_KEY");

    if (!gasUrl || !gasUrl.trim()) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_GAS_URL ausente.`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_gas_url" }
      };
    }
    try {
      const parsedUrl = new URL(gasUrl);
      if (parsedUrl.protocol !== "https:") {
        throw new Error("Protocol must be https");
      }
      const allowedHostnames = ["script.google.com", "script.googleusercontent.com"];
      if (!allowedHostnames.includes(parsedUrl.hostname) && !parsedUrl.hostname.endsWith(".google.com") && !parsedUrl.hostname.endsWith(".googleusercontent.com")) {
        throw new Error("Invalid hostname");
      }
    } catch (_urlErr) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_GAS_URL malformada ou insegura.`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_gas_url_invalid" }
      };
    }

    if (!kid || !kid.trim()) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_EDGE_GAS_SIGNING_KID ausente.`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_kid" }
      };
    }

    if (!signingKeyBase64Url || !signingKeyBase64Url.trim()) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_EDGE_GAS_SIGNING_KEY ausente.`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_signing_key" }
      };
    }
    try {
      if (signingKeyBase64Url.includes("+") || signingKeyBase64Url.includes("/") || signingKeyBase64Url.includes("=")) {
        throw new Error("Invalid characters");
      }
      const decodedKey = decodeBase64UrlStrict(signingKeyBase64Url);
      if (decodedKey.length < 32) {
        throw new Error("Key is too short");
      }
    } catch (_err) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_EDGE_GAS_SIGNING_KEY invalida (nao base64url ou menor que 32 bytes).`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_signing_key_invalid" }
      };
    }

    if (!idempotencySecretKeyBase64Url || !idempotencySecretKeyBase64Url.trim()) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_IDEMPOTENCY_SECRET_KEY ausente.`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_idempotency_key" }
      };
    }
    try {
      if (idempotencySecretKeyBase64Url.includes("+") || idempotencySecretKeyBase64Url.includes("/") || idempotencySecretKeyBase64Url.includes("=")) {
        throw new Error("Invalid characters");
      }
      const decodedKey = decodeBase64UrlStrict(idempotencySecretKeyBase64Url);
      if (decodedKey.length < 32) {
        throw new Error("Key is too short");
      }
    } catch (_err) {
      console.error(`[Correlation ID: ${correlationId}] Falha Preflight: CONECTEA_IDEMPOTENCY_SECRET_KEY invalida (nao base64url ou menor que 32 bytes).`);
      return {
        httpStatus: 200,
        body: { error: "preflight_failed_idempotency_key_invalid" }
      };
    }

    // 7. Invocar claim do envio do OTP no banco (Apenas após preflight bem sucedido)
    const { data: claimData, error: claimError } = await supabaseAdmin.rpc(
      "conectea_claim_email_change_challenge_delivery_v1",
      {
        p_user_id: authUserId,
        p_cycle_id: cycleId,
        p_challenge_id: challengeId
      }
    );

    if (claimError || !claimData) {
      console.error(`[Correlation ID: ${correlationId}] Falha de execução da RPC de claim.`);
      return {
        httpStatus: 200,
        body: { error: "claim_failed" }
      };
    }

    // Se o banco negou o claim (por lease ativo, cutoff expirado etc.), retorna sanitizado
    if (claimData.claimed !== true) {
      return {
        httpStatus: 200,
        body: { claimed: false, result: claimData.result }
      };
    }

    // 8. Descriptografar e-mail de destino e código OTP em memória
    let decryptedEmail: string;
    let decryptedOtp: string;

    try {
      decryptedEmail = await decryptAesGcmSeparatedTag({
        ciphertext: claimData.destination_ciphertext,
        nonce: claimData.destination_nonce,
        authTag: claimData.destination_auth_tag,
        keyVersion: claimData.destination_encryption_key_version
      });

      decryptedOtp = await decryptAesGcmSeparatedTag({
        ciphertext: claimData.code_ciphertext,
        nonce: claimData.code_nonce,
        authTag: claimData.code_auth_tag,
        keyVersion: claimData.code_encryption_key_version
      });
    } catch (_decryptErr) {
      console.error(`[Correlation ID: ${correlationId}] Falha na integridade ou descriptografia do material do OTP.`);
      return {
        httpStatus: 200,
        body: { claimed: false, error: "decrypt_failed" }
      };
    }

    // 9. Montar assunto, corpo do e-mail e obter chave de idempotência opaca
    const subject = "Confirmação de Alteração de E-mail — ConeCTEA";
    const bodyText = `Olá!\n\nVocê solicitou a alteração do seu e-mail no aplicativo ConeCTEA.\nCódigo de Confirmação: ${decryptedOtp}\n\nEste código expira em 15 minutos.\nSe você não solicitou essa alteração, ignore este e-mail.`;

    const idempotencySecretKey = await loadHmacKeyFromBase64UrlEnv("CONECTEA_IDEMPOTENCY_SECRET_KEY");
    const idempotencyKey = await createGasIdempotencyKey({
      secretKey: idempotencySecretKey,
      purpose: "email_change",
      challengeId: challengeId,
      sendSequence: claimData.send_sequence
    });

    // 10. Montar payload do GAS (sem material criptográfico do banco)
    const gasPayload = {
      purpose: "email_change",
      idempotency_key: idempotencyKey,
      send_sequence: claimData.send_sequence,
      recipient_email: decryptedEmail,
      subject: subject,
      body_text: bodyText,
      correlation_id: correlationId
    };

    const canonicalPayload = canonicalizeObject(gasPayload);
    const bodySha256 = await sha256Hex(canonicalPayload);
    const timestamp = new Date().toISOString();

    // 11. Computar assinatura simétrica HMAC-SHA256
    const baseString = buildSignatureBase({
      method: "POST",
      logicalPath: "email-change/send-otp/v1",
      version: "1",
      kid: kid,
      timestamp: timestamp,
      bodySha256: bodySha256
    });

    const signingKey = await loadHmacKeyFromBase64UrlEnv("CONECTEA_EDGE_GAS_SIGNING_KEY");
    const signature = await signHmacSha256Hex({ key: signingKey, baseString });

    const envelope = {
      meta: {
        signature_version: "1",
        signature_kid: kid,
        signature_timestamp: timestamp,
        logical_path: "email-change/send-otp/v1",
        payload_sha256: bodySha256,
        signature: signature,
        correlation_id: correlationId
      },
      payload: gasPayload
    };

    const envelopeString = JSON.stringify(envelope);

    // 12. Fazer requisição síncrona HTTP ao GAS com envelope e headers mínimos
    const headers = {
      "Content-Type": "application/json"
    };

    const abortController = new AbortController();
    const timeoutId = setTimeout(() => abortController.abort(), 20000);

    let gasResponse: Response;
    try {
      gasResponse = await fetch(gasUrl, {
        method: "POST",
        headers: headers,
        body: envelopeString,
        signal: abortController.signal
      });
    } catch (_fetchErr) {
      console.warn(`[Correlation ID: ${correlationId}] Timeout ou erro de rede ao chamar o GAS.`);
      return {
        httpStatus: 200,
        body: { claimed: true, status: "failed_temporary", error: "gas_network_failure" }
      };
    } finally {
      clearTimeout(timeoutId);
    }

    if (!gasResponse.ok) {
      const bodyText = await gasResponse.text().catch(() => "");
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status HTTP inválido: ${gasResponse.status}. Redirected: ${gasResponse.redirected}. Length: ${bodyText.length}`);
      return {
        httpStatus: 200,
        body: {
          claimed: true,
          status: "failed_temporary",
          error: "gas_http_failure",
          http_status: gasResponse.status,
          redirected: gasResponse.redirected
        }
      };
    }

    const contentType = gasResponse.headers.get("content-type") ?? "";
    if (!contentType.includes("application/json")) {
      const bodyText = await gasResponse.text().catch(() => "");
      const isHtml = bodyText.trim().toLowerCase().startsWith("<!doctype html>") || bodyText.trim().toLowerCase().startsWith("<html");
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com content-type nao JSON (${contentType}). Redirected: ${gasResponse.redirected}. Corpo HTML: ${isHtml}`);
      return {
        httpStatus: 200,
        body: {
          claimed: true,
          status: "failed_temporary",
          error: "gas_response_not_json",
          redirected: gasResponse.redirected,
          is_html: isHtml
        }
      };
    }

    let gasResult: any;
    try {
      gasResult = await gasResponse.json();
    } catch (_parseErr) {
      console.warn(`[Correlation ID: ${correlationId}] Falha de parse JSON na resposta do GAS. Redirected: ${gasResponse.redirected}`);
      return {
        httpStatus: 200,
        body: {
          claimed: true,
          status: "failed_temporary",
          error: "gas_response_invalid_json",
          redirected: gasResponse.redirected
        }
      };
    }
    const rawGasStatus = gasResult?.status;
    const fencingToken = claimData.delivery_attempts;

    const whitelist = [
      "sent",
      "already_sent",
      "failed_pre_send_invalid_destination",
      "attempt_reserved",
      "ambiguous_attempted",
      "temporary_failure",
      "invalid_signature",
      "invalid_request"
    ];

    const isKnown = typeof rawGasStatus === "string" && whitelist.includes(rawGasStatus);

    if (!isKnown) {
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status desconhecido. Redirected: ${gasResponse.redirected}. Sem consolidação.`);
      return {
        httpStatus: 200,
        body: {
          claimed: true,
          status: "failed_temporary",
          error: "gas_unknown_status",
          redirected: gasResponse.redirected
        }
      };
    }

    const gasStatus = rawGasStatus;

    if (gasStatus === "invalid_signature" || gasStatus === "invalid_request") {
      console.warn(`[Correlation ID: ${correlationId}] GAS recusou a requisição (${gasStatus}). Redirected: ${gasResponse.redirected}. Sem consolidação.`);
      return {
        httpStatus: 200,
        body: {
          claimed: true,
          status: "failed_temporary",
          error: `gas_${gasStatus}`,
          redirected: gasResponse.redirected
        }
      };
    }

    // 13. Mapeamento de consolidação conforme regras
    if (gasStatus === "sent" || gasStatus === "already_sent") {
      // Chamar RPC mark_sent no banco
      const { error: markErr } = await supabaseAdmin.rpc(
        "conectea_mark_email_change_challenge_sent_v1",
        {
          p_user_id: authUserId,
          p_cycle_id: cycleId,
          p_challenge_id: challengeId,
          p_expected_delivery_attempts: fencingToken
        }
      );
      if (markErr) {
        console.error(`[Correlation ID: ${correlationId}] Falha de consolidação mark_sent no banco.`);
      }
      return {
        httpStatus: 200,
        body: { claimed: true, status: "sent" }
      };
    }

    if (gasStatus === "failed_pre_send_invalid_destination") {
      // Chamar RPC mark_failed no banco com motivo restrito
      const { error: markErr } = await supabaseAdmin.rpc(
        "conectea_mark_email_change_challenge_failed_v1",
        {
          p_user_id: authUserId,
          p_cycle_id: cycleId,
          p_challenge_id: challengeId,
          p_expected_delivery_attempts: fencingToken,
          p_failure_reason_private: "invalid_destination_permanent"
        }
      );
      if (markErr) {
        console.error(`[Correlation ID: ${correlationId}] Falha de consolidação mark_failed no banco.`);
      }
      return {
        httpStatus: 200,
        body: { claimed: true, status: "failed_permanent", reason: "invalid_destination_permanent" }
      };
    }

    // Para qualquer outra resposta temporária (attempt_reserved, ambiguous_attempted etc.) da whitelist,
    // não chamamos consolidador. O banco permanece em sending permitindo retry.
    console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status temporário: ${gasStatus}. Sem consolidação.`);
    return {
      httpStatus: 200,
      body: { claimed: true, status: "failed_temporary", reason: gasStatus }
    };

  } catch (err) {
    console.error(`[Correlation ID: ${correlationId}] Erro interno na Edge Function.`);
    return {
      httpStatus: 500,
      body: { error: "internal_server_error" }
    };
  }
}

export function canonicalizeObject(obj: any): string {
  if (obj === null || typeof obj !== "object") {
    return JSON.stringify(obj);
  }
  if (Array.isArray(obj)) {
    const parts: string[] = [];
    for (let i = 0; i < obj.length; i++) {
      parts.push(canonicalizeObject(obj[i]));
    }
    return "[" + parts.join(",") + "]";
  }
  const keys = Object.keys(obj).sort();
  const parts: string[] = [];
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const val = obj[key];
    parts.push(JSON.stringify(key) + ":" + canonicalizeObject(val));
  }
  return "{" + parts.join(",") + "}";
}
