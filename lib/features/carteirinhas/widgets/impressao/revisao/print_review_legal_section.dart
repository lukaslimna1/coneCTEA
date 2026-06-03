import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintReviewLegalSection**
/// Renderiza apenas os avisos legais/privacidade finais da revisão.
class PrintReviewLegalSection extends StatelessWidget {
  const PrintReviewLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DsCard(
      backgroundColor: DsCores.privacidade.softBackground.withValues(alpha: 0.06),
      borderColor: DsCores.privacidade.border.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.shieldCheck,
                color: DsCores.privacidade.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O PDF será gerado no aparelho. Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
