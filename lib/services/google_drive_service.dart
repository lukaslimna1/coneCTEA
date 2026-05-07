import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class GoogleDriveService {
  // O usuário deve substituir esta URL após implantar o Google Apps Script
  static const String _gasUrl = 'https://script.google.com/macros/s/AKfycbx42XLdCojO8uLppfrEEBwhY6GTBjSKeNVqsqmWhk2phrnJfZwvqL_KaPumUxB6XJVDZw/exec';

  Future<String?> uploadFile({
    required PlatformFile file,
    required String fileName,
  }) async {
    if (_gasUrl == 'SUA_URL_DO_GOOGLE_APPS_SCRIPT_AQUI') {
      throw Exception('URL do Google Apps Script não configurada no google_drive_service.dart');
    }

    try {
      final bytes = await File(file.path!).readAsBytes();
      final base64Content = base64Encode(bytes);

      // Usando request manual para ter mais controle se necessário, 
      // mas o http.post padrão já deve funcionar se o GAS retornar 200.
      // Em caso de 302 (comum no GAS), o body pode estar no local do redirecionamento.
      final response = await http.post(
        Uri.parse(_gasUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': fileName,
          'mimeType': _getMimeType(file.extension),
          'content': base64Content,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['url'] as String?;
        } else {
          print('Erro do GAS: ${data['message']}');
          return null;
        }
      } else if (response.statusCode == 302) {
        // Se houver redirecionamento, a URL de destino está no header 'location'
        final newUrl = response.headers['location'];
        if (newUrl != null) {
          final secondResponse = await http.get(Uri.parse(newUrl));
          if (secondResponse.statusCode == 200) {
            final data = jsonDecode(secondResponse.body);
            return data['url'] as String?;
          }
        }
        return null;
      } else {
        print('Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro no upload para Google Drive: $e');
      return null;
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
