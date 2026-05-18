import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';

enum AdminModuleStatus {
  active,
  comingSoon,
  restricted,
  devOnly,
}

class AdminModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final AdminModuleStatus status;
  final VoidCallback onTap;
  final ConecteaVisualToken token; // O token semântico obrigatório que dita a identidade do card

  const AdminModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.onTap,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComingSoon = status == AdminModuleStatus.comingSoon;
    final bool isRestricted = status == AdminModuleStatus.restricted;

    return PremiumCard(
      onTap: onTap,
      hasGradient: !isComingSoon && !isRestricted,
      backgroundColor: isComingSoon 
          ? const Color(0x1F0F172A) // Mais apagado para "Em breve" (Slate translúcido)
          : isRestricted 
              ? const Color(0x331E293B) // Cor elegante e sutil para bloqueado
              : null,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone com contêiner estilizado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: token.iconBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: token.border,
                width: 1,
              ),
            ),
            child: Icon(
              isRestricted ? PhosphorIconsRegular.lockSimple : icon,
              color: token.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Informações de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isComingSoon 
                              ? AppColors.textPrimary.withValues(alpha: 0.5) 
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: isComingSoon 
                        ? AppColors.textSecondary.withValues(alpha: 0.4) 
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    String text;

    switch (status) {
      case AdminModuleStatus.active:
        text = 'Ativo';
        break;
      case AdminModuleStatus.comingSoon:
        text = 'Em breve';
        break;
      case AdminModuleStatus.restricted:
        text = 'Acesso restrito';
        break;
      case AdminModuleStatus.devOnly:
        text = 'Admin Dev';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: token.softBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: token.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: token.accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
