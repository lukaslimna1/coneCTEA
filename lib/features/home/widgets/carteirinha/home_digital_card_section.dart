import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/features/cards/widgets/digital_card_widget.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';

class HomeDigitalCardSection extends StatelessWidget {
  final List<Member> members;
  final List<CardRequest> requests;
  final List<DigitalCard> digitalCards;
  final Member? selectedMember;
  final VoidCallback onRequestCard;
  final VoidCallback onOpenDigitalCard;
  final void Function(Member member, CardRequest? request) onEditPendingRequest;
  final void Function(String requestId) onRequestRenewal;
  final VoidCallback onSupportTap;

  const HomeDigitalCardSection({
    super.key,
    required this.members,
    required this.requests,
    required this.digitalCards,
    required this.selectedMember,
    required this.onRequestCard,
    required this.onOpenDigitalCard,
    required this.onEditPendingRequest,
    required this.onRequestRenewal,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: PremiumCard(
          padding: const EdgeInsets.all(24),
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Você ainda não possui uma carteirinha.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Cadastre um membro para solicitar a carteirinha de identificação premium do projeto.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cardSubtitle.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRequestCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Solicitar Carteirinha',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (selectedMember == null) {
      return const SizedBox.shrink();
    }

    final member = selectedMember!;

    DigitalCard? digitalCard;
    try {
      digitalCard = digitalCards.firstWhere((c) => c.memberId == member.id);
    } catch (_) {
      digitalCard = null;
    }

    CardRequest? memberRequest;
    try {
      memberRequest = requests.firstWhere((r) => r.memberId == member.id);
    } catch (_) {
      memberRequest = null;
    }

    final String rawStatus = (memberRequest?.status ?? member.status)
        .toLowerCase();

    final lastUpdate = memberRequest?.updatedAt ?? member.updatedAt;
    final isExpired =
        rawStatus == 'active' &&
        DateTime.now().difference(lastUpdate).inDays >= 365;
    final statusInfo = HomeStatusHelper.digitalCardStatus(
      rawStatus,
      isExpired: isExpired,
    );
    final status = isExpired ? 'expired' : rawStatus;
    final effectiveStatus = status;

    final String statusDisplay = statusInfo.fullLabel;
    final Color statusColor = statusInfo.color;
    final IconData statusIcon = statusInfo.icon;
    final bool isActive = statusInfo.isActive;
    final bool showJustification = statusInfo.showJustification;
    final bool isRejected = statusInfo.isRejected;

    final adminNotes = memberRequest?.adminNotes ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Documento Digital',
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
                AspectRatio(
                  aspectRatio: 1.58,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: isActive ? 1.0 : 0.6,
                          child: DigitalCardWidget(
                            card: digitalCard,
                            member: member,
                            isStatic: true,
                          ),
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                statusDisplay,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (showJustification && adminNotes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showJustificationDialog(
                        context,
                        statusDisplay,
                        statusColor,
                        adminNotes,
                        isRejected: effectiveStatus == 'rejected',
                      ),
                      icon: Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color: statusColor,
                      ),
                      label: Text(
                        "Ver motivo da ${effectiveStatus == 'rejected' ? 'reprovação' : 'suspensão'}",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (isRejected)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSupportTap,
                      icon: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.errorRed,
                      ),
                      label: Text(
                        'Falar com Suporte',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.errorRed,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: AppColors.errorRed,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isActive) {
                          onOpenDigitalCard();
                        } else if (status == 'waiting_docs' ||
                            status == 'reviewing_data') {
                          onEditPendingRequest(member, memberRequest);
                        } else if (status == 'expired' ||
                            status == 'suspended') {
                          if (memberRequest != null) {
                            onRequestRenewal(memberRequest.id);
                          }
                        }
                      },
                      icon: Icon(
                        isActive
                            ? Icons.qr_code_scanner_rounded
                            : (status == 'expired' || status == 'suspended'
                                  ? Icons.autorenew_rounded
                                  : (status == 'waiting_docs' ||
                                            status == 'reviewing_data'
                                        ? Icons.edit_document
                                        : Icons.lock_outline_rounded)),
                        size: 20,
                      ),
                      label: Text(
                        isActive
                            ? 'Abrir Carteira Digital'
                            : (status == 'expired' || status == 'suspended'
                                  ? 'Solicitar Renovação'
                                  : (status == 'waiting_docs'
                                        ? 'Enviar Documentos'
                                        : (status == 'reviewing_data'
                                              ? 'Revisar Dados'
                                              : 'Aguardando Aprovação'))),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? AppColors.primary
                            : (status == 'waiting_docs' ||
                                      status == 'reviewing_data'
                                  ? AppColors.alertOrange
                                  : (status == 'expired' ||
                                            status == 'suspended'
                                        ? Colors.purple
                                        : AppColors.borderLight.withValues(
                                            alpha: 0.2,
                                          ))),
                        foregroundColor:
                            isActive ||
                                status == 'waiting_docs' ||
                                status == 'reviewing_data' ||
                                status == 'expired' ||
                                status == 'suspended'
                            ? Colors.white
                            : AppColors.textSecondary,
                        elevation: isActive ? 4 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJustificationDialog(
    BuildContext context,
    String status,
    Color color,
    String notes, {
    bool isRejected = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Motivo: $status',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Text(
                notes,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.cardTitle,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isRejected) ...[
              const SizedBox(height: 20),
              Text(
                'Caso não concorde com esta decisão, entre em contato com o nosso suporte para mais informações.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.cardSubtitle.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: GoogleFonts.inter(
                color: AppColors.cardSubtitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isRejected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: onSupportTap,
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Suporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
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
              ),
            ),
        ],
      ),
    );
  }
}
