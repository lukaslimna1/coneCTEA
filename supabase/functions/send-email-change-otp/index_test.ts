import { assertEquals, assertNotEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { handler, canonicalizeObject } from "./index.ts";

// --- HELPERS EXCLUSIVOS DE TESTE ---

function encodeBase64Url(bytes: Uint8Array): string {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function encryptAesGcm(
  plainText: string,
  keyBytes: Uint8Array,
  nonceBytes: Uint8Array
): Promise<{ ciphertext: string; authTag: string; nonce: string }> {
  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: "AES-GCM" },
    false,
    ["encrypt"]
  );

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
    authTag: encodeBase64Url(authTagBytes),
    nonce: encodeBase64Url(nonceBytes),
  };
}

// Chaves sintéticas de teste
const mockHmacKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockHmacKeyBytes[i] = i + 1;
const mockHmacKeyBase64Url = encodeBase64Url(mockHmacKeyBytes);

const mockAesKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockAesKeyBytes[i] = i + 10;
const mockAesKeyBase64Url = encodeBase64Url(mockAesKeyBytes);

// Massa de dados encriptada sintética válida
const nonceEmailBytes = new Uint8Array(12);
for (let i = 0; i < 12; i++) nonceEmailBytes[i] = i + 10;
const nonceOtpBytes = new Uint8Array(12);
for (let i = 0; i < 12; i++) nonceOtpBytes[i] = i + 20;

const testEmailValido = "usuario-teste-sintetico@conectea.org";
const testOtpValido = "987654";

// --- MOCKS GLOBAIS ---

const originalFetch = globalThis.fetch;
const originalLog = console.log;
const originalWarn = console.warn;
const originalError = console.error;

let lastGasRequest: { url: string; headers: Headers; body: any } | null = null;
let lastRpcCalls: { name: string; body: any }[] = [];
let mockAuthResponse: { status: number; body: any } = { status: 200, body: {} };
let mockClaimResponse: { status: number; body: any } = { status: 200, body: {} };
let mockGasResponse: { status: number; body: any } = { status: 200, body: {} };
let mockRpcResponses: Record<string, { status: number; body: any }> = {};
let shouldGasTimeout = false;
let interceptedLogs: string[] = [];

function setupConsoleInterceptor() {
  interceptedLogs = [];
  console.log = (...args) => {
    interceptedLogs.push(args.join(" "));
  };
  console.warn = (...args) => {
    interceptedLogs.push(args.join(" "));
  };
  console.error = (...args) => {
    interceptedLogs.push(args.join(" "));
  };
}

function restoreConsole() {
  console.log = originalLog;
  console.warn = originalWarn;
  console.error = originalError;
}

function setupFetchMock() {
  lastGasRequest = null;
  lastRpcCalls = [];
  shouldGasTimeout = false;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const urlStr = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;

    // Supabase Auth getUser()
    if (urlStr.includes("/auth/v1/user")) {
      return new Response(JSON.stringify(mockAuthResponse.body), {
        status: mockAuthResponse.status,
        headers: { "Content-Type": "application/json" }
      });
    }

    // RPCs
    if (urlStr.includes("/rest/v1/rpc/")) {
      const parts = urlStr.split("/rpc/");
      const rpcName = parts[1]?.split("?")[0] || "";
      let reqBody: any = {};
      if (init?.body) {
        reqBody = JSON.parse(init.body as string);
      }
      lastRpcCalls.push({ name: rpcName, body: reqBody });

      if (rpcName === "conectea_claim_email_change_challenge_delivery_v1") {
        return new Response(JSON.stringify(mockClaimResponse.body), {
          status: mockClaimResponse.status,
          headers: { "Content-Type": "application/json" }
        });
      }

      const customResp = mockRpcResponses[rpcName];
      if (customResp) {
        return new Response(JSON.stringify(customResp.body), {
          status: customResp.status,
          headers: { "Content-Type": "application/json" }
        });
      }

      return new Response(JSON.stringify({}), { status: 200, headers: { "Content-Type": "application/json" } });
    }

    // GAS
    if (urlStr.includes("macros/s/mock-gas/exec") || urlStr.includes("script.google.com")) {
      if (shouldGasTimeout) {
        await new Promise((_, reject) => {
          if (init?.signal) {
            init.signal.addEventListener("abort", () => reject(new DOMException("The user aborted a request.", "AbortError")));
          }
        });
      }

      let reqBody: any = {};
      if (init?.body) {
        reqBody = JSON.parse(init.body as string);
      }
      const headers = new Headers(init?.headers);
      lastGasRequest = { url: urlStr, headers, body: reqBody };

      return new Response(JSON.stringify(mockGasResponse.body), {
        status: mockGasResponse.status,
        headers: { "Content-Type": "application/json" }
      });
    }

    return new Response(JSON.stringify({ error: "not_found" }), { status: 404 });
  };
}

