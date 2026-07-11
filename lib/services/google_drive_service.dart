import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const String _gasUrl =
      'https://script.google.com/macros/s/AKfycbxnwNjkRDEY7lzgfRz3PMovcbHhM_IAvE7LzTgAUKKb0JbCuIVm4XbP6NmkePUyt_pj/exec';

  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> _allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'txt',
    'doc',
    'docx',
    'odt',
    'rtf',
  ];

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Centraliza a chamada ao Google Apps Script para lidar com redirects (302)
  /// que ocorrem tanto no Web quanto no Mobile.
  Future<http.Response> _callGas(Map<String, dynamic> payload) async {
    final uri = Uri.parse(_gasUrl);

    // Tentativa inicial com POST
    http.Response response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    // Lógica para seguir redirects do Google Apps Script
    // O GAS costuma responder com 302 redirecionando para script.googleusercontent.com
    // Às vezes o status code vem como 200 mas o corpo contém o HTML de "Moved Temporarily"
    for (int i = 0; i < 3; i++) {
      final isRedirectStatus =
          response.statusCode >= 300 && response.statusCode < 400;
      final hasRedirectBody =
          response.body.contains('Moved Temporarily') &&
          (response.headers.containsKey('location') ||
              response.body.contains('HREF="'));

      if (isRedirectStatus || hasRedirectBody) {
        String? location = response.headers['location'];

        // Se o header location estiver ausente (comum em alguns ambientes), extraímos do HTML
        if (location == null) {
          final match = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
          if (match != null) {
            location = match.group(1);
            // Desencapsular entidades HTML comuns
            location = location!.replaceAll('&amp;', '&');
          }
        }

        if (location != null) {
          final redirectUri = Uri.parse(location);
          _debugLog('GoogleDriveService: redirecionamento tratado.');
          // Após o POST inicial, o GAS redireciona para um GET no echo service para retornar o JSON
          response = await http.get(redirectUri);
        } else {
          break;
        }
      } else {
        // Não é um redirecionamento, retornamos a resposta atual
        break;
      }
    }
    return response;
  }

  Future<String?> uploadFile({
    required PlatformFile file,
    required String fileName,
  }) async {
    try {
      // Validação de extensão
      final ext = file.extension?.toLowerCase() ?? '';
      if (!_allowedExtensions.contains(ext)) {
        _debugLog('GoogleDriveService: extensão de arquivo não permitida.');
        return null;
      }

      // Validação de tamanho
      if (file.size > _maxFileSize) {
        _debugLog('GoogleDriveService: arquivo acima do limite permitido.');
        return null;
      }

      // Leitura dos bytes (Resolução cross-platform)
      List<int>? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
          bytes = await io.File(file.path!).readAsBytes();
        } else {
          _debugLog('GoogleDriveService: conteúdo do arquivo indisponível.');
          return null;
        }
      }

      final base64Content = base64Encode(bytes);

      final payload = {
        'fileName': fileName,
        'mimeType': _getMimeType(file.extension),
        'content': base64Content,
      };

      _debugLog('GoogleDriveService: upload iniciado.');

      // Faz a chamada ao GAS tratando redirects
      final response = await _callGas(payload);

      if (response.statusCode == 200) {
        // Proteção contra resposta HTML em caso de falha no redirect
        if (response.body.trim().startsWith('<!DOCTYPE html>') ||
            response.body.trim().startsWith('<html')) {
          _debugLog('GoogleDriveService: resposta de upload em formato inesperado.');
          return null;
        }

        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            String? resolvedFileId;
            final idCandidate = data['fileId'] ?? data['id'];
            final fileIdRegex = RegExp(r'^[a-zA-Z0-9_-]{10,256}$');

            if (idCandidate is String && idCandidate.isNotEmpty && fileIdRegex.hasMatch(idCandidate)) {
              resolvedFileId = idCandidate;
            }

            if (resolvedFileId == null) {
              final urlCandidate = data['url'] ?? data['fileUrl'] ?? data['driveUrl'] ?? data['webViewLink'];
              if (urlCandidate is String && urlCandidate.isNotEmpty) {
                final extractedId = extractFileId(urlCandidate);
                if (extractedId != null && fileIdRegex.hasMatch(extractedId)) {
                  resolvedFileId = extractedId;
                }
              }
            }

            if (resolvedFileId == null) {
              _debugLog('GoogleDriveService: identificador do arquivo não validado.');
              return null;
            }

            final canonicalUrl = 'https://drive.google.com/file/d/$resolvedFileId/view';

            _debugLog('GoogleDriveService: upload concluído.');
            return canonicalUrl;
          } else {
            _debugLog('GoogleDriveService: upload recusado pelo serviço.');
            return null;
          }
        } catch (_) {
          _debugLog('GoogleDriveService: resposta de upload inválida.');
          return null;
        }
      }

      _debugLog('GoogleDriveService: falha de rede no upload.');
      return null;
    } catch (_) {
      _debugLog('GoogleDriveService: falha inesperada no upload.');
      return null;
    }
  }

  /// Extrai o ID do arquivo a partir de uma URL do Google Drive.
  /// Suporta os formatos /d/FILE_ID e id=FILE_ID.
  String? extractFileId(String fileUrl) {
    // Tentar formato /d/ID/ ou /d/ID
    final RegExp regExpD = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final matchD = regExpD.firstMatch(fileUrl);
    if (matchD != null) {
      return matchD.group(1);
    }

    // Tentar formato id=ID
    final RegExp regExpId = RegExp(r'id=([a-zA-Z0-9_-]+)');
    final matchId = regExpId.firstMatch(fileUrl);
    if (matchId != null) {
      return matchId.group(1);
    }

    return null;
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final fileId = extractFileId(fileUrl);

      if (fileId == null || fileId.isEmpty) {
        _debugLog('GoogleDriveService: identificador indisponível para descarte.');
        return false;
      }

      final response = await _callGas({'action': 'delete', 'fileId': fileId});

      if (response.statusCode == 200) {
        // Proteção contra resposta HTML
        if (response.body.trim().startsWith('<!DOCTYPE html>') ||
            response.body.trim().startsWith('<html')) {
          _debugLog('GoogleDriveService: resposta de descarte em formato inesperado.');
          return false;
        }

        final data = jsonDecode(response.body);
        final success = data['status'] == 'success';
        if (success) {
          _debugLog('GoogleDriveService: descarte concluído.');
        } else {
          _debugLog('GoogleDriveService: descarte recusado pelo serviço.');
        }
        return success;
      }

      _debugLog('GoogleDriveService: falha de rede no descarte.');
      return false;
    } catch (_) {
      _debugLog('GoogleDriveService: falha inesperada no descarte.');
      return false;
    }
  }

  String _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'rtf':
        return 'application/rtf';
      default:
        return 'application/octet-stream';
    }
  }
}
