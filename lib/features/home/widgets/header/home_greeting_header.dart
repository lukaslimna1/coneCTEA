import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

import 'package:conectea/models/app_user.dart';
import 'package:conectea/core/widgets/premium/premium_qr_button.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

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
          PremiumQrButton(onTap: onQrTap),
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
        child: DsSeloCargo.compacto(role: role!),
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
