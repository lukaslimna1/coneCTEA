import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';

/// Variantes disponíveis para o emblema de cargo.
enum ConecteaRoleBadgeVariant {
  /// Usada na Home. Exibe apenas o ícone do cargo dentro do dark glass.
  compact,

  /// Usada em cabeçalhos ou painéis (como o Hub de Gestão). Exibe o ícone e o texto curto do cargo.
  expanded,
}

/// Um componente global reutilizável para emblemas de cargo do ConeCTEA.
/// Segue a estética premium Night Blue e Dark Glass, com as exatas cores,
/// ícones e fundos validados e aprovados.
class ConecteaRoleBadge extends StatelessWidget {
  final UserRole role;
  final ConecteaRoleBadgeVariant variant;

  const ConecteaRoleBadge({
    super.key,
    required this.role,
    this.variant = ConecteaRoleBadgeVariant.compact,
  });

  const ConecteaRoleBadge.compact({
    super.key,
    required this.role,
  }) : variant = ConecteaRoleBadgeVariant.compact;

  const ConecteaRoleBadge.expanded({
    super.key,
    required this.role,
  }) : variant = ConecteaRoleBadgeVariant.expanded;

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.user) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String label;

    // Lógica semântica por cargo aprovada na Home
    switch (role) {
      case UserRole.adminDev:
        icon = PhosphorIcons.codeSimple(PhosphorIconsStyle.bold);
        color = ConecteaVisualTokens.manutencaoTecnica.accent.withValues(alpha: 0.9); // Roxo/violeta técnico
        label = 'ADM Dev';
        break;
      case UserRole.adminMaster:
        icon = PhosphorIcons.crown(PhosphorIconsStyle.bold);
        color = const Color(0xFFFBBF24).withValues(alpha: 0.9); // Dourado âmbar suave
        label = 'ADM Master';
        break;
      case UserRole.admin:
      default:
        icon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold);
        color = const Color(0xFF34D399).withValues(alpha: 0.9); // Verde esmeralda suave
        label = 'ADM';
        break;
    }

    final bool isExpanded = variant == ConecteaRoleBadgeVariant.expanded;

    return Container(
      padding: isExpanded
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xD90F172A), // Dark glass mais fechado e premium
        borderRadius: BorderRadius.circular(10), // Mesma curvatura aprovada
        border: Border.all(
          color: color.withValues(alpha: 0.25), // Borda temática sutil
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: isExpanded
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16, // Levemente menor no modo expandido para equilibrar com o texto
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            )
          : Icon(
              icon,
              color: color,
              size: 18, // Tamanho original aprovado
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
    );
  }
}
