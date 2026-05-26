import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/services/google_drive_service.dart';

class RequestCleanupHelper {
  /// Executa a limpeza física dos uploads temporários da sessão no Google Drive
  /// enquanto apresenta um feedback visual de progresso para o usuário.
  /// No final, fecha as telas necessárias de forma segura.
  static Future<void> performCleanupAndExit({
    required BuildContext context,
    required List<String> uploadedUrls,
    required GoogleDriveService driveService,
  }) async {
    if (uploadedUrls.isEmpty) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Exibe o diálogo de progresso de descarte
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope<Object?>(
          canPop: false,
          child: Dialog(
            backgroundColor: const Color(0xFF0F1B2F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF1E2E4A)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00D4FF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Descartando alterações...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Removendo com segurança os novos arquivos enviados ao Drive.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      for (final url in uploadedUrls) {
        await driveService.deleteFile(url);
      }
    } catch (e) {
      debugPrint('Erro ao deletar arquivos descartados no Drive: $e');
    }

    uploadedUrls.clear();

    // Fecha o diálogo de progresso assincronamente e com validação de ciclo de vida
    if (context.mounted) {
      Navigator.of(context).pop(); // Fecha o diálogo de loading
    }

    // Fecha a tela AddMemberPage
    if (context.mounted) {
      Navigator.of(context).pop(); // Fecha a tela AddMemberPage
    }
  }
}
