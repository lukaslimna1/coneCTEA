import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/models/account_change_request.dart';

class AccountChangeSummaryCard extends StatelessWidget {
  final AccountChangeRequest request;
  final VoidCallback onTap;

  const AccountChangeSummaryCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = AccountChangePresentation(request);
    final visualToken = presentation.visualToken;
    final dateFormatted = ConecteaDateTimeHelper.formatProjectDateShort(
      request.createdAt,
    );

    return Semantics(
      label:
          'Solicitação de alteração de ${presentation.typeLabel}. Status: ${presentation.statusLabel}. Toque para abrir detalhes.',
      button: true,
      onTap: onTap,
      child: DsCard(
        onTap: onTap,
        showTopAccent: true,
        accentColor: visualToken.accent,
        borderColor: visualToken.border.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(DsEspacamentos.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Linha superior: Pill de Status + Chevron discreto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DsSelo.fromCorVisual(
                  label: presentation.statusLabel,
                  token: visualToken,
                  icon: presentation.statusIcon,
                  compact: true,
                ),
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
                        'Alteração de ${presentation.typeLabel}',
                        style: DsTipografia.cardTitle,
                      ),
                      const SizedBox(height: DsEspacamentos.xxs),
                      // Usar Wrap ou Column para responsividade
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Novo valor: ', style: DsTipografia.caption),
                          Text(
                            request.newValueMasked,
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
            const SizedBox(height: DsEspacamentos.md),

            // 3. Divisor sutil
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: DsEspacamentos.sm),

            // 4. Rodapé (Protocolo e Data)
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
