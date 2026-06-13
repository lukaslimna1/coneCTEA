import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class AccountChangeValueDelta extends StatelessWidget {
  final String? oldValueMasked;
  final String newValueMasked;
  final DsCorVisual statusToken;
  final bool isCompleted;

  const AccountChangeValueDelta({
    super.key,
    this.oldValueMasked,
    required this.newValueMasked,
    required this.statusToken,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final hasOldValue =
        oldValueMasked != null && oldValueMasked!.trim().isNotEmpty;
    // O bloco "Depois" recebe a intenção de sucesso se concluído, ou do status se pendente.
    final targetToken = isCompleted ? DsCores.sucesso : statusToken;

    return DsCard(
      borderColor: DsCores.border.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(DsEspacamentos.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alteração solicitada', style: DsTipografia.cardTitle),
          const SizedBox(height: DsEspacamentos.md),

          // Seção ANTES
          if (hasOldValue) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANTES',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  oldValueMasked!,
                  style: DsTipografia.bodySmall.copyWith(
                    color: DsCores.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsEspacamentos.sm),

            // Indicador de transição vertical
            Center(
              child: Icon(
                PhosphorIconsRegular.arrowDown,
                color: DsCores.textMuted.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
            const SizedBox(height: DsEspacamentos.sm),
          ],

          // Seção DEPOIS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DsEspacamentos.sm),
            decoration: BoxDecoration(
              color: targetToken.softBackground,
              borderRadius: BorderRadius.circular(DsRaios.sm),
              border: Border.all(color: targetToken.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEPOIS',
                  style: DsTipografia.caption.copyWith(
                    color: targetToken.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    Text(
                      newValueMasked,
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
