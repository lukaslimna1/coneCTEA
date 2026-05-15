import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';

class HomeGreetingHeader extends StatelessWidget {
  final String displayName;
  final UserRole? role;
  final VoidCallback onQrTap;

  const HomeGreetingHeader({
    super.key,
    required this.displayName,
    this.role,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Olá, $displayName!',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cardTitle,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (role != null && role != UserRole.user) ...[
                      const SizedBox(width: 8),
                      _buildAdminBadge(),
                    ],
                  ],
                ),
                Text(
                  'Que bom te ver por aqui.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardSubtitle,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onQrTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: const Icon(
                PhosphorIconsBold.qrCode,
                color: AppColors.cardTitle,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    if (role == null || role == UserRole.user) return const SizedBox.shrink();

    return Tooltip(
      message: _getRoleTooltip(),
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: _getRoleTooltip(),
        child: _AdminRankInsignia(role: role!),
      ),
    );
  }

  String _getRoleTooltip() {
    switch (role) {
      case UserRole.adminDev:
        return 'Administrador de Desenvolvimento';
      case UserRole.adminMaster:
        return 'Administrador Master';
      case UserRole.admin:
        return 'Administrador';
      default:
        return '';
    }
  }
}

/// Widget interno para compor a insígnia de patente administrativa premium.
class _AdminRankInsignia extends StatelessWidget {
  final UserRole role;

  const _AdminRankInsignia({required this.role});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (role) {
      case UserRole.adminDev:
        icon = PhosphorIcons.codeSimple(PhosphorIconsStyle.bold);
        color = const Color(0xFF22D3EE).withValues(alpha: 0.9); // Ciano suave premium
        break;
      case UserRole.adminMaster:
        icon = PhosphorIcons.crown(PhosphorIconsStyle.bold);
        color = const Color(0xFFFBBF24).withValues(alpha: 0.9); // Dourado âmbar suave
        break;
      case UserRole.admin:
      default:
        icon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold);
        color = const Color(0xFF34D399).withValues(alpha: 0.9); // Verde esmeralda suave
        break;
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xD90F172A), // Dark glass mais fechado e premium
        borderRadius: BorderRadius.circular(10),
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
      child: Icon(
        icon,
        color: color,
        size: 18,
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
