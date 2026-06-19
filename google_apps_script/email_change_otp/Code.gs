// ============================================================
// Google Apps Script — Email Change OTP Delivery
// Orquestração segura At-Most-Once e validação de assinatura
// ============================================================

/**
 * Ponto de entrada do Web App para requisições POST.
 */
function doPost(e) {
  var startTime = new Date().getTime();
  var correlationId = 'unknown';

  try {
    if (!e || !e.postData || !e.postData.contents) {
      return createResponse('invalid_request', 'unknown');
    }

    var rawBody = e.postData.contents;
    var envelope;
    try {
      envelope = JSON.parse(rawBody);
    } catch (parseErr) {
      return createResponse('invalid_request', 'unknown');
    }

    if (!envelope || typeof envelope !== 'object') {
      return createResponse('invalid_request', 'unknown');
    }

    var meta = envelope.meta;
    var payload = envelope.payload;

    if (!meta || !payload || typeof meta !== 'object' || typeof payload !== 'object') {
      return createResponse('invalid_request', 'unknown');
    }

    // Extração das informações de segurança do envelope JSON
    var sigVersion = meta.signature_version;
    var sigKid = meta.signature_kid;
    var sigTimestamp = meta.signature_timestamp;
    var payloadSha256 = meta.payload_sha256;
    var signature = meta.signature;
    var envelopeCorrId = meta.correlation_id;

    if (envelopeCorrId) {
      correlationId = envelopeCorrId;
    }

    // 1. Rejeição de chaves proibidas de identificação ou banco (critério de privacidade)
    var forbiddenKeys = ['user_id', 'auth_user_id', 'cycle_id', 'challenge_id'];
    for (var i = 0; i < forbiddenKeys.length; i++) {
      var key = forbiddenKeys[i];
      if (key in envelope || key in meta || key in payload) {
        logOperational(correlationId, 'validação_chaves_proibidas', 'rejeitado', startTime);
        return createResponse('invalid_request', correlationId);
      }
    }

    // 2. Validação básica de presença das chaves de segurança
    if (!sigVersion || !sigKid || !sigTimestamp || !payloadSha256 || !signature) {
      logOperational(correlationId, 'validação_headers', 'falha', startTime);
      return createResponse('invalid_signature', correlationId);
    }

    // 3. Validação do timestamp (janela de 5 minutos). Rejeita com invalid_signature por segurança.
    var now = new Date().getTime();
    var requestTime = new Date(sigTimestamp).getTime();
    if (isNaN(requestTime) || Math.abs(now - requestTime) > 5 * 60 * 1000) {
      logOperational(correlationId, 'validação_timestamp', 'falha', startTime);
      return createResponse('invalid_signature', correlationId);
    }

    // 4. Validação do KID
    var props = PropertiesService.getScriptProperties();
    var expectedKid = props.getProperty('CONECTEA_EDGE_GAS_SIGNING_KID');
    if (sigKid !== expectedKid) {
      logOperational(correlationId, 'validação_kid', 'falha', startTime);
      return createResponse('invalid_signature', correlationId);
    }

    // 5. Validar SHA-256 do payload canonicalizado
    var computedPayloadSha256 = computeSha256Hex(canonicalizeObject(payload));
    if (payloadSha256 !== computedPayloadSha256) {
      logOperational(correlationId, 'validação_body_hash', 'falha', startTime);
      return createResponse('invalid_signature', correlationId);
    }

    // 6. Validar Assinatura HMAC-SHA256
    var signingKeyBase64Url = props.getProperty('CONECTEA_EDGE_GAS_SIGNING_KEY');
    if (!signingKeyBase64Url) {
      logOperational(correlationId, 'carregamento_chave', 'falha', startTime);
      return createResponse('temporary_failure', correlationId);
    }

    var keyBytes;
    try {
      keyBytes = decodeBase64UrlStrict(signingKeyBase64Url);
    } catch (keyErr) {
      logOperational(correlationId, 'decodificação_chave', 'falha', startTime);
      return createResponse('temporary_failure', correlationId);
    }

    var baseString = 'POST\n' + 'email-change/send-otp/v1\n' + sigVersion + '\n' + sigKid + '\n' + sigTimestamp + '\n' + payloadSha256;
    var computedSignature = computeHmacSha256Hex(baseString, keyBytes);

    if (!safeCompare(signature, computedSignature)) {
      logOperational(correlationId, 'validação_hmac', 'falha', startTime);
      return createResponse('invalid_signature', correlationId);
    }

    // 7. Validação de campos obrigatórios do contrato do payload
    if (!payload.purpose || !payload.idempotency_key || !payload.recipient_email || !payload.subject || (!payload.body_text && !payload.body_html)) {
      logOperational(correlationId, 'validação_payload_obrigatorio', 'falha', startTime);
      return createResponse('invalid_request', correlationId);
    }

    // 8. Validação pré-envio de e-mail (sintaxe mínima)
    var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(payload.recipient_email)) {
      logOperational(correlationId, 'validação_destinatário', 'inválido', startTime);
      return createResponse('failed_pre_send_invalid_destination', correlationId);
    }

    // 9. Processamento de Idempotência At-Most-Once com Locks
    var lock = LockService.getScriptLock();
    try {
      lock.waitLock(10000); // 10 segundos
    } catch (lockErr) {
      logOperational(correlationId, 'aquisição_lock', 'timeout', startTime);
      return createResponse('temporary_failure', correlationId);
    }

    try {
      var stateKey = 'tombstone:' + payload.purpose + ':' + payload.idempotency_key;
      var existingState = props.getProperty(stateKey);

      if (existingState === 'sent') {
        lock.releaseLock();
        logOperational(correlationId, 'processamento_idempotencia', 'already_sent', startTime);
        return createResponse('already_sent', correlationId);
      }
      if (existingState === 'attempt_reserved') {
        lock.releaseLock();
        logOperational(correlationId, 'processamento_idempotencia', 'attempt_reserved', startTime);
        return createResponse('attempt_reserved', correlationId);
      }
      if (existingState === 'ambiguous_attempted') {
        lock.releaseLock();
        logOperational(correlationId, 'processamento_idempotencia', 'ambiguous_attempted', startTime);
        return createResponse('ambiguous_attempted', correlationId);
      }

      // Reservar tentativa antes do envio
      props.setProperty(stateKey, 'attempt_reserved');
      lock.releaseLock(); // Libera o lock antes de enviar o e-mail

      // 10. Envio de e-mail (mockado nos testes)
      try {
        sendEmailInternal(payload);
        
        // Gravar sucesso
        props.setProperty(stateKey, 'sent');
        logOperational(correlationId, 'envio_email', 'sent', startTime);
        return createResponse('sent', correlationId);
      } catch (sendErr) {
        // Gravar estado de ambiguidade em caso de erro pós-reserva
        props.setProperty(stateKey, 'ambiguous_attempted');
        logOperational(correlationId, 'envio_email', 'ambiguous_attempted', startTime);
        return createResponse('ambiguous_attempted', correlationId);
      }

    } catch (processErr) {
      if (lock.hasLock()) {
        lock.releaseLock();
      }
      logOperational(correlationId, 'processamento_interno', 'erro', startTime);
      return createResponse('temporary_failure', correlationId);
    }

  } catch (err) {
    logOperational(correlationId, 'execução_geral', 'erro', startTime);
    return createResponse('temporary_failure', 'unknown');
  }
}

