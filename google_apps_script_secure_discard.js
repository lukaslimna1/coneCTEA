// ============================================================
// Google Apps Script — ConeCTEA Drive Secure Discard (Separado)
// Conta: conecteabauru@gmail.com
//
// Este GAS é EXCLUSIVO para descarte seguro de arquivos
// do Google Drive, chamado apenas pela Edge Function
// process-gc-drive-queue (servidor-servidor).
//
// NÃO atende upload, carteirinhas ou qualquer outro fluxo.
// NÃO é chamado pelo app Flutter diretamente.
//
// AUTENTICAÇÃO: HMAC-SHA256 com timestamp anti-replay.
// SEGREDO: Script Property "SIGNING_KEY" (configurar manualmente).
// ============================================================

// ──────────────────────────────────────────────────────────────
// Configuração
// ──────────────────────────────────────────────────────────────

var REPLAY_WINDOW_MS = 5 * 60 * 1000; // ±5 minutos
var ACTION_EXPECTED = 'secure_discard_v1';
var VALID_REASONS = [
  'request_approved',
  'request_rejected',
  'request_cancelled',
  'request_expired',
  'document_replaced'
];

var FILE_ID_REGEX = /^[A-Za-z0-9_-]+$/;
var UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
var SIGNATURE_REGEX = /^[a-fA-F0-9]{64}$/;

// ──────────────────────────────────────────────────────────────
// Entrada principal — POST
// ──────────────────────────────────────────────────────────────

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);

    // 1. Validar que data é um objeto válido, não nulo e não array
    if (data === null || typeof data !== 'object' || Array.isArray(data)) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 2. Validar presença dos campos e tipos estritamente como string
    if (
      typeof data.action !== 'string' ||
      typeof data.file_id !== 'string' ||
      typeof data.request_id !== 'string' ||
      typeof data.reason !== 'string' ||
      typeof data.timestamp !== 'string' ||
      typeof data.signature !== 'string'
    ) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 3. Validar action esperada
    if (data.action !== ACTION_EXPECTED) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 4. Validar reason contra whitelist
    if (VALID_REASONS.indexOf(data.reason) === -1) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 5. Validar formato do file_id (entre 10 e 256 caracteres, contendo apenas caracteres seguros)
    var fileId = data.file_id;
    if (fileId.length < 10 || fileId.length > 256 || !FILE_ID_REGEX.test(fileId)) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 6. Validar formato do request_id (deve ser UUID válido)
    var requestId = data.request_id;
    if (!UUID_REGEX.test(requestId)) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 7. Validar formato hexadecimal de exatamente 64 caracteres da assinatura
    var signature = data.signature;
    if (!SIGNATURE_REGEX.test(signature)) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    // 8. Verificar HMAC-SHA256
    var signingKey = PropertiesService.getScriptProperties().getProperty('SIGNING_KEY');
    if (!signingKey) {
      // Chave não configurada no painel do GAS = falha de autenticação
      return createJsonResponse({ success: false, error: 'auth_failed' });
    }

    var canonicalString = data.action + '|' + fileId + '|' + requestId + '|' + data.reason + '|' + data.timestamp;
    var expectedSignature = computeHmacHex(signingKey, canonicalString);

    // Comparação segura de assinaturas contra ataques de tempo
    if (!safeCompareHex(expectedSignature, signature)) {
      return createJsonResponse({ success: false, error: 'auth_failed' });
    }

    // 9. Proteção anti-replay: verificar janela de timestamp
    var requestTime = new Date(data.timestamp).getTime();
    var serverTime = new Date().getTime();

    if (isNaN(requestTime)) {
      return createJsonResponse({ success: false, error: 'invalid_payload' });
    }

    var drift = Math.abs(serverTime - requestTime);
    if (drift > REPLAY_WINDOW_MS) {
      return createJsonResponse({ success: false, error: 'replay_rejected' });
    }

    // 10. Executar descarte no Drive
    var maskedFileId = maskId(fileId);
    var maskedRequestId = maskId(requestId);

    try {
      var file = DriveApp.getFileById(fileId);
      file.setTrashed(true);

      // Log seguro: ID de requisição e do arquivo mascarados
      Logger.log('DISCARD_OK: req=' + maskedRequestId + ' file=' + maskedFileId + ' reason=' + data.reason);

      return createJsonResponse({ success: true, status: 'trashed' });
    } catch (driveErr) {
      var errMsg = driveErr.message || '';

      if (errMsg.indexOf('File not found') !== -1 || errMsg.indexOf('is not found') !== -1) {
        Logger.log('DISCARD_NOT_FOUND: req=' + maskedRequestId + ' file=' + maskedFileId);
        return createJsonResponse({ success: false, error: 'file_not_found' });
      }

      if (errMsg.indexOf('permission') !== -1 || errMsg.indexOf('Permission') !== -1 || errMsg.indexOf('forbidden') !== -1) {
        Logger.log('DISCARD_PERMISSION: req=' + maskedRequestId + ' file=' + maskedFileId);
        return createJsonResponse({ success: false, error: 'permission_denied' });
      }

      // Erro genérico do Drive (temporário)
      Logger.log('DISCARD_DRIVE_ERROR: req=' + maskedRequestId + ' file=' + maskedFileId);
      return createJsonResponse({ success: false, error: 'drive_error' });
    }

  } catch (parseErr) {
    // Payload não é JSON válido ou erro inesperado
    return createJsonResponse({ success: false, error: 'invalid_payload' });
  }
}

// ──────────────────────────────────────────────────────────────
// Bloquear GET
// ──────────────────────────────────────────────────────────────

function doGet(e) {
  return createJsonResponse({ success: false, error: 'method_not_allowed' });
}

// ──────────────────────────────────────────────────────────────
// Utilitários
// ──────────────────────────────────────────────────────────────

/**
 * Calcula HMAC-SHA256 e retorna em hexadecimal lowercase.
 */
function computeHmacHex(key, data) {
  var rawSignature = Utilities.computeHmacSha256Signature(data, key);
  var hex = '';
  for (var i = 0; i < rawSignature.length; i++) {
    var byte = rawSignature[i];
    if (byte < 0) byte += 256;
    var hexByte = byte.toString(16);
    if (hexByte.length === 1) hexByte = '0' + hexByte;
    hex += hexByte;
  }
  return hex;
}

/**
 * Comparação segura em tempo constante (constant-time comparison) para hashes hexadecimais.
 */
function safeCompareHex(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') {
    return false;
  }
  if (a.length !== b.length) {
    return false;
  }
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

/**
 * Mascara qualquer string ID para exibição segura em logs:
 * Mostra apenas os 4 últimos caracteres precedidos de asteriscos.
 */
function maskId(idString) {
  if (!idString || idString.length <= 4) return '****';
  return '****' + idString.substring(idString.length - 4);
}

/**
 * Cria resposta JSON padronizada.
 */
function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
