/**
 * ConeCTEA — Núcleo Criptográfico Local (AES-256-GCM)
 *
 * Implementação segura para descriptografia em memória de payloads do banco.
 */

/**
 * Decodifica uma string Base64Url sem padding de forma estrita.
 * Rejeita qualquer caractere fora do alfabeto Base64Url ([A-Za-z0-9_-]).
 */
export function decodeBase64UrlStrict(value: string): Uint8Array {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]+$/.test(value)) {
    throw new Error("invalid_base64url_input");
  }

  // Substitui caracteres base64url para base64 padrão
  let base64 = value.replace(/-/g, "+").replace(/_/g, "/");

  // Adiciona padding se necessário
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
    throw new Error("invalid_base64url_input");
  }
}

/**
 * Carrega a chave AES-256-GCM do ambiente a partir da versão especificada.
 * Importa a chave apenas para descriptografia (["decrypt"]).
 */
export async function loadAesGcmKey(version: number): Promise<CryptoKey> {
  if (typeof version !== "number" || version <= 0) {
    throw new Error("missing_decryption_key_version");
  }

  const keyEnvName = `CONECTEA_DECRYPTION_KEY_V${version}`;
  const keyBase64Url = Deno.env.get(keyEnvName);

  if (!keyBase64Url || keyBase64Url.trim() === "") {
    throw new Error("missing_decryption_key_version");
  }

  let keyBytes: Uint8Array;
  try {
    keyBytes = decodeBase64UrlStrict(keyBase64Url);
  } catch (_err) {
    throw new Error("invalid_aes_gcm_key");
  }

  if (keyBytes.length !== 32) {
    throw new Error("invalid_aes_gcm_key");
  }

  try {
    return await crypto.subtle.importKey(
      "raw",
      keyBytes,
      { name: "AES-GCM" },
      false,
      ["decrypt"]
    );
  } catch (_err) {
    throw new Error("invalid_aes_gcm_key");
  }
}

interface DecryptParams {
  ciphertext: string;
  nonce: string;
  authTag: string;
  keyVersion: number;
}

/**
 * Descriptografa um payload AES-256-GCM com tag de autenticação separada.
 * Lança erros genéricos/sanitizados sem expor dados.
 */
export async function decryptAesGcmSeparatedTag(params: DecryptParams): Promise<string> {
  const { ciphertext, nonce, authTag, keyVersion } = params;

  if (ciphertext === undefined || ciphertext === null ||
      nonce === undefined || nonce === null ||
      authTag === undefined || authTag === null ||
      keyVersion === undefined || keyVersion === null) {
    throw new Error("decrypt_failed");
  }

  // 1. Carregar a chave pela versão
  const key = await loadAesGcmKey(keyVersion);

  // 2. Decodificar parâmetros Base64Url
  const ciphertextBytes = decodeBase64UrlStrict(ciphertext);
  const nonceBytes = decodeBase64UrlStrict(nonce);
  const authTagBytes = decodeBase64UrlStrict(authTag);

  // 3. Validar tamanhos de nonce (12 bytes) e auth tag (16 bytes)
  if (nonceBytes.length !== 12) {
    throw new Error("invalid_nonce_length");
  }
  if (authTagBytes.length !== 16) {
    throw new Error("invalid_auth_tag_length");
  }

  // 4. Concatenar Ciphertext || AuthTag
  const encryptedBuffer = new Uint8Array(ciphertextBytes.length + authTagBytes.length);
  encryptedBuffer.set(ciphertextBytes, 0);
  encryptedBuffer.set(authTagBytes, ciphertextBytes.length);

  // 5. Executar descriptografia na Web Crypto API
  try {
    const decryptedBuffer = await crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: nonceBytes,
        tagLength: 128,
      },
      key,
      encryptedBuffer
    );

    return new TextDecoder().decode(decryptedBuffer);
  } catch (_err) {
    throw new Error("decrypt_failed");
  }
}