function restoreFetchMock() {
  globalThis.fetch = originalFetch;
}

function setupTest() {
  Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
  Deno.env.set("SUPABASE_ANON_KEY", "mock-anon-key");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "mock-service-role-key");
  Deno.env.set("CONECTEA_GAS_URL", "https://script.google.com/macros/s/mock-gas/exec");
  Deno.env.set("CONECTEA_EDGE_GAS_SIGNING_KEY", mockHmacKeyBase64Url);
  Deno.env.set("CONECTEA_EDGE_GAS_SIGNING_KID", "kid_test_v1");
  Deno.env.set("CONECTEA_IDEMPOTENCY_SECRET_KEY", mockHmacKeyBase64Url);
  Deno.env.set("CONECTEA_DECRYPTION_KEY_V1", mockAesKeyBase64Url);

  setupFetchMock();
  setupConsoleInterceptor();

  // Reset dos retornos dos mocks
  mockAuthResponse = { status: 200, body: { id: "a8843eed-30db-fdbd-ed51-e1db41766ca6", email: "test@example.com" } };
  mockClaimResponse = { status: 200, body: { claimed: false } };
  mockGasResponse = { status: 200, body: { status: "sent" } };
  mockRpcResponses = {};
  shouldGasTimeout = false;
}

function cleanupTest() {
  restoreFetchMock();
  restoreConsole();
  Deno.env.delete("SUPABASE_URL");
  Deno.env.delete("SUPABASE_ANON_KEY");
  Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
  Deno.env.delete("CONECTEA_GAS_URL");
  Deno.env.delete("CONECTEA_EDGE_GAS_SIGNING_KEY");
  Deno.env.delete("CONECTEA_EDGE_GAS_SIGNING_KID");
  Deno.env.delete("CONECTEA_IDEMPOTENCY_SECRET_KEY");
  Deno.env.delete("CONECTEA_DECRYPTION_KEY_V1");
}

function assertNoSensitivesInLogs() {
  const sensitiveRegexes = [
    /usuario-teste-sintetico@conectea\.org/i,
    /987654/,
    /a8843eed-30db-fdbd-ed51-e1db41766ca6/, // O UUID de usuário
    /cycle-uuid-sintetico-123/,
    /challenge-uuid-sintetico-456/,
  ];

  for (const logLine of interceptedLogs) {
    for (const regex of sensitiveRegexes) {
      if (regex.test(logLine)) {
        throw new Error(`Dado sensível exposto nos logs: ${logLine}`);
      }
    }
  }
}

// --- SUÍTE DE TESTES ---

// O Cenário 1 não instancia o Supabase Client, portanto não exige bypass dos sanitizers.
Deno.test("Orquestração - Cenário 1: Sem JWT -> Rejeita", async () => {
  setupTest();
  try {
    const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        cycle_id: "cycle-uuid-sintetico-123",
        challenge_id: "challenge-uuid-sintetico-456"
      })
    });

    const res = await handler(req);
    assertEquals(res.status, 401);
    const body = await res.json();
    assertEquals(body.error, "unauthorized");
  } finally {
    cleanupTest();
  }
});

