import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { decryptAesGcmSeparatedTag } from "./crypto.ts";
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
    // 7. Invocar claim do envio do OTP no banco
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
    const kid = Deno.env.get("CONECTEA_EDGE_GAS_SIGNING_KID") ?? "kid_default";

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
    const gasUrl = Deno.env.get("CONECTEA_GAS_URL") ?? "";
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
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status HTTP inválido: ${gasResponse.status}`);
      return {
        httpStatus: 200,
        body: { claimed: true, status: "failed_temporary", error: "gas_http_failure" }
      };
    }

    const gasResult = await gasResponse.json();
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
      console.warn(`[Correlation ID: ${correlationId}] GAS respondeu com status desconhecido. Sem consolidação.`);
      return {
        httpStatus: 200,
        body: { claimed: true, status: "failed_temporary", error: "gas_unknown_status" }
      };
    }

    const gasStatus = rawGasStatus;

    if (gasStatus === "invalid_signature" || gasStatus === "invalid_request") {
      console.warn(`[Correlation ID: ${correlationId}] GAS recusou a requisição (${gasStatus}). Sem consolidação.`);
      return {
        httpStatus: 200,
        body: { claimed: true, status: "failed_temporary", error: `gas_${gasStatus}` }
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
