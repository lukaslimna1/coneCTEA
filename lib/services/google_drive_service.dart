import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const String _gasUrl =
      'https://script.google.com/macros/s/AKfycbz6TiI2-5v8hMh7uTQuSonRzcTEjdWbLqKIZVLbypt7Fktol-EGiv5YxvZzPKePQjvSng/exec';

  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> _allowedExtensions = [
    'pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
    'txt', 'doc', 'docx', 'odt', 'rtf'
  ];

  /// Centraliza a chamada ao Google Apps Script para lidar com redirects (302)
  /// que ocorrem tanto no Web quanto no Mobile.
  Future<http.Response> _callGas(Map<String, dynamic> payload) async {
    final platform = kIsWeb ? 'Web' : 'Mobile';
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
      final isRedirectStatus = response.statusCode >= 300 && response.statusCode < 400;
      final hasRedirectBody = response.body.contains('Moved Temporarily') &&
                             (response.headers.containsKey('location') || response.body.contains('HREF="'));

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
          debugPrint('[$platform] Seguindo redirect GAS (${response.statusCode}) para: ${redirectUri.host}');
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
    final platform = kIsWeb ? 'Web' : 'Mobile';
    try {
      // Validação de extensão
      final ext = file.extension?.toLowerCase() ?? '';
      if (!_allowedExtensions.contains(ext)) {
        debugPrint('[$platform] Erro: Extensão .$ext não permitida.');
        return null;
      }

      // Validação de tamanho
      if (file.size > _maxFileSize) {
        debugPrint('[$platform] Erro: Arquivo excede o limite de 5MB (${file.size} bytes).');
        return null;
      }

      // Leitura dos bytes (Resolução cross-platform)
      List<int>? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
          bytes = await io.File(file.path!).readAsBytes();
        } else {
          debugPrint('[$platform] Erro: file.bytes está nulo e não há fallback possível.');
          return null;
        }
      }

      final base64Content = base64Encode(bytes);

      final payload = {
        'fileName': fileName,
        'mimeType': _getMimeType(file.extension),
        'content': base64Content,
      };

      debugPrint('[$platform] Iniciando upload: $fileName (${bytes.length} bytes)');

      // Faz a chamada ao GAS tratando redirects
      final response = await _callGas(payload);

      if (response.statusCode == 200) {
        // Proteção contra resposta HTML em caso de falha no redirect
        if (response.body.trim().startsWith('<!DOCTYPE html>') || response.body.trim().startsWith('<html')) {
          debugPrint('[$platform] Erro: Resposta GAS é HTML em vez de JSON.');
          return null;
        }

        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            final result = data['url'] ?? '';
            final maskedId = result.length > 8
                ? '${result.substring(0, 4)}...${result.substring(result.length - 4)}'
                : result;
            debugPrint('[$platform] Sucesso: Arquivo do Drive enviado (ID: $maskedId).');
            return data['url'] as String?;
          } else {
            debugPrint('[$platform] GAS erro: ${data['message'] ?? 'Erro desconhecido'}');
            return null;
          }
        } catch (e) {
          debugPrint('[$platform] Erro ao decodificar JSON do GAS: $e');
          return null;
        }
      }

      debugPrint('[$platform] Erro de rede: statusCode=${response.statusCode}');
      return null;
    } catch (e, stacktrace) {
      final platform = kIsWeb ? 'Web' : 'Mobile';
      debugPrint('[$platform] Erro no upload: $e');
      debugPrint('Stacktrace: $stacktrace');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    final platform = kIsWeb ? 'Web' : 'Mobile';
    try {
      String? fileId;
      // Tentar formato /d/ID/ ou /d/ID
      final RegExp regExpD = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final matchD = regExpD.firstMatch(fileUrl);
      if (matchD != null) {
        fileId = matchD.group(1);
      } else {
        // Tentar formato id=ID
        final RegExp regExpId = RegExp(r'id=([a-zA-Z0-9_-]+)');
        final matchId = regExpId.firstMatch(fileUrl);
        if (matchId != null) {
          fileId = matchId.group(1);
        }
      }

      if (fileId == null || fileId.isEmpty) {
        debugPrint('[$platform] Erro: Não foi possível extrair o ID do arquivo para deleção.');
        return false;
      }

      
      final response = await _callGas({
        'action': 'delete',
        'fileId': fileId,
      });

      if (response.statusCode == 200) {
        // Proteção contra resposta HTML
        if (response.body.trim().startsWith('<!DOCTYPE html>') || response.body.trim().startsWith('<html')) {
          debugPrint('[$platform] Erro ao deletar: Resposta GAS é HTML.');
          return false;
        }

        final data = jsonDecode(response.body);
        final success = data['status'] == 'success';
        if (success) {
          final maskedId = fileId.length > 8
              ? '${fileId.substring(0, 4)}...${fileId.substring(fileId.length - 4)}'
              : fileId;
          debugPrint('[$platform] Sucesso: Arquivo do Drive deletado com segurança (ID: $maskedId).');
        } else {
          debugPrint('[$platform] Erro no GAS ao deletar: ${data['message'] ?? data}');
        }
        return success;
      }
      
      debugPrint('[$platform] Erro de rede ao deletar: statusCode=${response.statusCode}');
      return false;
    } catch (e) {
      final platform = kIsWeb ? 'Web' : 'Mobile';
      debugPrint('[$platform] Erro na função deleteFile: $e');
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