/**
 * Ponto de entrada do Web App para requisições GET.
 */
function doGet(e) {
  return createResponse('invalid_request', 'unknown');
}

// --- UTILS E HELPERS INTERNOS ---

function canonicalizeObject(obj) {
  if (obj === null || typeof obj !== 'object') {
    return JSON.stringify(obj);
  }
  if (Array.isArray(obj)) {
    var parts = [];
    for (var i = 0; i < obj.length; i++) {
      parts.push(canonicalizeObject(obj[i]));
    }
    return '[' + parts.join(',') + ']';
  }
  var keys = Object.keys(obj).sort();
  var parts = [];
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    var val = obj[key];
    parts.push(JSON.stringify(key) + ':' + canonicalizeObject(val));
  }
  return '{' + parts.join(',') + '}';
}

function createResponse(statusValue, correlationId) {
  var responsePayload = {
    status: statusValue,
    correlation_id: correlationId || 'unknown'
  };
  return ContentService.createTextOutput(JSON.stringify(responsePayload))
    .setMimeType(ContentService.MimeType.JSON);
}

function decodeBase64UrlStrict(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]+$/.test(value)) {
    throw new Error('invalid_base64url');
  }
  var base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) {
    base64 += '=';
  }
  try {
    return Utilities.base64Decode(base64);
  } catch (err) {
    throw new Error('invalid_base64url');
  }
}

function computeSha256Hex(text) {
  var digest = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, text, Utilities.Charset.UTF_8);
  return bytesToHex(digest);
}

function computeHmacSha256Hex(value, keyBytes) {
  var hmac = Utilities.computeHmacSignature(Utilities.MacAlgorithm.HMAC_SHA_256, value, keyBytes);
  return bytesToHex(hmac);
}

function bytesToHex(bytes) {
  var hex = '';
  for (var i = 0; i < bytes.length; i++) {
    var b = bytes[i];
    if (b < 0) b += 256;
    var byteString = b.toString(16);
    if (byteString.length == 1) byteString = '0' + byteString;
    hex += byteString;
  }
  return hex;
}

function safeCompare(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) {
    return false;
  }
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

function sendEmailInternal(payload) {
  if (typeof fakeSendEmail === 'function') {
    fakeSendEmail(payload);
  } else {
    MailApp.sendEmail({
      to: payload.recipient_email,
      subject: payload.subject,
      body: payload.body_text || '',
      htmlBody: payload.body_html || undefined
    });
  }
}

function logOperational(correlationId, etapa, status, startTime) {
  var duration = new Date().getTime() - startTime;
  console.log('[Correlation ID: ' + correlationId + '] Etapa: ' + etapa + ' | Status: ' + status + ' | Duração: ' + duration + 'ms');
}
