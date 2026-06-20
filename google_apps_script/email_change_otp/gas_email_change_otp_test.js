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

globalThis.MailApp = {
  getRemainingDailyQuota: () => 100,
  sendEmail: (data) => {
    if (typeof globalThis.fakeSendEmail === 'function') {
      globalThis.fakeSendEmail(data);
    }
  }
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

  newBlob: (data) => {
    return {
      getBytes: () => {
        if (typeof data === "string") {
          return new Int8Array(Buffer.from(data, "utf8"));
        }
        return new Int8Array(data);
      }
    };
  },

  computeHmacSignature: (algorithm, valueBytes, keyBytes) => {
    const keyBuf = Buffer.from(keyBytes);
    const valueBuf = Buffer.from(valueBytes);
    const hmac = crypto.createHmac("sha256", keyBuf);
    hmac.update(valueBuf);
    const buf = hmac.digest();
    return new Int8Array(buf);
  },

  computeHmacSha256Signature: (value, keyBytes) => {
    const keyBuf = Buffer.from(keyBytes);
    const valueBuf = typeof value === "string" ? Buffer.from(value, "utf8") : Buffer.from(value);
    const hmac = crypto.createHmac("sha256", keyBuf);
    hmac.update(valueBuf);
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

Deno.test("GAS - Teste 19: doGet e doPost em modo diagnóstico seguro retornam o handler correto", () => {
  setupEnv();
  // Teste doGet diagnóstico
  const eventGet = { parameter: { diagnostic: "true" } };
  const resGet = doGet(eventGet);
  const resGetObj = JSON.parse(resGet.content);
  assertEquals(resGetObj.status, "invalid_request");
  assertEquals(resGetObj.handler, "doGet");

  // Teste doPost diagnóstico vazio
  const eventPost = { parameter: { diagnostic: "true" }, postData: null };
  const resPost = doPost(eventPost);
  const resPostObj = JSON.parse(resPost.content);
  assertEquals(resPostObj.status, "invalid_request");
  assertEquals(resPostObj.handler, "doPost");
});

Deno.test("GAS - Teste 20: dry_run assinado não envia e-mail e retorna status e quota restante", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_20",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "dry_run_validated");
  assertEquals(resObj.quota_remaining, 100);
  assertEquals(lastSentEmail, null); // MailApp não foi chamado
});

Deno.test("GAS - Teste 21: dry_run sem assinatura válida é rejeitado", () => {
  setupEnv();
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_21",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true
  };
  const env = makeEnvelope({ payload });
  env.meta.signature = "assinatura_invalida";
  const event = { postData: { contents: JSON.stringify(env) } };

  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
  assertEquals(resObj.quota_remaining, undefined);
});

Deno.test("GAS - Teste 22: logs do GAS em falha de HMAC não contêm assinatura calculada ou recebida", () => {
  setupEnv();
  setupConsoleInterceptor();
  try {
    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_22",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654"
    };
    const env = makeEnvelope({ payload });
    env.meta.signature = "f8a7e6d5c4b3a291"; // assinatura incorreta
    const event = { postData: { contents: JSON.stringify(env) } };

    doPost(event);

    // Validar que nenhum log contém a assinatura enviada ("f8a7e6d5c4b3a291") ou dados internos
    for (const logLine of interceptedLogs) {
      assertEquals(logLine.includes("f8a7e6d5c4b3a291"), false);
      assertEquals(logLine.includes("calculado="), false);
      assertEquals(logLine.includes("recebido="), false);
    }
  } finally {
    restoreConsole();
  }
});

Deno.test("GAS - Teste 23: logs do GAS em falha de KID ou body hash não expõem KID ou body hash esperado/recebido", () => {
  setupEnv();
  setupConsoleInterceptor();
  try {
    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_23",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654"
    };
    const env = makeEnvelope({ payload, kid: "kid_incorreto_sintetico" });
    const event = { postData: { contents: JSON.stringify(env) } };

    doPost(event);

    // Validar que nenhum log contém o kid incorreto ("kid_incorreto_sintetico") nem hashes esperados
    for (const logLine of interceptedLogs) {
      assertEquals(logLine.includes("kid_incorreto_sintetico"), false);
      assertEquals(logLine.includes("esperado="), false);
      assertEquals(logLine.includes("recebido="), false);
    }
  } finally {
    restoreConsole();
  }
});

Deno.test("GAS - Teste 24: catch externo de doPost preserva correlation_id extraído e não retorna unknown", () => {
  setupEnv();
  const originalGetProperties = globalThis.PropertiesService.getScriptProperties;
  try {
    // Forçar erro na obtenção de propriedades para simular falha geral após extração do correlation_id
    globalThis.PropertiesService.getScriptProperties = () => {
      throw new Error("Erro simulado no properties service");
    };

    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_24",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654"
    };
    const env = makeEnvelope({ payload, corrId: "corr_teste_24" });
    const event = { postData: { contents: JSON.stringify(env) } };

    const res = doPost(event);
    const resObj = JSON.parse(res.content);

    assertEquals(resObj.status, "temporary_failure");
    assertEquals(resObj.correlation_id, "corr_teste_24"); // correlation_id preservado!
  } finally {
    globalThis.PropertiesService.getScriptProperties = originalGetProperties;
  }
});

