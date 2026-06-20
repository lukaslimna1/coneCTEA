import { assertEquals, assertNotEquals, assertExists, assertMatch } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { handler } from "./index.ts";
import { encryptAes256Gcm } from "./crypto_material.ts";
import { decryptAesGcmSeparatedTag } from "../send-email-change-otp/crypto.ts";

declare const Deno: any;

// Helper base64url sintético
function encodeBase64Url(bytes: Uint8Array): string {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

// Configuração de chaves sintéticas de teste
const mockKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockKeyBytes[i] = i + 1;
const mockKeyBase64Url = encodeBase64Url(mockKeyBytes);

const mockSessionHmacKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockSessionHmacKeyBytes[i] = i + 10;
const mockSessionHmacKeyBase64Url = encodeBase64Url(mockSessionHmacKeyBytes);

const mockIdempotencySecretKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) mockIdempotencySecretKeyBytes[i] = i + 20;
const mockIdempotencySecretKeyBase64Url = encodeBase64Url(mockIdempotencySecretKeyBytes);

// Token JWT Sintético contendo session_id no payload
const mockSessionId = "d7d13028-eb6e-4ad2-a396-3c0762cf0bb0";
const mockHeaderPart = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" })).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
const mockPayloadPart = btoa(JSON.stringify({ session_id: mockSessionId })).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
const mockJwtToken = `${mockHeaderPart}.${mockPayloadPart}.signature-sintetica`;
const mockAuthHeader = `Bearer ${mockJwtToken}`;

// Helper para gerar chave sintética de tamanho customizado
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

function getMockUser(id: string, email = "user@example.test") {
  return {
    id,
    email,
    aud: "authenticated",
    role: "authenticated",
    email_confirmed_at: new Date().toISOString(),
    confirmed_at: new Date().toISOString(),
    last_sign_in_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    app_metadata: { provider: "email", providers: ["email"] },
    user_metadata: {}
  };
}

function getMockTokenResponse(userId: string, email = "user@example.test") {
  return {
    access_token: "mock-access-token",
    refresh_token: "mock-refresh-token",
    expires_in: 3600,
    token_type: "bearer",
    user: getMockUser(userId, email)
  };
}

// --- MOCKS GLOBAIS DE REDE ---
const originalFetch = globalThis.fetch;
let lastFetchRequests: { url: string; method: string; body: any }[] = [];
let mockGetUserResponse: { status: number; body: any } = {
  status: 200,
  body: getMockUser("98765432-1111-2222-3333-abcdefabcdef", "user@example.test")
};
let mockStartAttemptResponse: { status: number; body: any } = {
  status: 200,
  body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
};
let mockSignInResponse: { status: number; body: any } = {
  status: 200,
  body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef", "user@example.test")
};
let mockFinalizeFailureResponse: { status: number; body: any } = {
  status: 200,
  body: { result: "finalized_failed_credentials" }
};
let mockFinalizeSuccessResponse: { status: number; body: any } = {
  status: 200,
  body: {
    result: "finalized_success",
    cycle_id: "cycle-uuid-123",
    challenge_id: "challenge-uuid-456",
    should_send: true,
    reused: false
  }
};
let mockClaimResponse: { status: number; body: any } = {
  status: 200,
  body: null
};
let mockGasResponse: { status: number; body: any } = {
  status: 200,
  body: { status: "sent" }
};
let mockMarkResponse: { status: number; body: any } = {
  status: 200,
  body: {}
};

