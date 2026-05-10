import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class GoogleDriveService {
  static const String _gasUrl =
      'https://script.google.com/macros/s/AKfycbz6TiI2-5v8hMh7uTQuSonRzcTEjdWbLqKIZVLbypt7Fktol-EGiv5YxvZzPKePQjvSng/exec';

  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  Future<String?> uploadFile({
    required PlatformFile file,
    required String fileName,
  }) async {
    try {
      // Validação de extensão
      final ext = file.extension?.toLowerCase() ?? '';
      if (!_allowedExtensions.contains(ext)) {
        debugPrint('Erro: Extensão .$ext não permitida.');
        return null;
      }

      // Validação de tamanho
      if (file.size > _maxFileSize) {
        debugPrint('Erro: Arquivo excede o limite de 5MB (${file.size} bytes).');
        return null;
      }

      final bytes = file.bytes ?? (throw Exception('Arquivo sem conteúdo'));
      final base64Content = base64Encode(bytes);

      final bodyStr = jsonEncode({
        'fileName': fileName,
        'mimeType': _getMimeType(file.extension),
        'content': base64Content,
      });

      final httpClient = HttpClient();

      // Passo 1: POST para /exec sem seguir redirect
      final postRequest = await httpClient.postUrl(Uri.parse(_gasUrl));
      postRequest.followRedirects = false;
      postRequest.headers.set('Content-Type', 'application/json');
      postRequest.write(bodyStr);

      final postResponse = await postRequest.close();
      final statusCode = postResponse.statusCode;

      // Passo 2: GAS retorna 302 — faz GET na URL de destino para ler a resposta
      if (statusCode == 302 || statusCode == 301) {
        final location = postResponse.headers.value('location');
        await postResponse.drain();

        if (location != null && location.isNotEmpty) {
          final getResponse = await httpClient.getUrl(Uri.parse(location))
              .then((req) {
            req.followRedirects = true;
            return req.close();
          });

          final responseBody = await getResponse.transform(utf8.decoder).join();
          httpClient.close();

          if (getResponse.statusCode == 200) {
            final data = jsonDecode(responseBody);
            if (data['status'] == 'success') {
              return data['url'] as String?;
            } else {
              debugPrint('GAS erro: Operação não concluída com sucesso.');
              return null;
            }
          }
        }

        httpClient.close();
        return null;
      }

      // Resposta direta (200 sem redirect)
      final responseBody = await postResponse.transform(utf8.decoder).join();
      httpClient.close();

      if (statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['status'] == 'success') {
          return data['url'] as String?;
        } else {
          debugPrint('GAS erro: Operação não concluída com sucesso.');
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erro no upload para infraestrutura de documentos.');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extrair ID do arquivo da URL do Google Drive
      final RegExp regExp = RegExp(r'/d/([^/]+)/');
      final match = regExp.firstMatch(fileUrl);
      
      if (match == null) {
        return false;
      }
      
      final String fileId = match.group(1)!;

      // Mitigação: Usar POST para delete no body em vez de Query Params na URL
      // Nota: O script GAS precisa ser atualizado para aceitar 'action' no body do POST
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(Uri.parse(_gasUrl));
      request.followRedirects = false;
      request.headers.set('Content-Type', 'application/json');
      
      request.write(jsonEncode({
        'action': 'delete',
        'fileId': fileId,
      }));

      final response = await request.close();

      // Se houver redirect 302 (comum no GAS POST), seguimos para ler o resultado
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location');
        await response.drain();

        if (location != null) {
          final getResponse = await httpClient.getUrl(Uri.parse(location));
          final finalResponse = await getResponse.close();
          final responseBody = await finalResponse.transform(utf8.decoder).join();
          httpClient.close();

          final data = jsonDecode(responseBody);
          return data['status'] == 'success';
        }
      }

      final responseBody = await response.transform(utf8.decoder).join();
      httpClient.close();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['status'] == 'success';
      }
      
      return false;
    } catch (e) {
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
      default:
        return 'application/octet-stream';
    }
  }
}