Deno.test("GAS - Teste 25: logs do catch geral não vazam chaves ou dados confidenciais", () => {
  setupEnv();
  setupConsoleInterceptor();
  const originalGetProperties = globalThis.PropertiesService.getScriptProperties;
  try {
    globalThis.PropertiesService.getScriptProperties = () => {
      throw new Error("Erro simulado no properties service");
    };

    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_25",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654"
    };
    const env = makeEnvelope({ payload, corrId: "corr_teste_25" });
    const event = { postData: { contents: JSON.stringify(env) } };

    doPost(event);

    // Validar que os logs de erro geral não contêm dados criptográficos brutas reais
    for (const logLine of interceptedLogs) {
      if (logLine.includes("Categoria: execution_general_failure")) {
        assertEquals(logLine.includes("Error"), true);
        assertEquals(logLine.includes(env.meta.signature), false);
        assertEquals(logLine.includes(env.meta.payload_sha256), false);
        assertEquals(logLine.includes(testSigningKeyBase64Url), false);
        assertEquals(logLine.includes(payload.recipient_email), false);
      }
    }
  } finally {
    globalThis.PropertiesService.getScriptProperties = originalGetProperties;
    restoreConsole();
  }
});

Deno.test("GAS - Teste 26: failure_stage exposto apenas após validação do HMAC", () => {
  setupEnv();

  // 1. Cenário de erro ANTES do HMAC (ex: erro ao ler propriedades)
  const originalGetProperties = globalThis.PropertiesService.getScriptProperties;
  try {
    globalThis.PropertiesService.getScriptProperties = () => {
      throw new Error("Erro simulado antes do HMAC");
    };

    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_26_1",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654"
    };
    const env = makeEnvelope({ payload, corrId: "corr_teste_26_1" });
    const event = { postData: { contents: JSON.stringify(env) } };

    const res = doPost(event);
    const resObj = JSON.parse(res.content);

    assertEquals(resObj.status, "temporary_failure");
    assertEquals(resObj.correlation_id, "corr_teste_26_1");
    assertEquals(resObj.failure_stage, undefined); // Oculto antes da validação do HMAC
  } finally {
    globalThis.PropertiesService.getScriptProperties = originalGetProperties;
  }

  // 2. Cenário de erro APÓS o HMAC (ex: erro no MailApp ao processar dry_run assinado válido)
  const originalQuota = globalThis.MailApp.getRemainingDailyQuota;
  try {
    globalThis.MailApp.getRemainingDailyQuota = () => {
      throw new Error("Erro simulado no MailApp");
    };

    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_26_2",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654",
      dry_run: true
    };
    const env = makeEnvelope({ payload, corrId: "corr_teste_26_2" });
    const event = { postData: { contents: JSON.stringify(env) } };

    const res = doPost(event);
    const resObj = JSON.parse(res.content);

    assertEquals(resObj.status, "temporary_failure");
    assertEquals(resObj.correlation_id, "corr_teste_26_2");
    assertEquals(resObj.failure_stage, "dry_run_quota_check"); // Exposto após a validação do HMAC!
  } finally {
    globalThis.MailApp.getRemainingDailyQuota = originalQuota;
  }
});

Deno.test("GAS - Teste 27: debug desativado por padrão quando CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED não é 'true'", () => {
  setupEnv();
  // mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = undefined
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_27",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  // Deve retornar o comportamento de dry_run normal (sem campos de debug detalhados)
  assertEquals(resObj.status, "dry_run_validated");
  assertEquals(resObj.debug, undefined);
  assertEquals(resObj.timestamp_present, undefined);
});

Deno.test("GAS - Teste 28: debug não aparece se payload.debug_diagnostics não for true", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_28",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true,
    debug_diagnostics: false
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "dry_run_validated");
  assertEquals(resObj.debug, undefined);
});

Deno.test("GAS - Teste 29: debug não aparece se dry_run não for true", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_29",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: false,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "sent"); // Envio real de OTP bem sucedido
  assertEquals(resObj.debug, undefined);
});

Deno.test("GAS - Teste 30: debug não aparece antes de HMAC válido", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_30",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  env.meta.signature = "assinatura_errada";
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "invalid_signature");
  assertEquals(resObj.debug, undefined);
});