Deno.test({
  name: "Orquestração - Cenário 2: JWT inválido -> Rejeita",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      mockAuthResponse = { status: 401, body: { error: "invalid_token" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-invalido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 401);
      const body = await res.json();
      assertEquals(body.error, "unauthorized");
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 3: Body com user_id ou auth_user_id -> rejeita explicitamente",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456",
          user_id: "malicious-user-id" // ID proibido no body
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 400);
      const body = await res.json();
      assertEquals(body.error, "invalid_request");

      // Validar que a chamada da RPC de claim nunca ocorreu
      const claimCall = lastRpcCalls.find(c => c.name === "conectea_claim_email_change_challenge_delivery_v1");
      assertEquals(claimCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 4: Claim claimed=false -> não chama GAS",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      mockClaimResponse = {
        status: 200,
        body: {
          claimed: false,
          result: "cutoff_expired"
        }
      };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, false);
      assertEquals(body.result, "cutoff_expired");

      assertEquals(lastGasRequest, null);
      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 5: Claim claimed=true + GAS sent -> chama mark_sent",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 3,
          delivery_attempts: 7
        }
      };

      mockGasResponse = { status: 200, body: { status: "sent" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "sent");

      assertExists(lastGasRequest);

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      assertExists(markSentCall);
      assertEquals(markSentCall.body.p_expected_delivery_attempts, 7);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 6: Claim claimed=true + GAS already_sent -> chama mark_sent",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 2
        }
      };

      mockGasResponse = { status: 200, body: { status: "already_sent" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "sent");

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      assertExists(markSentCall);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 7: GAS failed_pre_send_invalid_destination -> chama mark_failed com invalid_destination_permanent",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 3
        }
      };

      mockGasResponse = { status: 200, body: { status: "failed_pre_send_invalid_destination" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_permanent");
      assertEquals(body.reason, "invalid_destination_permanent");

      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertExists(markFailedCall);
      assertEquals(markFailedCall.body.p_expected_delivery_attempts, 3);
      assertEquals(markFailedCall.body.p_failure_reason_private, "invalid_destination_permanent");

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 8: GAS attempt_reserved -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 4
        }
      };

      mockGasResponse = { status: 200, body: { status: "attempt_reserved" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.reason, "attempt_reserved");

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 9: GAS ambiguous_attempted -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 4
        }
      };

      mockGasResponse = { status: 200, body: { status: "ambiguous_attempted" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.reason, "ambiguous_attempted");

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 10: GAS temporary_failure -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 4
        }
      };

      mockGasResponse = { status: 200, body: { status: "temporary_failure" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.reason, "temporary_failure");

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 11: Timeout de GAS -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 4
        }
      };

      shouldGasTimeout = true;

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.error, "gas_network_failure");

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 12: Erro de decrypt -> não chama GAS nem consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: "ciphertext-invalido-aaa",
          destination_nonce: "nonce-invalido-bbb",
          destination_auth_tag: "tag-invalido-ccc",
          destination_encryption_key_version: 1,
          code_ciphertext: "ciphertext-invalido-aaa",
          code_nonce: "nonce-invalido-bbb",
          code_auth_tag: "tag-invalido-ccc",
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 4
        }
      };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, false);
      assertEquals(body.error, "decrypt_failed");

      assertEquals(lastGasRequest, null);

      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 13 & 14: Payload para GAS envelopado, sem headers antigos, validação de canonicalização e privacidade",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 2,
          delivery_attempts: 3
        }
      };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      await handler(req);

      assertExists(lastGasRequest);

      const envelope = lastGasRequest.body;
      assertExists(envelope.meta);
      assertExists(envelope.payload);

      // 1. Meta do envelope contém somente os campos permitidos
      const metaKeys = Object.keys(envelope.meta).sort();
      const expectedMetaKeys = [
        "correlation_id",
        "logical_path",
        "payload_sha256",
        "signature",
        "signature_kid",
        "signature_timestamp",
        "signature_version"
      ];
      assertEquals(metaKeys, expectedMetaKeys);

      // 2. Payload do envelope contém somente os campos permitidos
      const payloadKeys = Object.keys(envelope.payload).sort();
      const expectedPayloadKeys = [
        "body_text",
        "correlation_id",
        "idempotency_key",
        "purpose",
        "recipient_email",
        "subject",
        "send_sequence"
      ].sort();
      assertEquals(payloadKeys, expectedPayloadKeys);

      // 3. Payload não contém user_id, auth_user_id, cycle_id, challenge_id, HMAC, ciphertext, nonce, auth tag, token ou secret
      const forbiddenKeys = [
        "user_id", "auth_user_id", "cycle_id", "challenge_id",
        "ciphertext", "nonce", "auth_tag", "encryption_key_version",
        "secret", "token", "hmac"
      ];
      for (const key of forbiddenKeys) {
        assertEquals(envelope.payload[key], undefined);
        assertEquals(envelope.meta[key], undefined);
      }

      // 4. Edge não envia headers customizados antigos de assinatura
      const headers = lastGasRequest.headers;
      assertEquals(headers.get("X-Conectea-Signature-Version"), null);
      assertEquals(headers.get("X-Conectea-Signature-KID"), null);
      assertEquals(headers.get("X-Conectea-Signature-Timestamp"), null);
      assertEquals(headers.get("X-Conectea-Body-SHA256"), null);
      assertEquals(headers.get("X-Conectea-Signature"), null);
      assertEquals(headers.get("X-Conectea-Correlation-ID"), null);

      // 5. Edge não envia assinatura/metadados por query string
      const gasUrlObj = new URL(lastGasRequest.url);
      assertEquals(gasUrlObj.searchParams.get("signature"), null);
      assertEquals(gasUrlObj.searchParams.get("signature_kid"), null);
      assertEquals(gasUrlObj.searchParams.get("signature_timestamp"), null);

      // 6. payload_sha256 é calculado sobre payload canônico
      const canonicalFromTest = canonicalizeObject(envelope.payload);
      // Fazer sha256 síncrono local no teste para conferir
      const hash = crypto.subtle ? null : await (async () => {
        // Fallback síncrono ou Deno Web Crypto
        const msgUint8 = new TextEncoder().encode(canonicalFromTest);
        const hashBuffer = await crypto.subtle.digest("SHA-256", msgUint8);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
      })();
      if (hash) {
        assertEquals(envelope.meta.payload_sha256, hash);
      }

      // 7. reordenação de chaves do payload não altera o hash canônico
      const reorderedPayload = {
        subject: envelope.payload.subject,
        purpose: envelope.payload.purpose,
        recipient_email: envelope.payload.recipient_email,
        idempotency_key: envelope.payload.idempotency_key,
        send_sequence: envelope.payload.send_sequence,
        body_text: envelope.payload.body_text,
        correlation_id: envelope.payload.correlation_id
      };
      assertEquals(canonicalizeObject(envelope.payload), canonicalizeObject(reorderedPayload));

      // 8. alteração de qualquer campo do payload altera o hash canônico
      const modifiedPayload = { ...envelope.payload, subject: "Assunto Alterado" };
      assertNotEquals(canonicalizeObject(envelope.payload), canonicalizeObject(modifiedPayload));

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});


