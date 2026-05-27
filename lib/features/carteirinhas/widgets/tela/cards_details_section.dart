import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

import 'package:conectea/core/utils/conectea_date_time_helper.dart';

class CardsDetailsSection extends StatelessWidget {
  final DateTime validUntil;
  final bool showBack;
  final VoidCallback onToggleBack;
  final VoidCallback onOpenFullScreen;

  const CardsDetailsSection({
    super.key,
    required this.validUntil,
    required this.showBack,
    required this.onToggleBack,
    required this.onOpenFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datas e Status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIconsRegular.calendarCheck,
                  label: 'Válida até',
                  value: ConecteaDateTimeHelper.formatProjectDateShort(
                    validUntil,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIconsRegular.checkCircle,
                  label: 'Situação',
                  value: 'ATIVA',
                  isStatus: true,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Botões de Ação
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: DsBotao(
                  label: 'VER',
                  variante: DsBotaoVariante.acao,
                  token: DsCorVisual(
                    key: 'active',
                    semanticName: 'Ativa',
                    description: 'Carteirinha ativa',
                    accent: DsTokenStatus.active.primary,
                    softBackground: DsTokenStatus.active.primary.withValues(
                      alpha: 0.14,
                    ),
                    border: DsTokenStatus.active.primary.withValues(
                      alpha: 0.26,
                    ),
                    iconBackground: DsTokenStatus.active.primary.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  icon: PhosphorIconsRegular.identificationCard,
                  onPressed: onOpenFullScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DsBotao(
                  label: showBack ? 'Ver frente' : 'Ver verso',
                  variante: DsBotaoVariante.secundario,
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  onPressed: onToggleBack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBlock({
    required IconData icon,
    required String label,
    required String value,
    bool isStatus = false,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isStatus
                ? DsTokenStatus.active.primary
                : DsTokenStatus.active.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.cardSubtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isStatus
                        ? DsTokenStatus.active.primary
                        : AppColors.cardTitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
