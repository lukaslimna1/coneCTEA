import { assertEquals, assertRejects, assertThrows, assertMatch } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  normalizeEmail,
  maskEmail,
  generateOtp,
  generateHmacSha256,
  encryptAes256Gcm
} from "./crypto_material.ts";
import { decryptAesGcmSeparatedTag } from "../send-email-change-otp/crypto.ts";

declare const Deno: any;

// Helper sintético para gerar chave AES/HMAC sintética de 32 bytes
function generateSyntheticKeyBase64Url(size = 32): string {
  const bytes = new Uint8Array(size);
  for (let i = 0; i < size; i++) {
    bytes[i] = (i * 7 + 13) % 256;
  }
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

const mockKeyBase64Url = generateSyntheticKeyBase64Url(32);
const mockInvalidSizeKeyBase64Url = generateSyntheticKeyBase64Url(16);

// --- TESTES ---

// 1. normalização aceita e-mail válido e reduz para lowercase
Deno.test("normalização aceita e-mail válido e reduz para lowercase", () => {
  const result = normalizeEmail("  User.Name@Example.Test  ");
  assertEquals(result, "user.name@example.test");
});

// 2. normalização rejeita e-mail inválido
Deno.test("normalização rejeita e-mail inválido", () => {
  assertThrows(() => normalizeEmail("invalid-email"), Error, "invalid_email_format");
  assertThrows(() => normalizeEmail("invalid@"), Error, "invalid_email_format");
  assertThrows(() => normalizeEmail("@domain.com"), Error, "invalid_email_format");
  assertThrows(() => normalizeEmail("a @b.com"), Error, "invalid_email_format");
});

// 3. normalização rejeita e-mail vazio/curto/grande demais
Deno.test("normalização rejeita e-mail vazio/curto/grande demais", () => {
  // Comprimento 0
  assertThrows(() => normalizeEmail(""), Error, "invalid_email_length");
  // Comprimento menor que 3 (ex: "a@")
  assertThrows(() => normalizeEmail("a@"), Error, "invalid_email_length");
  
  // Comprimento maior que 254 (ex: 255)
  const longLocal = "a".repeat(251);
  const longEmail = `${longLocal}@b.c`;
  assertThrows(() => normalizeEmail(longEmail), Error, "invalid_email_length");
});

// 4. máscara não expõe e-mail completo
Deno.test("máscara não expõe e-mail completo", () => {
  const email = "user.name@example.test";
  const masked = maskEmail(email);
  // O e-mail original completo não deve estar na string
  assertEquals(masked.includes(email), false);
  // Espera-se us***@ex***.test
  assertEquals(masked, "us***@ex***.test");
});

// 5. máscara funciona com endereços curtos
Deno.test("máscara funciona com endereços curtos", () => {
  // ab@go.com -> local "ab" (length 2) -> a***; domainName "go" (length 2) -> g***
  assertEquals(maskEmail("ab@go.com"), "a***@g***.com");
  // a@b.c -> local "a" (length 1) -> a***; domainName "b" (length 1) -> b***
  assertEquals(maskEmail("a@b.c"), "a***@b***.c");
  // caso sem ponto no domínio (embora improvável para e-mails válidos)
  assertEquals(maskEmail("x@y"), "x***@y***");
});

// 6. OTP tem exatamente 6 dígitos
Deno.test("OTP tem exatamente 6 dígitos", () => {
  const otp = generateOtp();
  assertEquals(otp.length, 6);
});

// 7. OTP preserva formato numérico
Deno.test("OTP preserva formato numérico", () => {
  const otp = generateOtp();
  assertMatch(otp, /^\d{6}$/);
});

// 8. HMAC é determinístico para mesma entrada
Deno.test("HMAC é determinístico para mesma entrada", async () => {
  const params = {
    secretKeyBase64Url: mockKeyBase64Url,
    domainPrefix: "conectea:email_change:code:v1:",
    message: "challenge_123"
  };
  const hmac1 = await generateHmacSha256(params);
  const hmac2 = await generateHmacSha256(params);
  assertEquals(hmac1, hmac2);
  assertEquals(hmac1.length, 64);
});

// 9. HMAC muda quando muda domínio
Deno.test("HMAC muda quando muda domínio", async () => {
  const hmac1 = await generateHmacSha256({
    secretKeyBase64Url: mockKeyBase64Url,
    domainPrefix: "conectea:email_change:code:v1:",
    message: "challenge_123"
  });
  const hmac2 = await generateHmacSha256({
    secretKeyBase64Url: mockKeyBase64Url,
    domainPrefix: "conectea:email_change:destination:v1:",
    message: "challenge_123"
  });
  assertEquals(hmac1 !== hmac2, true);
});

// 10. HMAC muda quando muda entrada
Deno.test("HMAC muda quando muda entrada", async () => {
  const hmac1 = await generateHmacSha256({
    secretKeyBase64Url: mockKeyBase64Url,
    domainPrefix: "conectea:email_change:code:v1:",
    message: "challenge_123"
  });
  const hmac2 = await generateHmacSha256({
    secretKeyBase64Url: mockKeyBase64Url,
    domainPrefix: "conectea:email_change:code:v1:",
    message: "challenge_456"
  });
  assertEquals(hmac1 !== hmac2, true);
});

// 11. HMAC falha com secret ausente
Deno.test("HMAC falha com secret ausente", async () => {
  await assertRejects(
    async () => {
      await generateHmacSha256({
        secretKeyBase64Url: "",
        domainPrefix: "conectea:email_change:code:v1:",
        message: "challenge_123"
      });
    },
    Error,
    "missing_secret_key"
  );
});

// 12. HMAC falha com secret base64url inválida
Deno.test("HMAC falha com secret base64url inválida", async () => {
  await assertRejects(
    async () => {
      await generateHmacSha256({
        // caractere '+' não é válido base64url sem padding
        secretKeyBase64Url: "abcd+1234_xyz",
        domainPrefix: "conectea:email_change:code:v1:",
        message: "challenge_123"
      });
    },
    Error,
    "invalid_key_format"
  );
});

// 13. HMAC falha com chave de tamanho diferente de 32 bytes
Deno.test("HMAC falha com chave de tamanho diferente de 32 bytes", async () => {
  await assertRejects(
    async () => {
      await generateHmacSha256({
        secretKeyBase64Url: mockInvalidSizeKeyBase64Url,
        domainPrefix: "conectea:email_change:code:v1:",
        message: "challenge_123"
      });
    },
    Error,
    "invalid_key_length"
  );
});

// 14. encryption gera nonce/tag/ciphertext em base64url sem padding
Deno.test("encryption gera nonce/tag/ciphertext em base64url sem padding", async () => {
  const result = await encryptAes256Gcm({
    plainText: "conteudo-sintetico-secreto",
    keyBase64Url: mockKeyBase64Url
  });

  assertMatch(result.ciphertext, /^[A-Za-z0-9_-]+$/);
  assertMatch(result.nonce, /^[A-Za-z0-9_-]+$/);
  assertMatch(result.authTag, /^[A-Za-z0-9_-]+$/);
  assertEquals(result.ciphertext.includes("="), false);
  assertEquals(result.nonce.includes("="), false);
  assertEquals(result.authTag.includes("="), false);
});

// 15. encryption gera nonce diferente entre chamadas
Deno.test("encryption gera nonce diferente entre chamadas", async () => {
  const result1 = await encryptAes256Gcm({
    plainText: "conteudo-sintetico-secreto",
    keyBase64Url: mockKeyBase64Url
  });
  const result2 = await encryptAes256Gcm({
    plainText: "conteudo-sintetico-secreto",
    keyBase64Url: mockKeyBase64Url
  });
  assertEquals(result1.nonce !== result2.nonce, true);
  assertEquals(result1.ciphertext !== result2.ciphertext, true);
});

// 16. encryption de destination descriptografa com decryptAesGcmSeparatedTag
Deno.test("encryption de destination descriptografa com decryptAesGcmSeparatedTag", async () => {
  const originalEmail = "target@example.test";
  
  // Criptografar usando nossa nova implementação
  const encrypted = await encryptAes256Gcm({
    plainText: originalEmail,
    keyBase64Url: mockKeyBase64Url,
    keyVersion: 1
  });

  // Configurar variável de ambiente temporária para decryptAesGcmSeparatedTag carregar a chave
  Deno.env.set("CONECTEA_DECRYPTION_KEY_V1", mockKeyBase64Url);

  try {
    // Descriptografar usando a implementação da Edge send-email-change-otp existente
    const decrypted = await decryptAesGcmSeparatedTag({
      ciphertext: encrypted.ciphertext,
      nonce: encrypted.nonce,
      authTag: encrypted.authTag,
      keyVersion: encrypted.keyVersion
    });

    assertEquals(decrypted, originalEmail);
  } finally {
    Deno.env.delete("CONECTEA_DECRYPTION_KEY_V1");
  }
});

// 17. encryption de OTP descriptografa com decryptAesGcmSeparatedTag
Deno.test("encryption de OTP descriptografa com decryptAesGcmSeparatedTag", async () => {
  const originalOtp = "123456";
  
  // Criptografar
  const encrypted = await encryptAes256Gcm({
    plainText: originalOtp,
    keyBase64Url: mockKeyBase64Url,
    keyVersion: 1
  });

  // Configurar variável de ambiente temporária
  Deno.env.set("CONECTEA_DECRYPTION_KEY_V1", mockKeyBase64Url);

  try {
    // Descriptografar
    const decrypted = await decryptAesGcmSeparatedTag({
      ciphertext: encrypted.ciphertext,
      nonce: encrypted.nonce,
      authTag: encrypted.authTag,
      keyVersion: encrypted.keyVersion
    });

    assertEquals(decrypted, originalOtp);
  } finally {
    Deno.env.delete("CONECTEA_DECRYPTION_KEY_V1");
  }
});

// 18. erros são sanitizados e não carregam valores sensíveis
Deno.test("erros são sanitizados e não carregam valores sensíveis", async () => {
  const sensitiveEmail = "sensitive@example.test";
  
  // O e-mail em si não deve constar na mensagem do erro de comprimento nem de formato
  try {
    normalizeEmail("");
  } catch (err: any) {
    assertEquals(err.message.includes(sensitiveEmail), false);
    assertEquals(err.message, "invalid_email_length");
  }

  try {
    normalizeEmail("invalid-email");
  } catch (err: any) {
    assertEquals(err.message.includes("invalid-email"), false);
    assertEquals(err.message, "invalid_email_format");
  }

  // Falha na descriptografia não deve expor a chave ou texto
  Deno.env.set("CONECTEA_DECRYPTION_KEY_V1", mockKeyBase64Url);
  try {
    await decryptAesGcmSeparatedTag({
      ciphertext: generateSyntheticKeyBase64Url(32), // ciphertext sintético válido estruturalmente
      nonce: generateSyntheticKeyBase64Url(12), // nonce sintético válido em tamanho
      authTag: generateSyntheticKeyBase64Url(16), // tag sintética válida em tamanho
      keyVersion: 1
    });
  } catch (err: any) {
    assertEquals(err.message, "decrypt_failed");
  } finally {
    Deno.env.delete("CONECTEA_DECRYPTION_KEY_V1");
  }
});
