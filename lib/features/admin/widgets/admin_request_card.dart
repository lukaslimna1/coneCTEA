import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/card_request.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/premium/premium_card.dart';
import '../utils/admin_status_helper.dart';

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
    final statusColor = AdminStatusHelper.getStatusColor(request.status);
    final statusLabel = AdminStatusHelper.getStatusLabel(request.status);

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
                _buildStatusBadge(statusColor, statusLabel),
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

  Widget _buildStatusBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
            ),
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
