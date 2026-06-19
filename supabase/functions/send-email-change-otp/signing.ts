import { decodeBase64UrlStrict } from "./crypto.ts";

/**
 * ConeCTEA — helpers locais de Assinatura, Idempotência e Correlação Edge → GAS
 */

/**
 * Codifica um array de bytes para string Base64Url sem padding.
 */
function encodeBase64Url(bytes: Uint8Array): string {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

/**
 * Calcula o hash SHA-256 do input em formato hexadecimal lowercase.
 */
export async function sha256Hex(input: string | Uint8Array): Promise<string> {
  if (input === undefined || input === null) {
    throw new Error("invalid_input_for_sha256");
  }
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  const hashBuffer = await crypto.subtle.digest("SHA-256", bytes);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

interface SignatureBaseParams {
  method: string;
  logicalPath: string;
  version: string;
  kid: string;
  timestamp: string;
  bodySha256: string;
}

/**
 * Monta a base canônica de assinatura com exatamente 6 linhas separadas por line-breaks.
 */
export function buildSignatureBase(params: SignatureBaseParams): string {
  const { method, logicalPath, version, kid, timestamp, bodySha256 } = params;
  if (!method || !logicalPath || !version || !kid || !timestamp || !bodySha256) {
    throw new Error("invalid_signature_base_params");
  }

  // Bloqueia quebras de linha nos campos individuais para evitar injeção
  if (
    method.includes("\n") || method.includes("\r") ||
    logicalPath.includes("\n") || logicalPath.includes("\r") ||
    version.includes("\n") || version.includes("\r") ||
    kid.includes("\n") || kid.includes("\r") ||
    timestamp.includes("\n") || timestamp.includes("\r") ||
    bodySha256.includes("\n") || bodySha256.includes("\r")
  ) {
    throw new Error("invalid_signature_base_params");
  }

  return `${method}\n${logicalPath}\n${version}\n${kid}\n${timestamp}\n${bodySha256}`;
}

/**
 * Carrega a chave HMAC-SHA256 a partir de variável de ambiente base64url de no mínimo 32 bytes.
 */
export async function loadHmacKeyFromBase64UrlEnv(envName: string): Promise<CryptoKey> {
  if (!envName) {
    throw new Error("missing_hmac_key_env_name");
  }
  const keyBase64Url = Deno.env.get(envName);
  if (!keyBase64Url || keyBase64Url.trim() === "") {
    throw new Error("missing_hmac_key_env");
  }
  let keyBytes: Uint8Array;
  try {
    keyBytes = decodeBase64UrlStrict(keyBase64Url);
  } catch (_err) {
    throw new Error("invalid_hmac_key");
  }
  if (keyBytes.length < 32) {
    throw new Error("invalid_hmac_key");
  }
  try {
    return await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
  } catch (_err) {
    throw new Error("invalid_hmac_key");
  }
}

interface SignHmacParams {
  key: CryptoKey;
  baseString: string;
}

/**
 * Computa a assinatura HMAC-SHA256 em formato hexadecimal lowercase.
 */
export async function signHmacSha256Hex(params: SignHmacParams): Promise<string> {
  const { key, baseString } = params;
  if (!key || !baseString) {
    throw new Error("invalid_signing_params");
  }
  const bytes = new TextEncoder().encode(baseString);
  const sigBuffer = await crypto.subtle.sign("HMAC", key, bytes);
  const sigArray = Array.from(new Uint8Array(sigBuffer));
  return sigArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

interface IdempotencyKeyParams {
  secretKey: CryptoKey;
  purpose: string;
  challengeId: string;
  sendSequence: number;
}

/**
 * Gera a idempotency key opaca e determinística no formato base64url sem padding.
 */
export async function createGasIdempotencyKey(params: IdempotencyKeyParams): Promise<string> {
  const { secretKey, purpose, challengeId, sendSequence } = params;
  if (!secretKey || !purpose || !challengeId || typeof sendSequence !== "number" || sendSequence <= 0) {
    throw new Error("invalid_idempotency_params");
  }
  const dataString = `conectea:gas:send_otp:v1:${purpose}:${challengeId}:${sendSequence}`;
  const dataBytes = new TextEncoder().encode(dataString);
  const hmacBuffer = await crypto.subtle.sign("HMAC", secretKey, dataBytes);
  return encodeBase64Url(new Uint8Array(hmacBuffer));
}

/**
 * Gera um correlation_id aleatório não sensível composto por "corr_" mais 16 bytes aleatórios em base64url.
 */
export function createCorrelationId(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return `corr_${encodeBase64Url(bytes)}`;
}
