import { assertEquals, assertNotEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import crypto from "node:crypto";
import { Buffer } from "node:buffer";

globalThis.Buffer = Buffer;

// --- MOCK DO AMBIENTE GOOGLE APPS SCRIPT ---

const mockProperties = {};
globalThis.PropertiesService = {
  getScriptProperties: () => ({
    getProperty: (key) => mockProperties[key] || null,
    setProperty: (key, value) => { mockProperties[key] = String(value); },
    deleteProperty: (key) => { delete mockProperties[key]; }
  })
};

let isLocked = false;
globalThis.LockService = {
  getScriptLock: () => ({
    waitLock: (timeout) => {
      if (isLocked) throw new Error("Lock timeout");
      isLocked = true;
    },
    releaseLock: () => { isLocked = false; },
    hasLock: () => isLocked
  })
};

globalThis.ContentService = {
  MimeType: { JSON: "application/json" },
  createTextOutput: (content) => {
    const output = {
      content: content,
      mimeType: "",
      setMimeType: (mime) => {
        output.mimeType = mime;
        return output;
      }
    };
    return output;
  }
};

globalThis.Utilities = {
  Charset: { UTF_8: "UTF-8" },
  DigestAlgorithm: { SHA_256: "SHA-256" },
  MacAlgorithm: { HMAC_SHA_256: "HMAC-SHA-256" },

  base64Decode: (encoded) => {
    let base64 = encoded.replace(/-/g, "+").replace(/_/g, "/");
    while (base64.length % 4) base64 += "=";
    const buf = Buffer.from(base64, "base64");
    return new Int8Array(buf);
  },

  base64Encode: (bytes) => {
    const buf = Buffer.from(bytes);
    return buf.toString("base64");
  },

  computeDigest: (algorithm, value) => {
    const hash = crypto.createHash("sha256");
    hash.update(value, "utf8");
    const buf = hash.digest();
    return new Int8Array(buf);
  },

  computeHmacSignature: (algorithm, value, keyBytes) => {
    const keyBuf = Buffer.from(keyBytes);
    const hmac = crypto.createHmac("sha256", keyBuf);
    hmac.update(value, "utf8");
    const buf = hmac.digest();
    return new Int8Array(buf);
  }
};

// --- AVALIAÇÃO DO CÓDIGO FONTE DO GAS ---

const codeUrl = new URL("./Code.gs", import.meta.url);
const codeGs = await Deno.readTextFile(codeUrl);
eval(codeGs + "\n; globalThis.doPost = doPost; globalThis.doGet = doGet; globalThis.canonicalizeObject = canonicalizeObject;");

// --- HELPERS DE TESTE ---

function encodeBase64Url(bytes) {
  let binString = "";
  for (let i = 0; i < bytes.length; i++) {
    binString += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binString);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

const testSigningKeyBytes = new Uint8Array(32);
for (let i = 0; i < 32; i++) testSigningKeyBytes[i] = i + 5;
const testSigningKeyBase64Url = encodeBase64Url(testSigningKeyBytes);

const testKid = "kid_gas_test_v1";

function makeEnvelope({
  payload,
  keyBytes = testSigningKeyBytes,
  kid = testKid,
  version = "1",
  timestamp = new Date().toISOString(),
  corrId = "corr_teste_v1",
  path = "email-change/send-otp/v1",
  method = "POST"
}) {
  const canonicalPayload = globalThis.canonicalizeObject(payload);
  const payloadSha256 = crypto.createHash("sha256").update(canonicalPayload, "utf8").digest("hex");
  const baseString = `${method}\n${path}\n${version}\n${kid}\n${timestamp}\n${payloadSha256}`;
  const hmac = crypto.createHmac("sha256", Buffer.from(keyBytes));
  hmac.update(baseString, "utf8");
  const signature = hmac.digest("hex");

  return {
    meta: {
      signature_version: version,
      signature_kid: kid,
      signature_timestamp: timestamp,
      logical_path: path,
      payload_sha256: payloadSha256,
      signature: signature,
      correlation_id: corrId
    },
    payload: payload
  };
}

let lastSentEmail = null;
globalThis.fakeSendEmail = (data) => {
  lastSentEmail = data;
};

let interceptedLogs = [];
const originalLog = console.log;

function setupConsoleInterceptor() {
  interceptedLogs = [];
  console.log = (...args) => {
    interceptedLogs.push(args.join(" "));
  };
}

function restoreConsole() {
  console.log = originalLog;
}

function assertNoSensitivesInLogs() {
  const sensitiveRegexes = [
    /destinatario-sintetico@conectea\.org/i,
    /987654/,
    /key/i,
    /secret/i,
    /signature/i,
    /payload/i,
    /tombstone/i,
    /user-uuid-123/i,
    /cycle-uuid-456/i,
  ];

  for (const logLine of interceptedLogs) {
    for (const regex of sensitiveRegexes) {
      if (regex.test(logLine)) {
        throw new Error(`Dado sensível exposto nos logs do GAS: ${logLine}`);
      }
    }
  }
}

function setupEnv() {
  mockProperties["CONECTEA_EDGE_GAS_SIGNING_KEY"] = testSigningKeyBase64Url;
  mockProperties["CONECTEA_EDGE_GAS_SIGNING_KID"] = testKid;
  isLocked = false;
  lastSentEmail = null;
  interceptedLogs = [];
  // Limpa tombstones
  for (const k in mockProperties) {
    if (k.startsWith("tombstone:")) {
      delete mockProperties[k];
    }
  }
}

// --- SUÍTE DE 18 TESTES OBRIGATÓRIOS ---

Deno.test("GAS - Teste 1: assinatura dentro do envelope é aceita", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_1",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código de alteração: 987654",
    correlation_id: "corr_teste_1"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "sent");
  assertExists(lastSentEmail);
});

