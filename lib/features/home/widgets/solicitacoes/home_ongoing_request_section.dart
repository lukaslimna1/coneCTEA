import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';

class HomeOngoingRequestSection extends StatelessWidget {
  final List<CardRequest> requests;
  final VoidCallback onDetailsTap;

  const HomeOngoingRequestSection({
    super.key,
    required this.requests,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final ongoingRequests = requests.where((r) {
      final s = r.status.toLowerCase();
      return s != 'active' &&
          s != 'ativa' &&
          s != 'approved' &&
          s != 'aprovada';
    }).toList();

    if (ongoingRequests.isEmpty) return const SizedBox.shrink();

    final request = ongoingRequests.first;

    final String rawStatus = request.status.toLowerCase();
    final statusInfo = HomeStatusHelper.ongoingRequestStatus(rawStatus);

    final String statusDisplay = statusInfo.fullLabel;
    final Color statusColor = statusInfo.color;
    final IconData statusIcon = statusInfo.icon;
    final bool isApproved = statusInfo.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Solicitação em andamento',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.cardTitle,
              ),
            ),
          ),
          PremiumCard(
            padding: const EdgeInsets.all(24),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617).withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.type == 'new_card' ||
                                    request.type == 'Emissão Digital'
                                ? 'Emissão de Carteirinha'
                                : 'Atualização de Cadastro',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Protocolo: #${request.protocol}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cardSubtitle.withValues(
                                  alpha: 0.7,
                                ),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: statusInfo.pillBorder,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Overlay da cor do status sutil
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: statusInfo.pillBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Text(
                              statusDisplay,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproved
                                ? 'Solicitação concluída'
                                : 'Previsão de conclusão',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.cardSubtitle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isApproved
                                ? 'Já disponível na carteira'
                                : 'Em até 5 dias úteis',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onDetailsTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detalhes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (request.expiresAt != null &&
              (request.status == 'waiting_docs' ||
                  request.status == 'reviewing_data'))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.expiresAt != null
                            ? 'Você tem até o dia ${request.expiresAt!.day.toString().padLeft(2, '0')}/${request.expiresAt!.month.toString().padLeft(2, '0')}/${request.expiresAt!.year} para concluir ou sua solicitação será reprovada.'
                            : 'Sua solicitação está sendo analisada.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
