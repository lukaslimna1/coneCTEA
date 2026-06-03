import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintReviewEmptyWarningBox**
/// Widget stateless local da funcionalidade de revisão de impressão.
/// Renderiza o aviso de informação não preenchida, suportando estilo plano
/// ou com container de alerta, além de um widget interno (child) opcional.
class PrintReviewEmptyWarningBox extends StatelessWidget {
  final String message;
  final String? helperText;
  final Widget? child;
  final bool isContainer;

  const PrintReviewEmptyWarningBox({
    super.key,
    required this.message,
    this.helperText,
    this.child,
    this.isContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isContainer) {
      return Container(
        margin: const EdgeInsets.only(top: 6.0, bottom: 12.0, left: 4.0, right: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: DsCores.alerta.softBackground.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DsRaios.card - 2),
          border: Border.all(
            color: DsCores.alerta.border.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: DsCores.alerta.accent,
              size: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.alerta.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (helperText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      helperText!,
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 4.0, right: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: DsCores.alerta.accent,
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 10),
            child!,
          ],
        ],
      ),
    );
  }
}