function setupFetchMock() {
  lastFetchRequests = [];
  globalThis.fetch = async (input: string | Request | URL, init?: RequestInit): Promise<Response> => {
    const url = typeof input === "string" ? input : (input as any).url || (input as any).toString();
    const method = init?.method ?? "GET";
    const bodyStr = init?.body ? String(init.body) : null;
    let bodyObj: any = null;
    if (bodyStr) {
      try {
        bodyObj = JSON.parse(bodyStr);
      } catch (_e) {
        bodyObj = bodyStr;
      }
    }

    lastFetchRequests.push({ url, method, body: bodyObj });

    const jsonHeaders = { "Content-Type": "application/json" };

    // 1. Auth getUser
    if (url.includes("/auth/v1/user")) {
      return new Response(JSON.stringify(mockGetUserResponse.body), { status: mockGetUserResponse.status, headers: jsonHeaders });
    }
    // 2. Auth signIn
    if (url.includes("/auth/v1/token")) {
      return new Response(JSON.stringify(mockSignInResponse.body), { status: mockSignInResponse.status, headers: jsonHeaders });
    }
    // 3. RPC Start Attempt
    if (url.includes("conectea_start_email_change_reauth_attempt_v1")) {
      return new Response(JSON.stringify(mockStartAttemptResponse.body), { status: mockStartAttemptResponse.status, headers: jsonHeaders });
    }
    // 4. RPC Finalize Failure
    if (url.includes("conectea_finalize_email_change_reauth_failure_v1")) {
      return new Response(JSON.stringify(mockFinalizeFailureResponse.body), { status: mockFinalizeFailureResponse.status, headers: jsonHeaders });
    }
    // 5. RPC Finalize Success
    if (url.includes("conectea_finalize_email_change_reauth_success_v1")) {
      return new Response(JSON.stringify(mockFinalizeSuccessResponse.body), { status: mockFinalizeSuccessResponse.status, headers: jsonHeaders });
    }
    // 6. RPC Claim (delivery.ts)
    if (url.includes("conectea_claim_email_change_challenge_delivery_v1")) {
      let responseBody = mockClaimResponse.body;
      if (!responseBody) {
        // Gera material encriptado válido sintético compatível com as chaves configuradas
        const destEnc = await encryptAes256Gcm({
          plainText: "target@example.test",
          keyBase64Url: mockKeyBase64Url,
          keyVersion: 1
        });
        const codeEnc = await encryptAes256Gcm({
          plainText: "987654",
          keyBase64Url: mockKeyBase64Url,
          keyVersion: 1
        });
        responseBody = {
          claimed: true,
          send_sequence: 1,
          delivery_attempts: 0,
          destination_ciphertext: destEnc.ciphertext,
          destination_nonce: destEnc.nonce,
          destination_auth_tag: destEnc.authTag,
          destination_encryption_key_version: 1,
          code_ciphertext: codeEnc.ciphertext,
          code_nonce: codeEnc.nonce,
          code_auth_tag: codeEnc.authTag,
          code_encryption_key_version: 1
        };
      }
      return new Response(JSON.stringify(responseBody), { status: mockClaimResponse.status, headers: jsonHeaders });
    }
    // 7. GAS
    if (url === "https://script.google.com/macros/s/mock-gas/exec" || url.includes("google.com")) {
      return new Response(JSON.stringify(mockGasResponse.body), { status: mockGasResponse.status, headers: jsonHeaders });
    }
    // 8. RPC Mark Sent/Failed (delivery.ts)
    if (url.includes("/rpc/conectea_mark_email_change_challenge_")) {
      return new Response(JSON.stringify(mockMarkResponse.body), { status: mockMarkResponse.status, headers: jsonHeaders });
    }

    return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers: jsonHeaders });
  };
}

function restoreFetchMock() {
  globalThis.fetch = originalFetch;
}

