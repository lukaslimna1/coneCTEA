/**
 * ConeCTEA — Núcleo Criptográfico para Criação de Solicitação de CPF
 *
 * Helpers puros para validação matemática de CPF, normalização,
 * geração de correlation_id, geração de HMAC SHA-256 e criptografia AES-256-GCM.
 */

declare const crypto: any;

/**
 * 1. Decodifica de forma estrita uma string base64url sem padding para Uint8Array.
 */
export function decodeBase64UrlStrict(value: string): Uint8Array {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]+$/.test(value)) {
    throw new Error("invalid_key_format");
  }

  let base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  while (base64.length % 4) {
    base64 += "=";
  }

  try {
    const binString = atob(base64);
    const bytes = new Uint8Array(binString.length);
    for (let i = 0; i < binString.length; i++) {
      bytes[i] = binString.charCodeAt(i);
    }
    return bytes;
  } catch (_err) {
    throw new Error("invalid_key_format");
  }
}

/**
 * 2. Codifica um array de bytes para string base64url sem padding.
 */
export function encodeBase64Url(bytes: Uint8Array): string {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

/**
 * 3. Validação matemática completa de CPF com base em request_cpf_validator.dart.
 */
export function isValidCpf(cpf: string): boolean {
  if (typeof cpf !== "string") return false;

  // Deixa apenas os dígitos
  const cleanCpf = cpf.replace(/[^\d]/g, "");

  // Deve ter exatamente 11 dígitos
  if (cleanCpf.length !== 11) return false;

  // Rejeita sequências repetidas conhecidas (00000000000, 11111111111, etc)
  if (/^(\d)\1{10}$/.test(cleanCpf)) return false;

  // Primeiro dígito verificador
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(cleanCpf[i], 10) * (10 - i);
  }
  let firstDigit = 11 - (sum % 11);
  if (firstDigit >= 10) firstDigit = 0;

  if (parseInt(cleanCpf[9], 10) !== firstDigit) return false;

  // Segundo dígito verificador
  sum = 0;
  for (let i = 0; i < 10; i++) {
    sum += parseInt(cleanCpf[i], 10) * (11 - i);
  }
  let secondDigit = 11 - (sum % 11);
  if (secondDigit >= 10) secondDigit = 0;

  if (parseInt(cleanCpf[10], 10) !== secondDigit) return false;

  return true;
}

/**
 * 4. Normaliza o CPF limpando caracteres não numéricos e validando matematicamente.
 */
export function normalizeCpf(cpf: string): string {
  if (typeof cpf !== "string") {
    throw new Error("invalid_cpf_format");
  }

  const cleanCpf = cpf.replace(/[^\d]/g, "");

  if (!isValidCpf(cleanCpf)) {
    throw new Error("invalid_cpf_format");
  }

  return cleanCpf;
}

/**
 * 5. Gera um correlation_id aleatório não sensível composto por "corr_" mais 16 bytes aleatórios em base64url.
 */
export function createCorrelationId(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return `corr_${encodeBase64Url(bytes)}`;
}

/**
 * 6. Gerar HMAC SHA-256 em hex lowercase com separação de domínio.
 * Valida a chave de entrada para conter exatamente 32 bytes (256 bits).
 */
export async function generateHmacSha256(params: {
  secretKeyBase64Url: string;
  domainPrefix: string;
  message: string;
}): Promise<string> {
  const { secretKeyBase64Url, domainPrefix, message } = params;

  if (!secretKeyBase64Url || secretKeyBase64Url.trim() === "") {
    throw new Error("missing_secret_key");
  }

  const keyBytes = decodeBase64UrlStrict(secretKeyBase64Url);
  if (keyBytes.length !== 32) {
    throw new Error("invalid_key_length");
  }

  try {
    const key = await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const fullMessage = domainPrefix + message;
    const data = new TextEncoder().encode(fullMessage);
    const signature = await crypto.subtle.sign("HMAC", key, data);

    return Array.from(new Uint8Array(signature))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  } catch (_err) {
    throw new Error("hmac_generation_failed");
  }
}

export interface EncryptResult {
  ciphertext: string;
  nonce: string;
  authTag: string;
  keyVersion: number;
}

/**
 * 7. Criptografar AES-256-GCM em formato compatível com o sistema (separando dados em base64url).
 * Chave de 32 bytes em base64url.
 */
export async function encryptAes256Gcm(params: {
  plainText: string;
  keyBase64Url: string;
  keyVersion?: number;
}): Promise<EncryptResult> {
  const { plainText, keyBase64Url, keyVersion = 1 } = params;

  if (!keyBase64Url || keyBase64Url.trim() === "") {
    throw new Error("missing_encryption_key");
  }

  const keyBytes = decodeBase64UrlStrict(keyBase64Url);
  if (keyBytes.length !== 32) {
    throw new Error("invalid_key_length");
  }

  try {
    const key = await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "AES-GCM" },
      false,
      ["encrypt"]
    );

    // Gerar nonce de 12 bytes
    const nonceBytes = new Uint8Array(12);
    crypto.getRandomValues(nonceBytes);

    const plainTextBytes = new TextEncoder().encode(plainText);
    const encryptedBuffer = await crypto.subtle.encrypt(
      {
        name: "AES-GCM",
        iv: nonceBytes,
        tagLength: 128,
      },
      key,
      plainTextBytes
    );

    const totalBytes = new Uint8Array(encryptedBuffer);
    const ciphertextBytes = totalBytes.subarray(0, totalBytes.length - 16);
    const authTagBytes = totalBytes.subarray(totalBytes.length - 16);

    return {
      ciphertext: encodeBase64Url(ciphertextBytes),
      nonce: encodeBase64Url(nonceBytes),
      authTag: encodeBase64Url(authTagBytes),
      keyVersion,
    };
  } catch (_err) {
    throw new Error("encrypt_failed");
  }
}
