import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { handler } from "./index.ts";
import { encryptAes256Gcm } from "../start-email-change-otp/crypto_material.ts";

declare const Deno: any;

// Helper base64url
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

// Token JWT Sintético contendo session_id no payload
const mockSessionId = "d7d13028-eb6e-4ad2-a396-3c0762cf0bb0";
const mockHeaderPart = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" })).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
const mockPayloadPart = btoa(JSON.stringify({ session_id: mockSessionId })).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
const mockJwtToken = `${mockHeaderPart}.${mockPayloadPart}.signature-sintetica`;
const mockAuthHeader = `Bearer ${mockJwtToken}`;

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

// --- MOCKS GLOBAIS DE REDE ---
const originalFetch = globalThis.fetch;
let lastFetchRequests: { url: string; method: string; body: any }[] = [];
let mockGetUserResponse: { status: number; body: any } = {
  status: 200,
  body: getMockUser("98765432-1111-2222-3333-abcdefabcdef", "user@example.test")
};
let mockConfirmResponse: { status: number; body: any } = {
  status: 200,
  body: null // Definido dinamicamente se necessário
};
let mockUpdateUserResponse: { status: number; body: any } = {
  status: 200,
  body: { id: "98765432-1111-2222-3333-abcdefabcdef", email: "new@example.test" }
};
let mockConsolidateResponse: { status: number; body: any } = {
  status: 200,
  body: { result: "consolidated_success" }
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
    // 2. Auth updateUserById (admin)
    if (url.includes("/auth/v1/admin/users/")) {
      return new Response(JSON.stringify(mockUpdateUserResponse.body), { status: mockUpdateUserResponse.status, headers: jsonHeaders });
    }
    // 3. RPC Confirm OTP
    if (url.includes("conectea_confirm_email_change_otp_v1")) {
      let responseBody = mockConfirmResponse.body;
      if (!responseBody) {
        // Mock padrão de sucesso com payload encriptado
        const destEnc = await encryptAes256Gcm({
          plainText: "new@example.test",
          keyBase64Url: mockKeyBase64Url,
          keyVersion: 1
        });
        responseBody = {
          result: "otp_valid",
          request_id: "request-uuid-123",
          protocol_number: "AC-20260619-9999",
          destination_ciphertext: destEnc.ciphertext,
          destination_nonce: destEnc.nonce,
          destination_auth_tag: destEnc.authTag,
          destination_encryption_key_version: 1
        };
      }
      return new Response(JSON.stringify(responseBody), { status: mockConfirmResponse.status, headers: jsonHeaders });
    }
    // 4. RPC Consolidate Success/Failure
    if (url.includes("conectea_consolidate_email_change_")) {
      return new Response(JSON.stringify(mockConsolidateResponse.body), { status: mockConsolidateResponse.status, headers: jsonHeaders });
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
  Deno.env.set("CONECTEA_CODE_HMAC_KEY_V1", mockKeyBase64Url);
  Deno.env.set("CONECTEA_DECRYPTION_KEY_V1", mockKeyBase64Url);
}

function cleanEnv() {
  Deno.env.delete("SUPABASE_URL");
  Deno.env.delete("SUPABASE_ANON_KEY");
  Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
  Deno.env.delete("CONECTEA_SESSION_HMAC_KEY_V1");
  Deno.env.delete("CONECTEA_CODE_HMAC_KEY_V1");
  Deno.env.delete("CONECTEA_DECRYPTION_KEY_V1");
}

function resetMocks() {
  mockGetUserResponse = {
    status: 200,
    body: getMockUser("98765432-1111-2222-3333-abcdefabcdef", "user@example.test")
  };
  mockConfirmResponse = { status: 200, body: null };
  mockUpdateUserResponse = {
    status: 200,
    body: { id: "98765432-1111-2222-3333-abcdefabcdef", email: "new@example.test" }
  };
  mockConsolidateResponse = { status: 200, body: { result: "consolidated_success" } };
}

// --- SUÍTE DE TESTES ---

// 1. OPTIONS preflight
Deno.test({
  name: "Confirm OTP - Cenário 1: OPTIONS preflight",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    const req = new Request("https://localhost/confirm-email-change-otp", { method: "OPTIONS" });
    const res = await handler(req);
    assertEquals(res.status, 200);
    assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
    cleanEnv();
  }
});

// 2. método diferente de POST retorna 405
Deno.test({
  name: "Confirm OTP - Cenário 2: método diferente de POST retorna 405",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    const req = new Request("https://localhost/confirm-email-change-otp", { method: "GET" });
    const res = await handler(req);
    assertEquals(res.status, 405);
    const body = await res.json();
    assertEquals(body.error, "method_not_allowed");
    cleanEnv();
  }
});

// 3. sem Authorization retorna unauthorized
Deno.test({
  name: "Confirm OTP - Cenário 3: sem Authorization retorna unauthorized",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      body: JSON.stringify({ otp: "123456" })
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
  name: "Confirm OTP - Cenário 4: Bearer inválido retorna unauthorized",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": "Bearer token-curto" },
      body: JSON.stringify({ otp: "123456" })
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
  name: "Confirm OTP - Cenário 5: body inválido retorna invalid_request",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123" }) // Curto demais
    });
    const res = await handler(req);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "invalid_request");
    restoreFetchMock();
    cleanEnv();
  }
});