Deno.test("GAS - Teste 31: debug aparece após HMAC válido, dry_run true, debug_diagnostics true e Script Property ativa", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_31",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);
  assertEquals(resObj.status, "dry_run_validated");
  assertEquals(resObj.debug, true);
  assertEquals(resObj.timestamp_present, true);
  assertEquals(resObj.timestamp_valid, true);
  assertEquals(resObj.kid_present, true);
  assertEquals(resObj.kid_matches, true);
  assertEquals(resObj.key_present, true);
  assertEquals(resObj.key_length_ok, true);
  assertEquals(resObj.key_base64url_shape_ok, true);
  assertEquals(resObj.key_decode_ok, true);
  assertEquals(resObj.payload_hash_matches, true);
  assertEquals(resObj.signature_matches, true);
  assertEquals(resObj.required_fields_ok, true);
  assertEquals(resObj.email_shape_ok, true);
  assertEquals(resObj.quota_check_reached, true);
  assertEquals(resObj.quota_check_ok, true);
});

Deno.test("GAS - Teste 32: resposta debug contém apenas booleans/enums permitidos e não expõe confidenciais", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_32",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);

  const allowedKeys = [
    "status",
    "correlation_id",
    "debug",
    "safe_stage",
    "timestamp_present",
    "timestamp_valid",
    "kid_present",
    "kid_matches",
    "key_present",
    "key_length_ok",
    "key_base64url_shape_ok",
    "key_decode_ok",
    "payload_hash_matches",
    "signature_matches",
    "required_fields_ok",
    "email_shape_ok",
    "quota_check_reached",
    "quota_check_ok"
  ].sort();

  const returnedKeys = Object.keys(resObj).sort();
  assertEquals(returnedKeys, allowedKeys);

  // Certificar de que dados confidenciais não estão expostos
  assertEquals(resObj.signing_key, undefined);
  assertEquals(resObj.signature, undefined);
  assertEquals(resObj.hash, undefined);
  assertEquals(resObj.payload, undefined);
  assertEquals(resObj.envelope, undefined);
  assertEquals(resObj.email, undefined);
  assertEquals(resObj.otp, undefined);
  assertEquals(resObj.subject, undefined);
  assertEquals(resObj.body, undefined);
  assertEquals(resObj.kid, undefined);
});

Deno.test("GAS - Teste 33: logs de dry_run debug não vazam chaves ou dados confidenciais", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  setupConsoleInterceptor();
  try {
    const payload = {
      purpose: "email_change",
      idempotency_key: "idemp_test_33",
      send_sequence: 1,
      recipient_email: "destinatario-sintetico@conectea.org",
      subject: "Assunto",
      body_text: "Código: 987654",
      dry_run: true,
      debug_diagnostics: true
    };
    const env = makeEnvelope({ payload });
    const event = { postData: { contents: JSON.stringify(env) } };
    doPost(event);

    // Verificar que nenhum log contém informações sensíveis do payload ou chaves
    assertNoSensitivesInLogs();
    for (const logLine of interceptedLogs) {
      assertEquals(logLine.includes(testSigningKeyBase64Url), false);
      assertEquals(logLine.includes(env.meta.signature), false);
      assertEquals(logLine.includes("987654"), false);
    }
  } finally {
    restoreConsole();
  }
});

Deno.test("GAS - Teste 34: dry_run debug não chama MailApp.sendEmail nem grava tombstone", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_34",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: true,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  doPost(event);

  assertEquals(lastSentEmail, null); // MailApp.sendEmail não chamado

  // Tombstone não deve ter sido gravado
  const stateKey = 'tombstone:email_change:idemp_test_34';
  assertEquals(mockProperties[stateKey], undefined);
});

Deno.test("GAS - Teste 35: fluxo normal sem debug continua igual", () => {
  setupEnv();
  // Sem habilitar debug na Script Property, envio normal de OTP
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_35",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    dry_run: false
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);

  assertEquals(resObj.status, "sent");
  assertExists(lastSentEmail);

  // Tombstone gravado como sent
  const stateKey = 'tombstone:email_change:idemp_test_35';
  assertEquals(mockProperties[stateKey], "sent");
});

Deno.test("GAS - Teste 36: payload com campos proibidos continua rejeitado", () => {
  setupEnv();
  mockProperties["CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED"] = "true";
  const payload = {
    purpose: "email_change",
    idempotency_key: "idemp_test_36",
    send_sequence: 1,
    recipient_email: "destinatario-sintetico@conectea.org",
    subject: "Assunto",
    body_text: "Código: 987654",
    user_id: "user-uuid-123", // Campo proibido
    dry_run: true,
    debug_diagnostics: true
  };
  const env = makeEnvelope({ payload });
  const event = { postData: { contents: JSON.stringify(env) } };
  const res = doPost(event);
  const resObj = JSON.parse(res.content);

  assertEquals(resObj.status, "invalid_request");
  assertEquals(resObj.debug, undefined); // Não deve retornar debug
});
