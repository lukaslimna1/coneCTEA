/**
 * ConeCTEA — Núcleo Criptográfico para Cancelamento de Solicitação de CPF
 *
 * Helpers puros para descriptografia AES-256-GCM em zero-knowledge
 * e decodificação base64url estrita.
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
 * 3. Gera um correlation_id aleatório não sensível composto por "corr_" mais 16 bytes aleatórios em base64url.
 */
export function createCorrelationId(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return `corr_${encodeBase64Url(bytes)}`;
}

export interface DecryptParams {
  ciphertext: string;
  nonce: string;
  authTag: string;
  keyBase64Url: string;
}

/**
 * 4. Descriptografar AES-256-GCM a partir de ciphertext, nonce e authTag decodificados.
 * Chave de 32 bytes em base64url.
 */
export async function decryptAes256Gcm(params: DecryptParams): Promise<string> {
  const { ciphertext, nonce, authTag, keyBase64Url } = params;

  if (!keyBase64Url || keyBase64Url.trim() === "") {
    throw new Error("missing_decryption_key");
  }

  const keyBytes = decodeBase64UrlStrict(keyBase64Url);
  if (keyBytes.length !== 32) {
    throw new Error("invalid_key_length");
  }

  const ciphertextBytes = decodeBase64UrlStrict(ciphertext);
  const nonceBytes = decodeBase64UrlStrict(nonce);
  const authTagBytes = decodeBase64UrlStrict(authTag);

  try {
    const key = await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "AES-GCM" },
      false,
      ["decrypt"]
    );

    // Concatenar o ciphertext com a tag de autenticação ao final (exigência do Web Crypto API)
    const encryptedData = new Uint8Array(ciphertextBytes.length + authTagBytes.length);
    encryptedData.set(ciphertextBytes);
    encryptedData.set(authTagBytes, ciphertextBytes.length);

    const decryptedBuffer = await crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: nonceBytes,
        tagLength: 128,
      },
      key,
      encryptedData
    );

    return new TextDecoder().decode(decryptedBuffer);
  } catch (_err) {
    throw new Error("decrypt_failed");
  }
}
