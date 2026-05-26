import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestUnsavedChangesDialog extends StatelessWidget {
  const RequestUnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F1B2F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E2E4A)),
      ),
      title: Text(
        'Descartar alterações?',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      content: Text(
        'Você possui alterações não salvas. Se sair agora, todos os dados modificados e novos documentos enviados nesta sessão serão perdidos definitivamente.',
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 15,
          height: 1.4,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            'Continuar Editando',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4D4D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Sair sem Salvar',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