function setupEnv() {
  Deno.env.set("SUPABASE_URL", "https://jyxpofhoohxdqmkdgwtu.supabase.co");
  Deno.env.set("SUPABASE_ANON_KEY", "mock-anon-key");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "mock-service-role-key");
  Deno.env.set("CONECTEA_SESSION_HMAC_KEY_V1", mockSessionHmacKeyBase64Url);
  Deno.env.set("CONECTEA_DESTINATION_HMAC_KEY_V1", mockKeyBase64Url);
  Deno.env.set("CONECTEA_CODE_HMAC_KEY_V1", mockKeyBase64Url);
  Deno.env.set("CONECTEA_DECRYPTION_KEY_V1", mockKeyBase64Url);
  Deno.env.set("CONECTEA_IDEMPOTENCY_SECRET_KEY", mockIdempotencySecretKeyBase64Url);
  Deno.env.set("CONECTEA_EDGE_GAS_SIGNING_KID", "kid_test_v1");
  Deno.env.set("CONECTEA_EDGE_GAS_SIGNING_KEY", mockKeyBase64Url);
  Deno.env.set("CONECTEA_GAS_URL", "https://script.google.com/macros/s/mock-gas/exec");
}

function cleanEnv() {
  Deno.env.delete("SUPABASE_URL");
  Deno.env.delete("SUPABASE_ANON_KEY");
  Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
  Deno.env.delete("CONECTEA_SESSION_HMAC_KEY_V1");
  Deno.env.delete("CONECTEA_DESTINATION_HMAC_KEY_V1");
  Deno.env.delete("CONECTEA_CODE_HMAC_KEY_V1");
  Deno.env.delete("CONECTEA_DECRYPTION_KEY_V1");
  Deno.env.delete("CONECTEA_IDEMPOTENCY_SECRET_KEY");
  Deno.env.delete("CONECTEA_EDGE_GAS_SIGNING_KID");
  Deno.env.delete("CONECTEA_EDGE_GAS_SIGNING_KEY");
  Deno.env.delete("CONECTEA_GAS_URL");
}

// Reset padrão dos mocks antes de cada teste
function resetMocks() {
  mockGetUserResponse = {
    status: 200,
    body: getMockUser("98765432-1111-2222-3333-abcdefabcdef", "user@example.test")
  };
  mockStartAttemptResponse = {
    status: 200,
    body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
  };
  mockSignInResponse = {
    status: 200,
    body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef", "user@example.test")
  };
  mockFinalizeFailureResponse = {
    status: 200,
    body: { result: "finalized_failed_credentials" }
  };
  mockFinalizeSuccessResponse = {
    status: 200,
    body: {
      result: "finalized_success",
      cycle_id: "cycle-uuid-123",
      challenge_id: "challenge-uuid-456",
      should_send: true,
      reused: false
    }
  };
  mockClaimResponse = { status: 200, body: null };
  mockGasResponse = { status: 200, body: { status: "sent" } };
  mockMarkResponse = { status: 200, body: {} };
}

// --- SUÍTE DE TESTES COM SANITIZATION DESATIVADA OPERACIONALMENTE ---
// sanitizeOps: false e sanitizeResources: false são usados devido ao uso de mocks controlados
// de rede (globalThis.fetch) e timeouts locais simulados em Deno, sem requisições reais ou conexões abertas.

// 1. OPTIONS preflight
Deno.test({
  name: "Handler - Cenário 1: OPTIONS preflight",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    const req = new Request("https://localhost/start-email-change-otp", { method: "OPTIONS" });
    const res = await handler(req);
    assertEquals(res.status, 200);
    assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
    cleanEnv();
  }
});

// 2. método diferente de POST retorna 405
Deno.test({
  name: "Handler - Cenário 2: método diferente de POST retorna 405",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    const req = new Request("https://localhost/start-email-change-otp", { method: "GET" });
    const res = await handler(req);
    assertEquals(res.status, 405);
    const body = await res.json();
    assertEquals(body.error, "method_not_allowed");
    cleanEnv();
  }
});

// 3. sem Authorization retorna unauthorized
Deno.test({
  name: "Handler - Cenário 3: sem Authorization retorna unauthorized",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 401);
    const body = await res.json();
    assertEquals(body.error, "unauthorized");
    cleanEnv();
  }
});