Deno.test("GAS - Teste 2: query string com assinatura/metadados não é usada", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_2",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });

  const event = {
    parameter: {
      signature: env.meta.signature,
      signature_kid: env.meta.signature_kid,
      signature_timestamp: env.meta.signature_timestamp
    },
    postData: null
  };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_request");
});

Deno.test("GAS - Teste 3: assinatura inválida retorna invalid_signature", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_3",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  env.meta.signature = "assinatura_corrompida_123";
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
});

Deno.test("GAS - Teste 4: timestamp vencido rejeita", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_4",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const oldTimestamp = new Date(Date.now() - 10 * 60 * 1000).toISOString();
  const env = makeEnvelope({ payload, timestamp: oldTimestamp });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
});

Deno.test("GAS - Teste 5: kid inesperado rejeita", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_5",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload, kid: "kid_errado" });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
});

Deno.test("GAS - Teste 6: payload_sha256 divergente rejeita", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_6",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  env.meta.payload_sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
});

Deno.test("GAS - Teste 7: payload malformado retorna invalid_request", () => {
  setupEnv();
  const event = { postData: { contents: "{ malformed_json: true " } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_request");
});

Deno.test("GAS - Teste 8: payload com campo proibido retorna invalid_request", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_8",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    user_id: "user-uuid-123"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_request");
});

Deno.test("GAS - Teste 9: recipient_email inválido retorna failed_pre_send_invalid_destination antes de attempt_reserved", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_9",
    send_sequence: 1,
    recipient_email: "email-invalido-sem-arroba",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "failed_pre_send_invalid_destination");

  const stateKey = 'tombstone:email_change:idemp_test_9';
  assertEquals(mockProperties[stateKey], undefined);
});

Deno.test("GAS - Teste 10: primeira chamada válida retorna sent", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_10",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "sent");
});

Deno.test("GAS - Teste 11: replay depois de sent retorna already_sent", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_11",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  let res = doPost(event);
  let resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "sent");
  assertExists(lastSentEmail);

  lastSentEmail = null;

  res = doPost(event);
  resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "already_sent");
  assertEquals(lastSentEmail, null);
});

Deno.test("GAS - Teste 12: attempt_reserved retorna sem reenviar", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_12",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const stateKey = 'tombstone:email_change:idemp_test_12';
  mockProperties[stateKey] = 'attempt_reserved';

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "attempt_reserved");
  assertEquals(lastSentEmail, null);
});

Deno.test("GAS - Teste 13: erro pós-reserva grava ambiguous_attempted", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_13",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  globalThis.fakeSendEmail = () => {
    throw new Error("Erro de infra simulado");
  };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "ambiguous_attempted");

  const stateKey = 'tombstone:email_change:idemp_test_13';
  assertEquals(mockProperties[stateKey], "ambiguous_attempted");
});

Deno.test("GAS - Teste 14: replay depois de ambiguous_attempted retorna ambiguous_attempted", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_14",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  globalThis.fakeSendEmail = () => {
    throw new Error("Erro de infra simulado");
  };

  let res = doPost(event);
  let resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "ambiguous_attempted");

  globalThis.fakeSendEmail = (data) => {
    lastSentEmail = data;
  };

  res = doPost(event);
  resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "ambiguous_attempted");
  assertEquals(lastSentEmail, null);
});

Deno.test("GAS - Teste 15: alteração de payload quebra assinatura", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_15",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto Original",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });

  env.payload.subject = "Assunto Alterado";

  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
});

Deno.test("GAS - Teste 16: reordenação de chaves do payload não quebra assinatura se a canonicalização for correta", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_16",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });

  const reorderedPayloadStr = '{"subject":"Assunto","purpose":"email_change","idempotency_key":"idemp_test_16","recipient_email":"destinatario-sintetico@conectea.org","send_sequence":1,"body_text":"Código: 987654"}';

  const envStr = JSON.stringify({
    meta: env.meta,
    payload: JSON.parse(reorderedPayloadStr)
  });

  const event = { postData: { contents: envStr } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "sent");
});

Deno.test("GAS - Teste 17: retorno não contém e-mail, OTP, assinatura, idempotency_key, raw body ou payload completo", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_17",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654"
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);

  const returnedKeys = Object.keys(resObj).sort();
  assertEquals(returnedKeys, ["correlation_id", "status"]);

  assertEquals(resObj.recipient_email, undefined);
  assertEquals(resObj.body_text, undefined);
  assertEquals(resObj.body_html, undefined);
  assertEquals(resObj.signature, undefined);
  assertEquals(resObj.idempotency_key, undefined);
  assertEquals(resObj.payload, undefined);
});

Deno.test("GAS - Teste 18: logs não expõem dados sensíveis", () => {
  setupEnv();
  setupConsoleInterceptor();
  try {
    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_18",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto de Teste",
      body_text: "Código de alteração: 987654"
    };
    const env = makeEnvelope({ payload });
    const event = { postData: { contents: JSON.stringify(env) } };

    doPost(event);

    assertNoSensitivesInLogs();
  } finally {
    restoreConsole();
  }
});
