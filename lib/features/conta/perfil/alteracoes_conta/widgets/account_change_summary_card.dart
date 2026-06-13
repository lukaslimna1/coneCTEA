import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/models/account_change_request.dart';

class AccountChangeSummaryCard extends StatelessWidget {
  final AccountChangeRequest request;

  const AccountChangeSummaryCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final presentation = AccountChangePresentation(request);
    final visualToken = presentation.visualToken;
    final dateFormatted = ConecteaDateTimeHelper.formatProjectDateShort(
      request.createdAt,
    );

    return DsCard(
      borderColor: visualToken.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Badge de Status (comunicando por texto, ícone e cor semântica)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: visualToken.softBackground,
              borderRadius: BorderRadius.circular(DsRaios.xs),
              border: Border.all(color: visualToken.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  presentation.statusIcon,
                  size: 12,
                  color: visualToken.accent,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    presentation.statusLabel.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DsTipografia.label.copyWith(
                      color: visualToken.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Tipo da Alteração
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DsMolduraIcone(
                icon: presentation.typeIcon,
                accentColor: visualToken.accent,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alteração de ${presentation.typeLabel}',
                      style: DsTipografia.cardTitle.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Usar Wrap ou Column para o valor mascarado não estourar em 360dp
                    Wrap(
                      children: [
                        Text(
                          'Novo valor: ',
                          style: DsTipografia.bodySmall.copyWith(
                            color: DsCores.textSecondary,
                          ),
                        ),
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
          const SizedBox(height: 16),

          // 3. Divisor sutil
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),

          // 4. Rodapé do Card (Protocolo e Data)
          // Usado Wrap para total responsividade caso a fonte esteja muito ampliada
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Protocolo: ${request.protocolNumber}',
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Solicitado em $dateFormatted',
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
