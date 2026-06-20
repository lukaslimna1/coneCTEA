import { assertEquals, assertRejects } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  decodeBase64UrlStrict,
  decryptAesGcmSeparatedTag
} from "./crypto.ts";

// --- HELPERS EXCLUSIVOS DE TESTE ---

function encodeBase64Url(bytes: Uint8Array): string {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function encryptAesGcmSeparatedTag(
  plainText: string,
  keyBytes: Uint8Array,
  nonceBytes: Uint8Array
): Promise<{ ciphertext: string; authTag: string; nonce: string }> {
  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes as any,
    { name: "AES-GCM" },
    false,
    ["encrypt"]
  );

  const plainTextBytes = new TextEncoder().encode(plainText);
  const encryptedBuffer = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv: nonceBytes as any,
      tagLength: 128,
    },
    key,
    plainTextBytes as any
  );

  const totalBytes = new Uint8Array(encryptedBuffer);
  const ciphertextBytes = totalBytes.subarray(0, totalBytes.length - 16);
  const authTagBytes = totalBytes.subarray(totalBytes.length - 16);

  return {
    ciphertext: encodeBase64Url(ciphertextBytes),
    authTag: encodeBase64Url(authTagBytes),
    nonce: encodeBase64Url(nonceBytes),
  };
}

// Configura uma chave simétrica de teste sintética (32 bytes)
const mockKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockKeyBytes[i] = i + 1;
const mockKeyBase64Url = encodeBase64Url(mockKeyBytes);

const keyEnvName = "CONECTEA_DECRYPTION_KEY_V1";
const originalKeyVal = Deno.env.get(keyEnvName);

function setupEnv() {
  Deno.env.set(keyEnvName, mockKeyBase64Url);
}

function restoreEnv() {
  if (originalKeyVal !== undefined) {
    Deno.env.set(keyEnvName, originalKeyVal);
  } else {
    Deno.env.delete(keyEnvName);
  }
}

// --- SUÍTE DE TESTES ---

Deno.test("Cenário 1 e 3: Ida/volta com e-mail sintético e versão de chave existente", async () => {
  setupEnv();
  try {
    const plainEmail = "usuario-teste-sintetico@conectea.org";
    const nonceBytes = new Uint8Array(12);
    for (let i = 0; i < 12; i++) nonceBytes[i] = i + 10;

    const encrypted = await encryptAesGcmSeparatedTag(plainEmail, mockKeyBytes, nonceBytes);

    const decrypted = await decryptAesGcmSeparatedTag({
      ciphertext: encrypted.ciphertext,
      nonce: encrypted.nonce,
      authTag: encrypted.authTag,
      keyVersion: 1
    });

    assertEquals(decrypted, plainEmail);
  } finally {
    restoreEnv();
  }
});

Deno.test("Cenário 2: Ida/volta com OTP sintético", async () => {
  setupEnv();
  try {
    const plainOtp = "987654";
    const nonceBytes = new Uint8Array(12);
    for (let i = 0; i < 12; i++) nonceBytes[i] = i + 20;

    const encrypted = await encryptAesGcmSeparatedTag(plainOtp, mockKeyBytes, nonceBytes);

    const decrypted = await decryptAesGcmSeparatedTag({
      ciphertext: encrypted.ciphertext,
      nonce: encrypted.nonce,
      authTag: encrypted.authTag,
      keyVersion: 1
    });

    assertEquals(decrypted, plainOtp);
  } finally {
    restoreEnv();
  }
});

Deno.test("Cenário 4: Key version inexistente falha com erro sanitizado", async () => {
  setupEnv();
  try {
    const params = {
      ciphertext: "aaaa",
      nonce: "bbbbbbbbbbbbbbbb",
      authTag: "cccccccccccccccccccccc",
      keyVersion: 99 // versão não configurada no env
    };

    await assertRejects(
      async () => {
        await decryptAesGcmSeparatedTag(params);
      },
      Error,
      "missing_decryption_key_version"
    );
  } finally {
    restoreEnv();
  }
});

Deno.test("Cenário 5: Nonce com tamanho inválido falha", async () => {
  setupEnv();
  try {
    const plainText = "dados-teste";
    const invalidNonceBytes = new Uint8Array(8); // 8 bytes em vez de 12
    const correctNonceBytes = new Uint8Array(12);

    const encrypted = await encryptAesGcmSeparatedTag(plainText, mockKeyBytes, correctNonceBytes);

    await assertRejects(
      async () => {
        await decryptAesGcmSeparatedTag({
          ciphertext: encrypted.ciphertext,
          nonce: encodeBase64Url(invalidNonceBytes),
          authTag: encrypted.authTag,
          keyVersion: 1
        });
      },
      Error,
      "invalid_nonce_length"
    );
  } finally {
    restoreEnv();
  }
});

Deno.test("Cenário 6: Auth tag com tamanho inválido falha", async () => {
  setupEnv();
  try {
    const plainText = "dados-teste";
    const invalidAuthTagBytes = new Uint8Array(8); // 8 bytes em vez de 16
    const correctNonceBytes = new Uint8Array(12);

    const encrypted = await encryptAesGcmSeparatedTag(plainText, mockKeyBytes, correctNonceBytes);

    await assertRejects(
      async () => {
        await decryptAesGcmSeparatedTag({
          ciphertext: encrypted.ciphertext,
          nonce: encrypted.nonce,
          authTag: encodeBase64Url(invalidAuthTagBytes),
          keyVersion: 1
        });
      },
      Error,
      "invalid_auth_tag_length"
    );
  } finally {
    restoreEnv();
  }
});

Deno.test("Cenário 7: Ciphertext corrompido falha", async () => {
  setupEnv();
  try {
    const plainText = "dados-teste-seguranca";
    const nonceBytes = new Uint8Array(12);
    for (let i = 0; i < 12; i++) nonceBytes[i] = i + 5;

    const encrypted = await encryptAesGcmSeparatedTag(plainText, mockKeyBytes, nonceBytes);

    const cipherBytes = decodeBase64UrlStrict(encrypted.ciphertext);
    cipherBytes[0] = cipherBytes[0] ^ 0xFF; // altera o primeiro byte
    const corruptedCiphertext = encodeBase64Url(cipherBytes);

    await assertRejects(
      async () => {
        await decryptAesGcmSeparatedTag({
          ciphertext: corruptedCiphertext,
          nonce: encrypted.nonce,
          authTag: encrypted.authTag,
          keyVersion: 1
        });
      },
      Error,
      "decrypt_failed"
    );
  } finally {
    restoreEnv();
  }
});

Deno.test("Cenário 8: Base64Url inválido falha de forma estrita", async () => {
  setupEnv();
  try {
    // Casos de caracteres base64 tradicional que devem falhar no base64url estrito
    const badCases = [
      { c: "aaaa+", name: "Caractere +" },
      { c: "aaaa/", name: "Caractere /" },
      { c: "aaaa=", name: "Caractere = (padding)" },
      { c: "", name: "String vazia" },
      { c: "aaaa bbbb", name: "Contém espaço" },
      { c: "aaaa@bbbb", name: "Caractere especial @" }
    ];

    for (const testCase of badCases) {
      await assertRejects(
        async () => {
          await decryptAesGcmSeparatedTag({
            ciphertext: testCase.c,
            nonce: "bbbbbbbbbbbbbbbb",
            authTag: "cccccccccccccccccccccc",
            keyVersion: 1
          });
        },
        Error,
        "invalid_base64url_input",
        `Falhou ao rejeitar: ${testCase.name}`
      );
    }
  } finally {
    restoreEnv();
  }
});