// 4. Bearer inválido retorna unauthorized
Deno.test({
  name: "Handler - Cenário 4: Bearer inválido retorna unauthorized",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": "Bearer token-invalido-curto" },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 401);
    const body = await res.json();
    assertEquals(body.error, "unauthorized");
    restoreFetchMock();
    cleanEnv();
  }
});

// 5. body inválido retorna invalid_request
Deno.test({
  name: "Handler - Cenário 5: body inválido retorna invalid_request",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "invalid_request");
    restoreFetchMock();
    cleanEnv();
  }
});

// 6. body com campo proibido retorna invalid_request
Deno.test({
  name: "Handler - Cenário 6: body com campo proibido retorna invalid_request",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test", user_id: "123" })
    });
    const res = await handler(req);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "invalid_request");
    restoreFetchMock();
    cleanEnv();
  }
});

// 7. user_id no body é rejeitado mesmo se JWT existir
Deno.test({
  name: "Handler - Cenário 7: user_id no body é rejeitado mesmo se JWT existir",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test", auth_user_id: "987" })
    });
    const res = await handler(req);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "invalid_request");
    restoreFetchMock();
    cleanEnv();
  }
});

// 8. e-mail inválido retorna destination_invalid ou invalid_request, sem chamar RPC
Deno.test({
  name: "Handler - Cenário 8: e-mail inválido retorna destination_invalid sem chamar RPC",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "123", new_email: "invalid-email" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "destination_invalid");

    const calledStart = lastFetchRequests.some(r => r.url.includes("conectea_start_email_change_reauth_attempt_v1"));
    assertEquals(calledStart, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// 9. senha vazia retorna invalid_request
Deno.test({
  name: "Handler - Cenário 9: senha vazia retorna invalid_request",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "invalid_request");
    restoreFetchMock();
    cleanEnv();
  }
});

// 10. JWT válido deriva authUserId do token validado
Deno.test({
  name: "Handler - Cenário 10: JWT válido deriva authUserId do token validado",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test" })
    });
    await handler(req);

    const startRpcReq = lastFetchRequests.find(r => r.url.includes("conectea_start_email_change_reauth_attempt_v1"));
    assertExists(startRpcReq);
    assertEquals(startRpcReq.body.p_user_id, "98765432-1111-2222-3333-abcdefabcdef");

    restoreFetchMock();
    cleanEnv();
  }
});

// 11. session_id ausente/inválido retorna unauthorized ou invalid_request
Deno.test({
  name: "Handler - Cenário 11: session_id ausente retorna unauthorized ou invalid_request",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const payloadSemSession = btoa(JSON.stringify({ user_id: "123" })).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
    const jwtSemSession = `${mockHeaderPart}.${payloadSemSession}.signature`;

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": `Bearer ${jwtSemSession}` },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 401);
    const body = await res.json();
    assertEquals(body.error, "unauthorized");

    restoreFetchMock();
    cleanEnv();
  }
});

// 12. start RPC bloqueada não chama Auth de senha
Deno.test({
  name: "Handler - Cenário 12: start RPC bloqueada não chama Auth de senha",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "reauth_blocked" }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "reauth_blocked");

    const calledSignIn = lastFetchRequests.some(r => r.url.includes("/auth/v1/token?grant_type=password"));
    assertEquals(calledSignIn, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// 13. start RPC com throttle retorna try_again_later
Deno.test({
  name: "Handler - Cenário 13: start RPC com throttle retorna try_again_later",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "attempt_in_progress" }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "123", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "try_again_later");

    restoreFetchMock();
    cleanEnv();
  }
});

