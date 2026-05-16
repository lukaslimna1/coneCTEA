import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

class AdminRequestCard extends StatelessWidget {
  final CardRequest request;
  final VoidCallback onTap;

  const AdminRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = StatusVisualTokens.fromStatus(request.status);

    return PremiumCard(
      hasGradient: true,
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${request.protocol.isEmpty ? request.id.substring(0, 6).toUpperCase() : request.protocol}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(tokens),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              request.memberName.isNotEmpty ? request.memberName.toUpperCase() : 'MEMBRO NÃO IDENTIFICADO',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  _getTypeLabel(request.type),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Analisar solicitação',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C3AED), // Soft Purple
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF7C3AED)),
              ],
            ),
          ],
        ),
      );
    }

  Widget _buildStatusBadge(StatusVisualTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tokens.pillBorder,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Overlay da cor do status sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: tokens.pillBackground,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tokens.icon,
                color: tokens.primary,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                tokens.label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: tokens.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'new_card':
      case 'emissão digital':
      case 'primeira via':
        return 'Emissão de Carteirinha';
      case 'update_data':
      case 'atualização de cadastro':
        return 'Atualização Cadastral';
      case 'support':
        return 'Suporte';
      default:
        return type.isNotEmpty ? type : 'Solicitação';
    }
  }
}
