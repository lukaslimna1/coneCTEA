import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/carteirinhas/solicitacao/dependent_cpf_change_presentation.dart';
import 'package:conectea/models/dependent_cpf_change_request.dart';

class DependentCpfChangeSummaryCard extends StatelessWidget {
  final DependentCpfChangeRequest request;
  final VoidCallback onTap;

  const DependentCpfChangeSummaryCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = DependentCpfChangePresentation(request);
    final visualToken = presentation.visualToken;
    final dateFormatted = ConecteaDateTimeHelper.formatProjectDateShort(
      request.createdAt,
    );

    final String semanticaLabel;
    if (presentation.canShowDeadline && request.expiresAt != null) {
      final date = request.expiresAt!;
      final meses = [
        'janeiro',
        'fevereiro',
        'março',
        'abril',
        'maio',
        'junho',
        'julho',
        'agosto',
        'setembro',
        'outubro',
        'novembro',
        'dezembro',
      ];
      final mesExtenso = date.month >= 1 && date.month <= 12
          ? meses[date.month - 1]
          : date.month.toString();
      final prazoFalado =
          'Prazo para sua ação até ${date.day} de $mesExtenso de ${date.year}';
      semanticaLabel =
          'Solicitação de alteração de CPF do dependente. Status: ${presentation.statusLabel}. $prazoFalado. Toque para abrir detalhes.';
    } else {
      semanticaLabel =
          'Solicitação de alteração de CPF do dependente. Status: ${presentation.statusLabel}. Toque para abrir detalhes.';
    }

    return Semantics(
      container: true,
      button: true,
      label: semanticaLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: DsCard(
          onTap: onTap,
          showTopAccent: true,
          accentColor: visualToken.accent,
          borderColor: visualToken.border.withValues(alpha: 0.15),
          padding: const EdgeInsets.all(DsEspacamentos.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final seloMaxWidth =
                  constraints.maxWidth - DsEspacamentos.md - 16;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Linha superior: Pill de Status + Chevron discreto
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DsSelo.fromCorVisual(
                            label: presentation.statusLabel,
                            token: visualToken,
                            icon: presentation.statusIcon,
                            compact: true,
                            maxWidth: seloMaxWidth,
                          ),
                        ),
                      ),
                      const SizedBox(width: DsEspacamentos.md),
                      Icon(
                        PhosphorIconsRegular.caretRight,
                        color: DsCores.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: DsEspacamentos.md),

                  // 2. Tipo da Alteração (Moldura + Título forte)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DsMolduraIcone(
                        icon: presentation.typeIcon,
                        accentColor: visualToken.accent,
                        size: DsTamanhos.iconFrameSm,
                        iconSize: DsTamanhos.iconSm,
                      ),
                      const SizedBox(width: DsEspacamentos.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alteração de CPF do dependente',
                              style: DsTipografia.cardTitle,
                            ),
                            const SizedBox(height: DsEspacamentos.xxs),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'CPF solicitado: ',
                                  style: DsTipografia.caption,
                                ),
                                Text(
                                  request.requestedCpfMasked ?? '***.***.***-XX',
                                  style: DsTipografia.bodySmall.copyWith(
                                    color: DsCores.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. Aviso de prazo (quando aplicável)
                  if (presentation.canShowDeadline) ...[
                    const SizedBox(height: DsEspacamentos.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DsEspacamentos.sm,
                        vertical: DsEspacamentos.xs,
                      ),
                      decoration: BoxDecoration(
                        color: visualToken.softBackground,
                        border: Border.all(
                          color: visualToken.border.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(DsRaios.xs),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.calendarBlank,
                            color: visualToken.accent,
                            size: 16,
                          ),
                          const SizedBox(width: DsEspacamentos.xs),
                          Expanded(
                            child: Text(
                              presentation.deadlineText ?? '',
                              style: DsTipografia.bodySmall.copyWith(
                                color: DsCores.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: DsEspacamentos.md),

                  // 4. Divisor sutil
                  Divider(
                    color: Colors.white.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  const SizedBox(height: DsEspacamentos.sm),

                  // 5. Rodapé (Protocolo, Data da Solicitação e Data de Encerramento)
                  Wrap(
                    spacing: DsEspacamentos.md,
                    runSpacing: DsEspacamentos.xs,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Protocolo: ${request.protocolNumber}',
                        style: DsTipografia.caption,
                      ),
                      Text(
                        'Solicitado em $dateFormatted',
                        style: DsTipografia.caption,
                      ),
                      if (presentation.canShowClosedAt &&
                          presentation.closedAtText != null)
                        Text(
                          presentation.closedAtText!,
                          style: DsTipografia.caption.copyWith(
                            color: DsCores.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