// 14. senha inválida chama finalize failure
Deno.test({
  name: "Handler - Cenário 14: senha inválida chama finalize failure",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 400,
      body: { error: "invalid_credentials", message: "Invalid login credentials" }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-errada", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "invalid_credentials");

    const calledFailureRpc = lastFetchRequests.some(r => r.url.includes("conectea_finalize_email_change_reauth_failure_v1"));
    assertEquals(calledFailureRpc, true);

    const calledSuccessRpc = lastFetchRequests.some(r => r.url.includes("conectea_finalize_email_change_reauth_success_v1"));
    assertEquals(calledSuccessRpc, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// 15. erro técnico de Auth chama finalize failure técnico
Deno.test({
  name: "Handler - Cenário 15: erro técnico de Auth chama finalize failure técnico",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 503,
      body: { error: "service_unavailable", message: "Database error or timeout" }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "temporarily_unavailable");

    const failureRpcReq = lastFetchRequests.find(r => r.url.includes("conectea_finalize_email_change_reauth_failure_v1"));
    assertExists(failureRpcReq);
    assertEquals(failureRpcReq.body.p_result, "technical_failure");
    assertEquals(failureRpcReq.body.p_failed_technical_code_private, "auth_unavailable");

    restoreFetchMock();
    cleanEnv();
  }
});

// 16. senha válida gera material e chama finalize success
Deno.test({
  name: "Handler - Cenário 16: senha válida gera material e chama finalize success",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: true
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "otp_send_started");
    assertEquals(body.email_masked, "te***@ex***.test");
 
    const successRpcReq = lastFetchRequests.find(r => r.url.includes("conectea_finalize_email_change_reauth_success_v1"));
    assertExists(successRpcReq);
    
    assertEquals(successRpcReq.body.p_destination_email_normalized, "test@example.test");
    assertExists(successRpcReq.body.p_destination_hmac);
    assertExists(successRpcReq.body.p_destination_ciphertext);
    assertExists(successRpcReq.body.p_code_hmac);
    assertExists(successRpcReq.body.p_code_ciphertext);

    restoreFetchMock();
    cleanEnv();
  }
});

// 17. finalize success com should_send=false não chama delivery
Deno.test({
  name: "Handler - Cenário 17: finalize success com should_send=false não chama delivery",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: false
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "otp_send_started");

    const calledClaim = lastFetchRequests.some(r => r.url.includes("conectea_claim_email_change_challenge_delivery_v1"));
    assertEquals(calledClaim, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// 18. finalize success com should_send=true chama sendExistingEmailChangeOtp
Deno.test({
  name: "Handler - Cenário 18: finalize success com should_send=true chama sendExistingEmailChangeOtp",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: true
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "otp_send_started");

    const calledClaim = lastFetchRequests.some(r => r.url.includes("conectea_claim_email_change_challenge_delivery_v1"));
    assertEquals(calledClaim, true);

    const calledGas = lastFetchRequests.some(r => r.url.includes("google.com") || r.url.includes("macros/s/mock-gas"));
    assertEquals(calledGas, true);

    restoreFetchMock();
    cleanEnv();
  }
});

// 19. resposta de sucesso não contém cycle_id/challenge_id/OTP/e-mail completo
Deno.test({
  name: "Handler - Cenário 19: resposta de sucesso não vaza dados sensíveis",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: true
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    const body = await res.json();

    const keys = Object.keys(body);
    assertEquals(keys.includes("status"), true);
    assertEquals(keys.includes("email_masked"), true);
    assertEquals(keys.includes("resend_available_in_seconds"), true);

    assertEquals(keys.includes("cycle_id"), false);
    assertEquals(keys.includes("challenge_id"), false);
    assertEquals(keys.includes("otp"), false);
    assertEquals(keys.includes("code"), false);
    assertEquals(body.email_masked.includes("user@example.test"), false);

    restoreFetchMock();
    cleanEnv();
  }
});

// 20. delivery temporário retorna resposta pública segura
Deno.test({
  name: "Handler - Cenário 20: delivery temporário retorna resposta pública segura",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: true
      }
    };
    // Simula resposta temporariamente falha do GAS
    mockGasResponse = {
      status: 200,
      body: { status: "temporary_failure" }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "try_again_later");

    restoreFetchMock();
    cleanEnv();
  }
});

