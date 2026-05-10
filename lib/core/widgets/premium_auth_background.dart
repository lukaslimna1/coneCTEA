import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import 'premium/app_background.dart';

class PremiumAuthBackground extends StatelessWidget {
  final Widget child;

  const PremiumAuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Stack(
        children: [
          // 1. Conteúdo Principal
          child,

          // 2. Barra de Segurança/Informação Inferior
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1B31).withValues(alpha: 0.4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.shieldCheck(), color: AppColors.cyan, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ambiente seguro e criptografado para seus dados.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
