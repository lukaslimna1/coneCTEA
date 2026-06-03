import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintReviewPreviewBox**
/// Widget stateless local da funcionalidade de revisão de impressão.
/// Renderiza a caixa visual que indica o valor selecionado/calculado a ser impresso.
class PrintReviewPreviewBox extends StatelessWidget {
  final String value;
  final IconData icon;
  final String label;

  const PrintReviewPreviewBox({
    super.key,
    required this.value,
    this.icon = Icons.check_circle_outline_rounded,
    this.label = 'Será impresso:',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6.0, bottom: 12.0, left: 4.0, right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: DsCores.carteirinha.softBackground.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DsRaios.card - 2),
        border: Border.all(
          color: DsCores.carteirinha.border.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: DsCores.carteirinha.accent,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: DsTipografia.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
