import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/status_action_button.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/cards/widgets/digital/digital_card_widget.dart';
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
        child: DsCard(
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
              DsBotao(
                label: 'Solicitar Carteirinha',
                onPressed: onRequestCard,
                variante: DsBotaoVariante.acao,
                token: DsCores.solicitacao,
                icon: Icons.add_circle_outline_rounded,
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

    final Color statusColor = statusInfo.color;
    final bool isActive = statusInfo.isActive;

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
                                  statusOverride: effectiveStatus,
                                ),
                              ),
                              // Selo de Status Centralizado (Horizontal Pill)
                              if (!isActive)
                                DsSeloStatus(
                                  status: effectiveStatus,
                                  shortLabel: false,
                                  uppercase: true,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Linha Técnica de Requerimento (Discreta e Copiável)
                      Builder(
                        builder: (context) {
                          final protocol = memberRequest?.protocol;
                          if (isActive ||
                              protocol == null ||
                              protocol.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: protocol),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Requerimento copiado',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 2),
                                    margin: const EdgeInsets.all(20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      protocol,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.6),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                              backgroundColor: statusColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (statusInfo.shouldShowSupport)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onSupportTap,
                            icon: Icon(
                              Icons.support_agent_rounded,
                              color: statusInfo.isSuspended
                                  ? statusColor
                                  : AppColors.errorRed,
                            ),
                            label: Text(
                              statusInfo.isSuspended
                                  ? 'Pedir revisão'
                                  : 'Falar com Suporte',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: statusInfo.isSuspended
                                    ? statusColor
                                    : AppColors.errorRed,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: statusInfo.isSuspended
                                    ? statusColor
                                    : AppColors.errorRed,
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
                              : (statusInfo.canRenew
                                    ? 'Solicitar Renovação'
                                    : (effectiveStatus == 'waiting_docs'
                                          ? 'Enviar Documentos'
                                          : (effectiveStatus == 'reviewing_data'
                                                ? 'Revisar Dados'
                                                : (statusInfo.isSuspended
                                                      ? 'Aguardando Revisão'
                                                      : 'Aguardando Aprovação')))),
                          iconOverride: isActive
                              ? Icons.qr_code_scanner_rounded
                              : (statusInfo.canRenew
                                    ? Icons.autorenew_rounded
                                    : (effectiveStatus == 'waiting_docs' ||
                                              effectiveStatus ==
                                                  'reviewing_data'
                                          ? Icons.edit_document
                                          : (statusInfo.isSuspended
                                                ? Icons.hourglass_empty_rounded
                                                : Icons.lock_outline_rounded))),
                          onTap:
                              (isActive ||
                                  effectiveStatus == 'waiting_docs' ||
                                  effectiveStatus == 'reviewing_data' ||
                                  (statusInfo.canRenew &&
                                      memberRequest != null))
                              ? () {
                                  if (isActive) {
                                    onOpenDigitalCard();
                                  } else if (effectiveStatus ==
                                          'waiting_docs' ||
                                      effectiveStatus == 'reviewing_data') {
                                    onEditPendingRequest(member, memberRequest);
                                  } else if (statusInfo.canRenew) {
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
    DsStatusDialog.show(context, statusInfo: statusInfo, notes: notes);
  }
}