// 6. body com chaves extras retorna invalid_request
Deno.test({
  name: "Confirm OTP - Cenário 6: body com chaves extras retorna invalid_request",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456", extra_key: "value" })
    });
    const res = await handler(req);
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "invalid_request");
    restoreFetchMock();
    cleanEnv();
  }
});

// 7. OTP expirado retorna otp_expired
Deno.test({
  name: "Confirm OTP - Cenário 7: OTP expirado retorna otp_expired",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockConfirmResponse = {
      status: 200,
      body: { result: "otp_expired" }
    };
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "otp_expired");
    restoreFetchMock();
    cleanEnv();
  }
});

// 8. Limite de tentativas estouradas retorna otp_attempts_exceeded
Deno.test({
  name: "Confirm OTP - Cenário 8: Limite de tentativas estouradas retorna otp_attempts_exceeded",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockConfirmResponse = {
      status: 200,
      body: { result: "otp_attempts_exceeded" }
    };
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "otp_attempts_exceeded");
    restoreFetchMock();
    cleanEnv();
  }
});

// 9. OTP inválido com tentativas restantes retorna otp_invalid e tentativas_restantes
Deno.test({
  name: "Confirm OTP - Cenário 9: OTP inválido retorna otp_invalid e tentativas restantes",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();
    mockConfirmResponse = {
      status: 200,
      body: { result: "otp_invalid", attempts_remaining: 2 }
    };
    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "otp_invalid");
    assertEquals(body.attempts_remaining, 2);
    restoreFetchMock();
    cleanEnv();
  }
});

// 10. Sucesso total de alteração e consolidação
Deno.test({
  name: "Confirm OTP - Cenário 10: Sucesso total de alteração e consolidação",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();

    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.status, "success");
    assertEquals(body.protocol_number, "AC-20260619-9999");

    // Verificar se o update no Auth foi chamado corretamente
    const updateAuthReq = lastFetchRequests.find(r => r.url.includes("/auth/v1/admin/users/98765432-1111-2222-3333-abcdefabcdef"));
    assertExists(updateAuthReq);
    assertEquals(updateAuthReq.body.email, "new@example.test");

    // Verificar se a consolidação de sucesso foi chamada
    const successConsolidateReq = lastFetchRequests.find(r => r.url.includes("conectea_consolidate_email_change_success_v1"));
    assertExists(successConsolidateReq);
    assertEquals(successConsolidateReq.body.p_new_email_clear, "new@example.test");

    restoreFetchMock();
    cleanEnv();
  }
});

// 11. Erro de descriptografia consolida falha com decrypt_failed
Deno.test({
  name: "Confirm OTP - Cenário 11: Erro de descriptografia consolida falha com decrypt_failed",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();

    // Mock confirm response com nonce/tag corrompidos para falhar descriptografia
    mockConfirmResponse = {
      status: 200,
      body: {
        result: "otp_valid",
        request_id: "request-uuid-123",
        protocol_number: "AC-20260619-9999",
        destination_ciphertext: "ciphertext-invalido",
        destination_nonce: "nonce-invalido-tamanho-errado-123",
        destination_auth_tag: "tag-invalida-tamanho-errado-123",
        destination_encryption_key_version: 1
      }
    };

    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456" })
    });
    const res = await handler(req);
    assertEquals(res.status, 500);
    const body = await res.json();
    assertEquals(body.error, "internal_error");

    // Verificar se a consolidação de falha foi chamada
    const failureConsolidateReq = lastFetchRequests.find(r => r.url.includes("conectea_consolidate_email_change_failure_v1"));
    assertExists(failureConsolidateReq);
    assertEquals(failureConsolidateReq.body.p_failure_code, "decrypt_failed");

    restoreFetchMock();
    cleanEnv();
  }
});

// 12. Erro no Supabase Auth consolida falha com auth_update_failed sanitizado
Deno.test({
  name: "Confirm OTP - Cenário 12: Erro no Supabase Auth consolida falha com auth_update_failed sanitizado",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    setupEnv();
    setupFetchMock();
    resetMocks();

    // Mock de erro de email duplicado ou falha técnica no Auth contendo mensagem sensível
    mockUpdateUserResponse = {
      status: 400,
      body: { message: "Email already exists" }
    };

    const req = new Request("https://localhost/confirm-email-change-otp", {
      method: "POST",
      headers: { "Authorization": mockAuthHeader },
      body: JSON.stringify({ otp: "123456" })
    });
    const res = await handler(req);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.error, "auth_update_failed");

    // Verificar se a consolidação de falha foi chamada com reason sanitizado
    const failureConsolidateReq = lastFetchRequests.find(r => r.url.includes("conectea_consolidate_email_change_failure_v1"));
    assertExists(failureConsolidateReq);
    assertEquals(failureConsolidateReq.body.p_failure_code, "auth_update_failed");
    assertEquals(failureConsolidateReq.body.p_failure_reason, "Erro de atualizacao cadastral no Supabase Auth");

    // Garantir que a mensagem original de erro bruto do Auth NÃO foi enviada na RPC
    const containsRawError = JSON.stringify(failureConsolidateReq.body).includes("Email already exists");
    assertEquals(containsRawError, false);

    restoreFetchMock();
    cleanEnv();
  }
});
