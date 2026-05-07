import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class GoogleDriveService {
  static const String _gasUrl =
      'https://script.google.com/macros/s/AKfycbz6TiI2-5v8hMh7uTQuSonRzcTEjdWbLqKIZVLbypt7Fktol-EGiv5YxvZzPKePQjvSng/exec';

  Future<String?> uploadFile({
    required PlatformFile file,
    required String fileName,
  }) async {
    try {
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
      postRequest.followRedirects = false; // propriedade do REQUEST
      postRequest.headers.set('Content-Type', 'application/json');
      postRequest.write(bodyStr);

      final postResponse = await postRequest.close();
      final statusCode = postResponse.statusCode;

      debugPrint('GAS POST status: $statusCode');

      // Passo 2: GAS retorna 302 — faz GET na URL de destino para ler a resposta
      if (statusCode == 302 || statusCode == 301) {
        final location = postResponse.headers.value('location');
        await postResponse.drain(); // descarta o body do redirect

        debugPrint('GAS redirect para: $location');

        if (location != null && location.isNotEmpty) {
          final getResponse = await httpClient.getUrl(Uri.parse(location))
              .then((req) {
            req.followRedirects = true; // segue redirects adicionais no GET
            return req.close();
          });

          final responseBody = await getResponse.transform(utf8.decoder).join();
          httpClient.close();

          debugPrint('GAS GET status: ${getResponse.statusCode}');
          debugPrint('GAS GET response: $responseBody');

          if (getResponse.statusCode == 200) {
            final data = jsonDecode(responseBody);
            if (data['status'] == 'success') {
              return data['url'] as String?;
            } else {
              debugPrint('GAS erro: ${data['message']}');
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

      debugPrint('GAS response: $responseBody');

      if (statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['status'] == 'success') {
          return data['url'] as String?;
        } else {
          debugPrint('GAS erro: ${data['message']}');
          return null;
        }
      }

      debugPrint('HTTP erro inesperado: $statusCode');
      return null;
    } catch (e) {
      debugPrint('Erro no upload para Google Drive: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extrair ID do arquivo da URL do Google Drive
      // Formato esperado: https://drive.google.com/file/d/FILE_ID/view?usp=drivesdk
      final RegExp regExp = RegExp(r'/d/([^/]+)/');
      final match = regExp.firstMatch(fileUrl);
      
      if (match == null) {
        debugPrint('Não foi possível extrair o ID do arquivo da URL: $fileUrl');
        return false;
      }
      
      final String fileId = match.group(1)!;
      final String deleteUrl = '$_gasUrl?action=delete&fileId=$fileId';

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(deleteUrl));
      request.followRedirects = true;
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      httpClient.close();

      debugPrint('GAS Delete Response: $responseBody');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['status'] == 'success';
      }
      
      return false;
    } catch (e) {
      debugPrint('Erro ao deletar arquivo no Google Drive: $e');
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
