import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/core/constants/colors.dart';

class ProfileSupportDialog {
  static void show(BuildContext context, String field) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(
              Icons.support_agent_rounded,
              color: AppColors.alertOrange,
            ),
            const SizedBox(width: 8),
            Text(
              'Alterar $field',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para sua segurança, campos de identificação crítica como $field não podem ser editados diretamente no aplicativo.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entre em contato com o suporte da ConeCTEA para solicitar esta alteração.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fechar',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              const url = 'https://wa.me/5514997728448';
              if (await canLaunchUrlString(url)) {
                await launchUrlString(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Falar no WhatsApp',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
