import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/status_action_button.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/features/cards/widgets/carteirinha_digital/digital_card_widget.dart';
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

    final String rawStatus = HomeStatusHelper.getEffectiveStatus(
      memberStatus: member.status,
      memberRequest: memberRequest,
    );

    final lastUpdate = memberRequest?.updatedAt ?? member.updatedAt;
    final isExpired =
        rawStatus == 'active' &&
        DateTime.now().difference(lastUpdate).inDays >= 365;

    final statusInfo = HomeStatusHelper.digitalCardStatus(
      member.status,
      memberRequest: memberRequest,
      isExpired: isExpired,
    );
    final effectiveStatus = isExpired ? 'expired' : rawStatus;

    final String statusDisplay = statusInfo.fullLabel;
    final Color statusColor = statusInfo.color;
    final bool isActive = statusInfo.isActive;
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
          // Container Principal com DNA Premium Card
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A192F), // Tom de fundo profundo
                  Color(0xFF060D1A), // Quase preto
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0x2494A3B4), // Padrão premium borda
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Camada de vidro sutil
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.025),
                    ),
                  ),
                ),

                // Efeito de luz sutil no canto (Glow)
                Positioned(
                  bottom: -60,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.12),
                          statusColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Borda superior colorida (Acento Premium)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Preview da Carteirinha
                      AspectRatio(
                        aspectRatio: 1.58,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: isActive ? 1.0 : 0.6,
                                child: DigitalCardWidget(
                                  card: digitalCard,
                                  member: member,
                                  isStatic: true,
                                ),
                              ),
                              // Selo de Status Centralizado (Horizontal Pill)
                              if (!isActive)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withValues(alpha: 0.25),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusInfo.icon,
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          statusDisplay.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: statusColor,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Linha Técnica de Requerimento (Discreta e Copiável)
                      Builder(
                        builder: (context) {
                          final protocol = memberRequest?.protocol;
                          if (isActive || protocol == null || protocol.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: protocol));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Requerimento copiado',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 2),
                                    margin: const EdgeInsets.all(20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      protocol,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      ),


                      if (statusInfo.secondaryActionLabel != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _showJustificationDialog(
                              context,
                              statusInfo,
                              adminNotes,
                            ),
                            icon: Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                              color: statusColor,
                            ),
                            label: Text(
                              statusInfo.secondaryActionLabel!,
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
                      const SizedBox(height: 20),
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
                        StatusActionButton(
                          isExpanded: true,
                          height: 52,
                          fontSize: 14,
                          statusKey: isActive
                              ? 'active'
                              : (effectiveStatus.isEmpty
                                  ? 'waiting_approval'
                                  : effectiveStatus),
                          label: isActive
                              ? 'Abrir Carteira Digital'
                              : (effectiveStatus == 'expired' ||
                                      effectiveStatus == 'suspended'
                                  ? 'Solicitar Renovação'
                                  : (effectiveStatus == 'waiting_docs'
                                      ? 'Enviar Documentos'
                                      : (effectiveStatus == 'reviewing_data'
                                          ? 'Revisar Dados'
                                          : 'Aguardando Aprovação'))),
                          iconOverride: isActive
                              ? Icons.qr_code_scanner_rounded
                              : (effectiveStatus == 'expired' ||
                                      effectiveStatus == 'suspended'
                                  ? Icons.autorenew_rounded
                                  : (effectiveStatus == 'waiting_docs' ||
                                          effectiveStatus == 'reviewing_data'
                                      ? Icons.edit_document
                                      : Icons.lock_outline_rounded)),
                          onTap: (isActive ||
                                  effectiveStatus == 'waiting_docs' ||
                                  effectiveStatus == 'reviewing_data' ||
                                  ((effectiveStatus == 'expired' ||
                                          effectiveStatus == 'suspended') &&
                                      memberRequest != null))
                              ? () {
                                  if (isActive) {
                                    onOpenDigitalCard();
                                  } else if (effectiveStatus == 'waiting_docs' ||
                                      effectiveStatus == 'reviewing_data') {
                                    onEditPendingRequest(member, memberRequest);
                                  } else if (effectiveStatus == 'expired' ||
                                      effectiveStatus == 'suspended') {
                                    if (memberRequest != null) {
                                      onRequestRenewal(memberRequest.id);
                                    }
                                  }
                                }
                              : null,
                        ),
                    ],
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
    HomeStatusInfo statusInfo,
    String notes,
  ) {
    final color = statusInfo.color;
    final title = statusInfo.deadlineTitle ?? statusInfo.fullLabel;
    final isRejected = statusInfo.isRejected;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(statusInfo.icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
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
            if (statusInfo.deadlineMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informação importante:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusInfo.deadlineMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.cardTitle,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (notes.isNotEmpty) ...[
              Text(
                'Detalhes da equipe:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cardSubtitle.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
            ] else if (notes.isEmpty && (statusInfo.isRejected || statusInfo.showJustification) && statusInfo.deadlineMessage == null) ...[
              Text(
                'A equipe responsável ainda não adicionou detalhes específicos.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cardSubtitle.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
