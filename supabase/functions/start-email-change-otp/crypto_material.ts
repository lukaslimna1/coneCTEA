/**
 * ConeCTEA — Núcleo Criptográfico para Início de Alteração de E-mail
 *
 * Helpers puros para normalização, mascaramento, geração de OTP,
 * geração de assinaturas HMAC de domínio separado e criptografia compatível.
 */

declare const crypto: any;

/**
 * 1. Normaliza e-mail de destino.
 * Limites estritos: 3..254 caracteres.
 * Lança erros genéricos/sanitizados sem expor dados.
 */
export function normalizeEmail(email: string): string {
  if (typeof email !== "string") {
    throw new Error("invalid_email_format");
  }

  const trimmed = email.trim();
  if (trimmed.length < 3 || trimmed.length > 254) {
    throw new Error("invalid_email_length");
  }

  const normalized = trimmed.toLowerCase();

  // Validação mínima de formato via regex robusta
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(normalized)) {
    throw new Error("invalid_email_format");
  }

  return normalized;
}

/**
 * 2. Gerar máscara pública de e-mail (ex: lu***@do***.com).
 * Nunca expõe o e-mail completo e lida com e-mails curtos sem quebrar.
 */
export function maskEmail(email: string): string {
  if (typeof email !== "string" || !email.includes("@")) {
    return "***";
  }

  const parts = email.split("@");
  if (parts.length !== 2) {
    return "***";
  }

  const local = parts[0];
  const domain = parts[1];

  let maskedLocal = "";
  if (local.length >= 3) {
    maskedLocal = local.substring(0, 2) + "***";
  } else if (local.length > 0) {
    maskedLocal = local.substring(0, 1) + "***";
  } else {
    maskedLocal = "***";
  }

  let maskedDomain = "";
  const dotIndex = domain.indexOf(".");

  if (dotIndex !== -1) {
    const domainName = domain.substring(0, dotIndex);
    const tld = domain.substring(dotIndex);

    let maskedName = "";
    if (domainName.length >= 3) {
      maskedName = domainName.substring(0, 2) + "***";
    } else if (domainName.length > 0) {
      maskedName = domainName.substring(0, 1) + "***";
    } else {
      maskedName = "***";
    }
    maskedDomain = maskedName + tld;
  } else {
    if (domain.length >= 3) {
      maskedDomain = domain.substring(0, 2) + "***";
    } else if (domain.length > 0) {
      maskedDomain = domain.substring(0, 1) + "***";
    } else {
      maskedDomain = "***";
    }
  }

  return `${maskedLocal}@${maskedDomain}`;
}

/**
 * 3. Gerar OTP com 6 dígitos usando crypto.getRandomValues de forma segura e sem viés de módulo.
 */
export function generateOtp(): string {
  let otp = "";
  for (let i = 0; i < 6; i++) {
    let val: number;
    do {
      const singleByte = new Uint8Array(1);
      crypto.getRandomValues(singleByte);
      val = singleByte[0];
    } while (val >= 250); // descarta val >= 250 para eliminar viés de módulo 10
    otp += (val % 10).toString();
  }
  return otp;
}

/**
 * Helper estrito para decodificar base64url sem padding.
 */
function decodeBase64UrlStrict(value: string): Uint8Array {
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
 * Helper estrito para codificar em base64url sem padding.
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
 * 4. Gerar HMAC SHA-256 em hex lowercase com separação de domínio.
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
 * 5. Criptografar AES-256-GCM em formato compatível com send-email-change-otp/crypto.ts
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