// 21. erro em delivery não vaza detalhes internos
Deno.test({
  name: "Handler - Cenário 21: erro em delivery não vaza detalhes internos",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: true
      }
    };
    
    globalThis.fetch = async (input: string | Request | URL, init?: RequestInit): Promise<Response> => {
      const url = typeof input === "string" ? input : (input as any).url || (input as any).toString();
      const jsonHeaders = { "Content-Type": "application/json" };
      if (url.includes("/auth/v1/user")) return new Response(JSON.stringify(mockGetUserResponse.body), { status: 200, headers: jsonHeaders });
      if (url.includes("/auth/v1/token")) return new Response(JSON.stringify(mockSignInResponse.body), { status: 200, headers: jsonHeaders });
      if (url.includes("conectea_start_email_change_reauth_attempt_v1")) return new Response(JSON.stringify(mockStartAttemptResponse.body), { status: 200, headers: jsonHeaders });
      if (url.includes("conectea_finalize_email_change_reauth_success_v1")) return new Response(JSON.stringify(mockFinalizeSuccessResponse.body), { status: 200, headers: jsonHeaders });
      if (url.includes("conectea_claim_email_change_challenge_delivery_v1")) {
        const destEnc = await encryptAes256Gcm({ plainText: "target@example.test", keyBase64Url: mockKeyBase64Url });
        const codeEnc = await encryptAes256Gcm({ plainText: "123456", keyBase64Url: mockKeyBase64Url });
        return new Response(JSON.stringify({
          claimed: true, send_sequence: 1, delivery_attempts: 0,
          destination_ciphertext: destEnc.ciphertext, destination_nonce: destEnc.nonce, destination_auth_tag: destEnc.authTag, destination_encryption_key_version: 1,
          code_ciphertext: codeEnc.ciphertext, code_nonce: codeEnc.nonce, code_auth_tag: codeEnc.authTag, code_encryption_key_version: 1
        }), { status: 200, headers: jsonHeaders });
      }
      if (url.includes("google.com") || url.includes("macros/s/mock-gas")) {
        throw new Error("Network connection lost");
      }
      return new Response(JSON.stringify({}), { status: 200 });
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "try_again_later");
    assertEquals(body.message, undefined);

    restoreFetchMock();
    cleanEnv();
  }
});

// 22. logs/respostas não contêm material sensível
Deno.test({
  name: "Handler - Cenário 22: logs/respostas não contêm material sensível",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();

    const originalConsoleError = console.error;
    let errorLogs: string[] = [];
    console.error = (...args: any[]) => {
      errorLogs.push(args.join(" "));
    };

    mockStartAttemptResponse = {
      status: 500,
      body: null
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-ultra-secreta-12345", new_email: "sensivel@example.test" })
    });
    const res = await handler(req);
    // Deve retornar 200 com erro sanitizado e não propagar 500
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "temporarily_unavailable");
    
    const hasSensitiveData = errorLogs.some(log => 
      log.includes("senha-ultra-secreta-12345") ||
      log.includes("sensivel@example.test") ||
      log.includes(mockJwtToken)
    );
    assertEquals(hasSensitiveData, false);

    console.error = originalConsoleError;
    restoreFetchMock();
    cleanEnv();
  }
});