// OPTIONS preflight não instancia o Supabase Client, então não exige bypass de sanitizers.
Deno.test("Orquestração - Cenário 15: OPTIONS preflight", async () => {
  setupTest();
  try {
    const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
      method: "OPTIONS"
    });

    const res = await handler(req);
    assertEquals(res.status, 200);
    const text = await res.text();
    assertEquals(text, "ok");
    assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
  } finally {
    cleanupTest();
  }
});

Deno.test({
  name: "Orquestração - Cenário 16: GAS HTTP 5xx -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 5
        }
      };

      mockGasResponse = { status: 500, body: {} }; // GAS retorna HTTP 500

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.error, "gas_http_failure");

      // Validar que não consolidou
      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 17: GAS invalid_signature -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 5
        }
      };

      mockGasResponse = { status: 200, body: { status: "invalid_signature" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.error, "gas_invalid_signature");

      // Validar que não consolidou
      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 18: GAS invalid_request -> não chama consolidadores",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 5
        }
      };

      mockGasResponse = { status: 200, body: { status: "invalid_request" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.error, "gas_invalid_request");

      // Validar que não consolidou
      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});

Deno.test({
  name: "Orquestração - Cenário 19: GAS status desconhecido -> não chama consolidadores e não vaza status bruto",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    // NOTA TÉCNICA: O SDK do Supabase inicia conexões e intervals persistentes de auth no background,
    // que mantêm operações ativas no event loop do Deno. A flag desativa o sanitizer de leaks.
    setupTest();
    try {
      const encEmail = await encryptAesGcm(testEmailValido, mockAesKeyBytes, nonceEmailBytes);
      const encOtp = await encryptAesGcm(testOtpValido, mockAesKeyBytes, nonceOtpBytes);

      mockClaimResponse = {
        status: 200,
        body: {
          claimed: true,
          destination_ciphertext: encEmail.ciphertext,
          destination_nonce: encEmail.nonce,
          destination_auth_tag: encEmail.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: encOtp.ciphertext,
          code_nonce: encOtp.nonce,
          code_auth_tag: encOtp.authTag,
          code_encryption_key_version: 1,
          send_sequence: 1,
          delivery_attempts: 5
        }
      };

      // Mock de status do GAS totalmente desconhecido/malicioso
      mockGasResponse = { status: 200, body: { status: "malicious_status_payload_12345" } };

      const req = new Request("https://example.supabase.co/functions/v1/send-email-change-otp", {
        method: "POST",
        headers: {
          "Authorization": "Bearer token-valido",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          cycle_id: "cycle-uuid-sintetico-123",
          challenge_id: "challenge-uuid-sintetico-456"
        })
      });

      const res = await handler(req);
      assertEquals(res.status, 200);
      const body = await res.json();
      assertEquals(body.claimed, true);
      assertEquals(body.status, "failed_temporary");
      assertEquals(body.error, "gas_unknown_status");
      assertNotEquals(body.reason, "malicious_status_payload_12345");

      // Validar que não consolidou
      const markSentCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_sent_v1");
      const markFailedCall = lastRpcCalls.find(c => c.name === "conectea_mark_email_change_challenge_failed_v1");
      assertEquals(markSentCall, undefined);
      assertEquals(markFailedCall, undefined);

      // Validar que o log do console e o body da resposta não contêm o status bruto desconhecido
      for (const logLine of interceptedLogs) {
        assertEquals(logLine.includes("malicious_status_payload_12345"), false);
      }

      assertNoSensitivesInLogs();
    } finally {
      cleanupTest();
    }
  }
});
