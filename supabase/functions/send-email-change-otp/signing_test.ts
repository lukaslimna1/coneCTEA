import { assertEquals, assertNotEquals, assertRejects } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  sha256Hex,
  buildSignatureBase,
  loadHmacKeyFromBase64UrlEnv,
  signHmacSha256Hex,
  createGasIdempotencyKey,
  createCorrelationId
} from "./signing.ts";

// --- HELPERS EXCLUSIVOS DE TESTE ---

function encodeBase64Url(bytes: Uint8Array): string {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

// Chave sintética válida de 32 bytes
const mockKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockKeyBytes[i] = i + 2;
const mockKeyBase64Url = encodeBase64Url(mockKeyBytes);

const signingKeyEnv = "CONECTEA_HMAC_SIGNING_KEY";
const idempotencyKeyEnv = "CONECTEA_IDEMPOTENCY_SECRET_KEY";

const originalSigningKey = Deno.env.get(signingKeyEnv);
const originalIdempotencyKey = Deno.env.get(idempotencyKeyEnv);

function setupEnv() {
  Deno.env.set(signingKeyEnv, mockKeyBase64Url);
  Deno.env.set(idempotencyKeyEnv, mockKeyBase64Url);
}

function restoreEnv() {
  if (originalSigningKey !== undefined) {
    Deno.env.set(signingKeyEnv, originalSigningKey);
  } else {
    Deno.env.delete(signingKeyEnv);
  }

  if (originalIdempotencyKey !== undefined) {
    Deno.env.set(idempotencyKeyEnv, originalIdempotencyKey);
  } else {
    Deno.env.delete(idempotencyKeyEnv);
  }
}

// --- SUÍTE DE TESTES ---

Deno.test("Testes Sintéticos 1: sha256Hex gera hash hexadecimal determinístico", async () => {
  const input = "payload-sintetico-para-teste";
  const hash1 = await sha256Hex(input);
  const hash2 = await sha256Hex(input);

  assertEquals(hash1, hash2);
  assertEquals(hash1.length, 64);
  assertEquals(/^[a-f0-9]+$/.test(hash1), true);
});

Deno.test("Testes Sintéticos 2: buildSignatureBase monta exatamente a base com 6 linhas", () => {
  const base = buildSignatureBase({
    method: "POST",
    logicalPath: "email-change/send-otp/v1",
    version: "1",
    kid: "kid_2026_01",
    timestamp: "2026-06-19T02:00:00Z",
    bodySha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  });

  const lines = base.split("\n");
  assertEquals(lines.length, 6);
  assertEquals(lines[0], "POST");
  assertEquals(lines[1], "email-change/send-otp/v1");
  assertEquals(lines[2], "1");
  assertEquals(lines[3], "kid_2026_01");
  assertEquals(lines[4], "2026-06-19T02:00:00Z");
  assertEquals(lines[5], "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
});

Deno.test("Testes Sintéticos 3 a 8: alteração de parâmetros e body altera a base e a assinatura", async () => {
  setupEnv();
  try {
    const key = await loadHmacKeyFromBase64UrlEnv(signingKeyEnv);
    const defaultParams = {
      method: "POST",
      logicalPath: "email-change/send-otp/v1",
      version: "1",
      kid: "kid_2026_01",
      timestamp: "2026-06-19T02:00:00Z",
      bodySha256: await sha256Hex("corpo-inicial-sintetico")
    };

    const baseOriginal = buildSignatureBase(defaultParams);
    const sigOriginal = await signHmacSha256Hex({ key, baseString: baseOriginal });

    // 3. Alteração do Method muda assinatura
    const baseMethod = buildSignatureBase({ ...defaultParams, method: "GET" });
    const sigMethod = await signHmacSha256Hex({ key, baseString: baseMethod });
    assertNotEquals(sigOriginal, sigMethod);

    // 4. Alteração do LogicalPath muda assinatura
    const baseLogical = buildSignatureBase({ ...defaultParams, logicalPath: "outro-path/v1" });
    const sigLogical = await signHmacSha256Hex({ key, baseString: baseLogical });
    assertNotEquals(sigOriginal, sigLogical);

    // 5. Alteração da Version muda assinatura
    const baseVersion = buildSignatureBase({ ...defaultParams, version: "2" });
    const sigVersion = await signHmacSha256Hex({ key, baseString: baseVersion });
    assertNotEquals(sigOriginal, sigVersion);

    // 6. Alteração do KID muda assinatura
    const baseKid = buildSignatureBase({ ...defaultParams, kid: "kid_2026_02" });
    const sigKid = await signHmacSha256Hex({ key, baseString: baseKid });
    assertNotEquals(sigOriginal, sigKid);

    // 7. Alteração do Timestamp muda assinatura
    const baseTime = buildSignatureBase({ ...defaultParams, timestamp: "2026-06-19T03:00:00Z" });
    const sigTime = await signHmacSha256Hex({ key, baseString: baseTime });
    assertNotEquals(sigOriginal, sigTime);

    // 8. Alteração do body altera bodySha256 e a assinatura
    const bodySha256Alterado = await sha256Hex("corpo-alterado-sintetico");
    assertNotEquals(defaultParams.bodySha256, bodySha256Alterado);
    
    const baseBody = buildSignatureBase({ ...defaultParams, bodySha256: bodySha256Alterado });
    const sigBody = await signHmacSha256Hex({ key, baseString: baseBody });
    assertNotEquals(sigOriginal, sigBody);
  } finally {
    restoreEnv();
  }
});

Deno.test("Testes Sintéticos 9: signing key ausente falha com erro sanitizado", async () => {
  setupEnv();
  try {
    Deno.env.delete(signingKeyEnv);

    await assertRejects(
      async () => {
        await loadHmacKeyFromBase64UrlEnv(signingKeyEnv);
      },
      Error,
      "missing_hmac_key_env"
    );
  } finally {
    restoreEnv();
  }
});

Deno.test("Testes Sintéticos 10: signing key inválida falha com erro sanitizado", async () => {
  setupEnv();
  try {
    // Chave menor do que 32 bytes
    const shortKeyBytes = new Uint8Array(16);
    Deno.env.set(signingKeyEnv, encodeBase64Url(shortKeyBytes));

    await assertRejects(
      async () => {
        await loadHmacKeyFromBase64UrlEnv(signingKeyEnv);
      },
      Error,
      "invalid_hmac_key"
    );
  } finally {
    restoreEnv();
  }
});

Deno.test("Testes Sintéticos 11 a 13: idempotency key opaca e determinística", async () => {
  setupEnv();
  try {
    const secretKey = await loadHmacKeyFromBase64UrlEnv(idempotencyKeyEnv);
    const challengeId = "99999999-9999-9999-9999-999999999999";
    const purpose = "email_change";
    const sequence = 1;

    // 11. Idempotency key é determinística
    const key1 = await createGasIdempotencyKey({ secretKey, purpose, challengeId, sendSequence: sequence });
    const key2 = await createGasIdempotencyKey({ secretKey, purpose, challengeId, sendSequence: sequence });
    assertEquals(key1, key2);

    // 12. Idempotency key muda ao alterar purpose, challenge_id ou sequence
    const keyPurpose = await createGasIdempotencyKey({ secretKey, purpose: "phone_change", challengeId, sendSequence: sequence });
    const keyChallenge = await createGasIdempotencyKey({ secretKey, purpose, challengeId: "88888888-8888-8888-8888-888888888888", sendSequence: sequence });
    const keySequence = await createGasIdempotencyKey({ secretKey, purpose, challengeId, sendSequence: 2 });
    
    assertNotEquals(key1, keyPurpose);
    assertNotEquals(key1, keyChallenge);
    assertNotEquals(key1, keySequence);

    // 13. Idempotency key tem formato base64url sem padding
    assertEquals(/^[A-Za-z0-9_-]+$/.test(key1), true);
    assertEquals(key1.includes("+"), false);
    assertEquals(key1.includes("/"), false);
    assertEquals(key1.includes("="), false);
  } finally {
    restoreEnv();
  }
});

Deno.test("Testes Sintéticos 14: correlation_id é aleatório, base64url válido e não contém UUID real", () => {
  const id1 = createCorrelationId();
  const id2 = createCorrelationId();

  assertNotEquals(id1, id2);
  assertEquals(id1.startsWith("corr_"), true);

  // Função validadora interna do contrato
  const validateCorrelationIdPayload = (val: string): boolean => {
    // 1. Deve conter apenas caracteres base64url sem padding
    const isBase64Url = /^[A-Za-z0-9_-]+$/.test(val);
    if (!isBase64Url) return false;

    // 2. Não pode conter padding, espaços ou caracteres base64 tradicionais
    if (val.includes("+") || val.includes("/") || val.includes("=") || val.includes(" ")) {
      return false;
    }

    // 3. Não pode ter formato de UUID real (8-4-4-4-12)
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(val);
    if (isUuid) return false;

    return true;
  };

  // Valida IDs gerados (removendo o prefixo "corr_")
  const payload1 = id1.substring(5);
  const payload2 = id2.substring(5);
  assertEquals(validateCorrelationIdPayload(payload1), true);
  assertEquals(validateCorrelationIdPayload(payload2), true);
  assertEquals(id1.length >= 20, true);

  // Fixture negativa explícita: corr_ + UUID real
  const badCorrelationId = "corr_123e4567-e89b-12d3-a456-426614174000";
  const badPayload = badCorrelationId.substring(5);
  assertEquals(validateCorrelationIdPayload(badPayload), false); // Deve ser considerado inválido
});

Deno.test("Testes Sintéticos 15: buildSignatureBase rejeita quebras de linha nos campos individuais", () => {
  const validParams = {
    method: "POST",
    logicalPath: "email-change/send-otp/v1",
    version: "1",
    kid: "kid_2026_01",
    timestamp: "2026-06-19T02:00:00Z",
    bodySha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  };

  // Testa injeção de quebra de linha em cada parâmetro individualmente
  const injectCases = [
    { ...validParams, method: "POST\n" },
    { ...validParams, logicalPath: "email-change/send-otp/v1\r" },
    { ...validParams, version: "1\n2" },
    { ...validParams, kid: "kid\n_2026_01" },
    { ...validParams, timestamp: "2026-06-19T02:00:00Z\r\n" },
    { ...validParams, bodySha256: "e3b0c442\n98fc1c14" }
  ];

  for (const params of injectCases) {
    try {
      buildSignatureBase(params);
      throw new Error("Deveria ter falhado com parâmetro contendo quebra de linha");
    } catch (err) {
      assertEquals((err as Error).message, "invalid_signature_base_params");
    }
  }
});
