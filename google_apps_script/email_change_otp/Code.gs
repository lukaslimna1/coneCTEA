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
  var isDiag = e && e.parameter && e.parameter.diagnostic === 'true';
  var safeStage = 'received';
  var isHmacValidated = false;

  var diagnostics = {
    debug: true,
    safe_stage: 'received',
    timestamp_present: false,
    timestamp_valid: false,
    kid_present: false,
    kid_matches: false,
    key_present: false,
    key_length_ok: false,
    key_base64url_shape_ok: false,
    key_decode_ok: false,
    payload_hash_matches: false,
    signature_matches: false,
    required_fields_ok: false,
    email_shape_ok: false,
    quota_check_reached: false,
    quota_check_ok: false
  };

  var props = null;
  var payload = null;

  function buildResult(statusValue, defaultResponse) {
    diagnostics.status = statusValue;
    diagnostics.correlation_id = correlationId;
    diagnostics.safe_stage = safeStage;

    var debugEnabledProp = props ? props.getProperty('CONECTEA_GAS_DRY_RUN_DEBUG_ENABLED') : null;
    var showDebug = (
      debugEnabledProp === 'true' &&
      payload &&
      payload.dry_run === true &&
      payload.debug_diagnostics === true &&
      diagnostics.signature_matches === true
    );

    if (showDebug) {
      var debugResponsePayload = {
        status: diagnostics.status,
        correlation_id: diagnostics.correlation_id,
        debug: true,
        safe_stage: diagnostics.safe_stage,
        timestamp_present: diagnostics.timestamp_present,
        timestamp_valid: diagnostics.timestamp_valid,
        kid_present: diagnostics.kid_present,
        kid_matches: diagnostics.kid_matches,
        key_present: diagnostics.key_present,
        key_length_ok: diagnostics.key_length_ok,
        key_base64url_shape_ok: diagnostics.key_base64url_shape_ok,
        key_decode_ok: diagnostics.key_decode_ok,
        payload_hash_matches: diagnostics.payload_hash_matches,
        signature_matches: diagnostics.signature_matches,
        required_fields_ok: diagnostics.required_fields_ok,
        email_shape_ok: diagnostics.email_shape_ok,
        quota_check_reached: diagnostics.quota_check_reached,
        quota_check_ok: diagnostics.quota_check_ok
      };
      return ContentService.createTextOutput(JSON.stringify(debugResponsePayload))
        .setMimeType(ContentService.MimeType.JSON);
    }
    return defaultResponse;
  }

  try {
    if (!e || !e.postData || !e.postData.contents) {
      console.log('[doPost] Entrada rejeitada: ausência de postData.');
      return createResponse('invalid_request', 'unknown', isDiag ? 'doPost' : undefined);
    }

    var rawBody = e.postData.contents;
    var envelope;
    try {
      envelope = JSON.parse(rawBody);
      safeStage = 'parsed_json';
    } catch (parseErr) {
      console.log('[doPost] Entrada rejeitada: falha de parse JSON.');
      return createResponse('invalid_request', 'unknown', isDiag ? 'doPost' : undefined);
    }

    if (!envelope || typeof envelope !== 'object') {
      console.log('[doPost] Entrada rejeitada: envelope malformado.');
      return createResponse('invalid_request', 'unknown', isDiag ? 'doPost' : undefined);
    }

    var meta = envelope.meta;
    payload = envelope.payload;

    if (!meta || !payload || typeof meta !== 'object' || typeof payload !== 'object') {
      console.log('[doPost] Entrada rejeitada: campos meta ou payload ausentes.');
      return createResponse('invalid_request', 'unknown', isDiag ? 'doPost' : undefined);
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

    console.log('[doPost] [Correlation ID: ' + correlationId + '] Entrada processada com sucesso.');

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
    diagnostics.timestamp_present = (sigTimestamp !== undefined && sigTimestamp !== null && sigTimestamp !== '');
    diagnostics.kid_present = (sigKid !== undefined && sigKid !== null && sigKid !== '');

    if (!sigVersion || !sigKid || !sigTimestamp || !payloadSha256 || !signature) {
      logOperational(correlationId, 'validação_headers', 'falha', startTime);
      return buildResult('invalid_signature', createResponse('invalid_signature', correlationId));
    }
    safeStage = 'meta_validated';

    // 3. Validação do timestamp (janela de 5 minutos). Rejeita com invalid_signature por segurança.
    var now = new Date().getTime();
    var requestTime = new Date(sigTimestamp).getTime();
    var timeValid = (!isNaN(requestTime) && Math.abs(now - requestTime) <= 5 * 60 * 1000);
    diagnostics.timestamp_valid = timeValid;

    if (!timeValid) {
      logOperational(correlationId, 'validação_timestamp', 'falha', startTime);
      return buildResult('invalid_signature', createResponse('invalid_signature', correlationId));
    }
    safeStage = 'timestamp_validated';

    // 4. Validação do KID
    safeStage = 'script_properties_loading';
    props = PropertiesService.getScriptProperties();
    safeStage = 'script_properties_loaded';

    var expectedKid = props.getProperty('CONECTEA_EDGE_GAS_SIGNING_KID');
    var kidMatches = (sigKid === expectedKid);
    diagnostics.kid_matches = kidMatches;

    if (!kidMatches) {
      logOperational(correlationId, 'validação_kid', 'falha', startTime);
      return buildResult('invalid_signature', createResponse('invalid_signature', correlationId));
    }
    safeStage = 'kid_validated';

    // 5. Validar SHA-256 do payload canonicalizado
    var computedPayloadSha256 = computeSha256Hex(canonicalizeObject(payload));
    var hashMatches = (payloadSha256 === computedPayloadSha256);
    diagnostics.payload_hash_matches = hashMatches;

    if (!hashMatches) {
      logOperational(correlationId, 'validação_body_hash', 'falha', startTime);
      return buildResult('invalid_signature', createResponse('invalid_signature', correlationId));
    }
    safeStage = 'payload_hash_validated';

    // 6. Validar Assinatura HMAC-SHA256
    safeStage = 'signing_key_decoding';
    var signingKeyBase64Url = props.getProperty('CONECTEA_EDGE_GAS_SIGNING_KEY');
    diagnostics.key_present = (signingKeyBase64Url !== undefined && signingKeyBase64Url !== null && signingKeyBase64Url !== '');

    if (!signingKeyBase64Url) {
      logOperational(correlationId, 'carregamento_chave', 'falha', startTime);
      return buildResult('temporary_failure', createResponse('temporary_failure', correlationId));
    }

    var keyBytes;
    try {
      diagnostics.key_base64url_shape_ok = /^[A-Za-z0-9_-]+$/.test(signingKeyBase64Url);
      keyBytes = decodeBase64UrlStrict(signingKeyBase64Url);
      diagnostics.key_decode_ok = true;
      diagnostics.key_length_ok = (keyBytes && keyBytes.length === 32);
      safeStage = 'signing_key_decoded';
    } catch (keyErr) {
      diagnostics.key_decode_ok = false;
      diagnostics.key_length_ok = false;
      logOperational(correlationId, 'decodificação_chave', 'falha', startTime);
      return buildResult('temporary_failure', createResponse('temporary_failure', correlationId));
    }

    var baseString = 'POST\n' + 'email-change/send-otp/v1\n' + sigVersion + '\n' + sigKid + '\n' + sigTimestamp + '\n' + payloadSha256;
    var computedSignature = computeHmacSha256Hex(baseString, keyBytes);
    var signatureMatches = safeCompare(signature, computedSignature);
    diagnostics.signature_matches = signatureMatches;

    if (!signatureMatches) {
      logOperational(correlationId, 'validação_hmac', 'falha', startTime);
      return buildResult('invalid_signature', createResponse('invalid_signature', correlationId));
    }
    isHmacValidated = true;
    safeStage = 'hmac_validated';

    // 7. Validação de campos obrigatórios do contrato do payload
    var hasRequiredFields = (payload.purpose && payload.idempotency_key && payload.recipient_email && payload.subject && (payload.body_text || payload.body_html));
    diagnostics.required_fields_ok = !!hasRequiredFields;

    if (!hasRequiredFields) {
      logOperational(correlationId, 'validação_payload_obrigatorio', 'falha', startTime);
      return buildResult('invalid_request', createResponse('invalid_request', correlationId));
    }

    // 8. Validação pré-envio de e-mail (sintaxe mínima)
    var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    var emailMatches = emailRegex.test(payload.recipient_email);
    diagnostics.email_shape_ok = emailMatches;

    if (!emailMatches) {
      logOperational(correlationId, 'validação_destinatário', 'inválido', startTime);
      return buildResult('failed_pre_send_invalid_destination', createResponse('failed_pre_send_invalid_destination', correlationId));
    }
    safeStage = 'required_fields_validated';

    // 8.a Suporte a dry_run assinado (preflight de teste)
    if (payload.dry_run === true) {
      logOperational(correlationId, 'dry_run_validado', 'sucesso', startTime);
      safeStage = 'dry_run_quota_check';
      diagnostics.quota_check_reached = true;
      var quota = MailApp.getRemainingDailyQuota();
      diagnostics.quota_check_ok = (quota !== undefined && quota !== null && quota > 0);
      safeStage = 'dry_run_validated';
      return buildResult('dry_run_validated', createResponse('dry_run_validated', correlationId, undefined, quota));
    }

    // 9. Processamento de Idempotência At-Most-Once com Locks
    var lock = LockService.getScriptLock();
    try {
      lock.waitLock(10000); // 10 segundos
    } catch (lockErr) {
      logOperational(correlationId, 'aquisição_lock', 'timeout', startTime);
      return buildResult('temporary_failure', createResponse('temporary_failure', correlationId));
    }

    try {
      var stateKey = 'tombstone:' + payload.purpose + ':' + payload.idempotency_key;
      var existingState = props.getProperty(stateKey);

      if (existingState === 'sent') {
        lock.releaseLock();
        logOperational(correlationId, 'processamento_idempotencia', 'already_sent', startTime);
        return buildResult('already_sent', createResponse('already_sent', correlationId));
      }
      if (existingState === 'attempt_reserved') {
        lock.releaseLock();
        logOperational(correlationId, 'processamento_idempotencia', 'attempt_reserved', startTime);
        return buildResult('attempt_reserved', createResponse('attempt_reserved', correlationId));
      }
      if (existingState === 'ambiguous_attempted') {
        lock.releaseLock();
        logOperational(correlationId, 'processamento_idempotencia', 'ambiguous_attempted', startTime);
        return buildResult('ambiguous_attempted', createResponse('ambiguous_attempted', correlationId));
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
        return buildResult('sent', createResponse('sent', correlationId));
      } catch (sendErr) {
        // Gravar estado de ambiguidade em caso de erro pós-reserva
        props.setProperty(stateKey, 'ambiguous_attempted');
        logOperational(correlationId, 'envio_email', 'ambiguous_attempted', startTime);
        return buildResult('ambiguous_attempted', createResponse('ambiguous_attempted', correlationId));
      }

    } catch (processErr) {
      if (lock.hasLock()) {
        lock.releaseLock();
      }
      logOperational(correlationId, 'processamento_interno', 'erro', startTime);
      var errorName = (processErr && processErr.name) ? processErr.name : 'UnknownError';
      console.log('[doPost] [Correlation ID: ' + correlationId + '] Categoria: process_error | Stage: ' + safeStage + ' | ErrorName: ' + errorName);
      return buildResult('temporary_failure', createResponse('temporary_failure', correlationId));
    }

  } catch (err) {
    var errorName = (err && err.name) ? err.name : 'UnknownError';

    // Internal logging complying with rule 5
    var diagStr = 'timestamp_present=' + diagnostics.timestamp_present +
                  ', timestamp_valid=' + diagnostics.timestamp_valid +
                  ', kid_present=' + diagnostics.kid_present +
                  ', kid_matches=' + diagnostics.kid_matches +
                  ', key_present=' + diagnostics.key_present +
                  ', key_length_ok=' + diagnostics.key_length_ok +
                  ', key_base64url_shape_ok=' + diagnostics.key_base64url_shape_ok +
                  ', key_decode_ok=' + diagnostics.key_decode_ok +
                  ', payload_hash_matches=' + diagnostics.payload_hash_matches +
                  ', signature_matches=' + diagnostics.signature_matches +
                  ', required_fields_ok=' + diagnostics.required_fields_ok +
                  ', email_shape_ok=' + diagnostics.email_shape_ok +
                  ', quota_check_reached=' + diagnostics.quota_check_reached +
                  ', quota_check_ok=' + diagnostics.quota_check_ok;

    console.log('[doPost] [Correlation ID: ' + correlationId + '] Categoria: execution_general_failure | Stage: ' + safeStage + ' | ErrorName: ' + errorName + ' | Diag: ' + diagStr);

    var response = createResponse('temporary_failure', correlationId, undefined, undefined, isHmacValidated ? safeStage : undefined);
    return buildResult('temporary_failure', response);
  }
}

/**
 * Ponto de entrada do Web App para requisições GET.
 */
function doGet(e) {
  var isDiag = e && e.parameter && e.parameter.diagnostic === 'true';
  console.log('[doGet] Entrada registrada. Diagnostic: ' + isDiag);
  return createResponse('invalid_request', 'unknown', isDiag ? 'doGet' : undefined);
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

function createResponse(statusValue, correlationId, handlerName, quotaRemaining, failureStage) {
  var responsePayload = {
    status: statusValue,
    correlation_id: correlationId || 'unknown'
  };
  if (handlerName) {
    responsePayload.handler = handlerName;
  }
  if (quotaRemaining !== undefined && quotaRemaining !== null) {
    responsePayload.quota_remaining = quotaRemaining;
  }
  if (failureStage) {
    responsePayload.failure_stage = failureStage;
  }
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
  var valueBytes = Utilities.newBlob(value).getBytes();
  var hmac = Utilities.computeHmacSha256Signature(valueBytes, keyBytes);
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