// Cenário 23: Reuso de tentativa com sucesso (reused/succeeded)
// sanitizeOps: false e sanitizeResources: false são usados devido ao uso de mocks controlados
// de rede (globalThis.fetch) e timeouts locais simulados em Deno, sem requisições reais ou conexões abertas.
Deno.test({
  name: "Handler - Cenário 23: reuso de sucesso retorna try_again_later sem chamar delivery",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: {
        result: "reused",
        attempt_state: "succeeded",
        attempt_id: "attempt-uuid-123",
        should_authenticate: false
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "try_again_later");

    // Garantir que não chamou o claim/delivery
    const calledClaim = lastFetchRequests.some(r => r.url.includes("conectea_claim_email_change_challenge_delivery_v1"));
    assertEquals(calledClaim, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// Cenário 24: Reuso de tentativa com sucesso e dados extras inesperados no payload de start
// sanitizeOps: false e sanitizeResources: false são usados devido ao uso de mocks controlados
// de rede (globalThis.fetch) e timeouts locais simulados em Deno, sem requisições reais ou conexões abertas.
Deno.test({
  name: "Handler - Cenário 24: reuso de sucesso com dados extras inesperados ignora e retorna try_again_later sem chamar delivery",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: {
        result: "reused",
        attempt_state: "succeeded",
        attempt_id: "attempt-uuid-123",
        should_authenticate: false,
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456"
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "try_again_later");

    // Garantir que mesmo com os IDs extras na resposta mockada o delivery não é chamado
    const calledClaim = lastFetchRequests.some(r => r.url.includes("conectea_claim_email_change_challenge_delivery_v1"));
    assertEquals(calledClaim, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// Cenário 25: Usuário reautenticado com ID diferente
// sanitizeOps: false e sanitizeResources: false são usados devido ao uso de mocks controlados
// de rede (globalThis.fetch) e timeouts locais simulados em Deno, sem requisições reais ou conexões abertas.
Deno.test({
  name: "Handler - Cenário 25: usuario reautenticado com ID diferente chama finalize failure e retorna temporarily_unavailable",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("id-diferente-do-usuario-autenticado")
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "temporarily_unavailable");

    const failureRpcReq = lastFetchRequests.find(r => r.url.includes("conectea_finalize_email_change_reauth_failure_v1"));
    assertExists(failureRpcReq);
    assertEquals(failureRpcReq.body.p_result, "technical_failure");
    assertEquals(failureRpcReq.body.p_failed_technical_code_private, "auth_internal_error");

    restoreFetchMock();
    cleanEnv();
  }
});

// Cenário 26: Teste garantindo que start-email-change-otp não chama signOut global após signInWithPassword.
Deno.test({
  name: "Handler - Cenário 26: reautenticação bem-sucedida não chama signOut global",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: false
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);

    // Deve ter chamado signInWithPassword (/auth/v1/token)
    const calledSignIn = lastFetchRequests.some(r => r.url.includes("/auth/v1/token"));
    assertEquals(calledSignIn, true);

    // Não deve chamar signOut (/auth/v1/logout)
    const calledSignOut = lastFetchRequests.some(r => r.url.includes("/auth/v1/logout"));
    assertEquals(calledSignOut, false);

    restoreFetchMock();
    cleanEnv();
  }
});

// Cenário 27: Teste garantindo que o fluxo de reautenticação bem-sucedida continua chamando finalize success.
Deno.test({
  name: "Handler - Cenário 27: fluxo de reautenticação bem-sucedida continua chamando finalize success",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockStartAttemptResponse = {
      status: 200,
      body: { result: "created", attempt_id: "attempt-uuid-123", should_authenticate: true }
    };
    mockSignInResponse = {
      status: 200,
      body: getMockTokenResponse("98765432-1111-2222-3333-abcdefabcdef")
    };
    mockFinalizeSuccessResponse = {
      status: 200,
      body: {
        result: "finalized_success",
        cycle_id: "cycle-uuid-123",
        challenge_id: "challenge-uuid-456",
        should_send: false
      }
    };

    const req = new Request("https://localhost/start-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ current_password: "senha-valida", new_email: "test@example.test" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);

    // Deve ter chamado a RPC conectea_finalize_email_change_reauth_success_v1
    const successRpcReq = lastFetchRequests.find(r => r.url.includes("conectea_finalize_email_change_reauth_success_v1"));
    assertExists(successRpcReq);
    assertEquals(successRpcReq.body.p_attempt_id, "attempt-uuid-123");

    restoreFetchMock();
    cleanEnv();
  }
});
