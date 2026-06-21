import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:conectea/core/design_system_v2/componentes/ds_botao.dart';
import 'package:conectea/core/design_system_v2/componentes/ds_card.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';

import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

class DsDialogAction<T> {
  final String label;
  final T? value;
  final DsBotaoVariante variante;
  final DsCorVisual? token;

  const DsDialogAction({
    required this.label,
    this.value,
    this.variante = DsBotaoVariante.primario,
    this.token,
  });
}

class DsDialog<T> extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final DsCorVisual token;
  final DsDialogAction<T> primaryAction;
  final DsDialogAction<T>? secondaryAction;

  const DsDialog({
    super.key,
    required this.title,
    required this.description,
    required this.token,
    required this.primaryAction,
    this.secondaryAction,
    this.icon,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String description,
    required DsCorVisual token,
    required DsDialogAction<T> primaryAction,
    DsDialogAction<T>? secondaryAction,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DsDialog<T>(
                title: title,
                description: description,
                token: token,
                icon: icon,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(24),
      borderColor: token.border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: token.accent, size: 40),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                description,
                style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 280 && secondaryAction != null) {
                // Empilhar botões verticalmente em telas muito pequenas
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DsBotao(
                      label: primaryAction.label,
                      onPressed: () => Navigator.of(context).pop(primaryAction.value),
                      variante: primaryAction.variante,
                      token: primaryAction.token ?? token,
                    ),
                    const SizedBox(height: 12),
                    DsBotao(
                      label: secondaryAction!.label,
                      onPressed: () => Navigator.of(context).pop(secondaryAction!.value),
                      variante: secondaryAction!.variante,
                      token: secondaryAction!.token ?? token,
                    ),
                  ],
                );
              }

              // Lado a lado em telas normais (360dp é suficiente para lado a lado)
              return Row(
                children: [
                  if (secondaryAction != null) ...[
                    Expanded(
                      child: DsBotao(
                        label: secondaryAction!.label,
                        onPressed: () => Navigator.of(context).pop(secondaryAction!.value),
                        variante: secondaryAction!.variante,
                        token: secondaryAction!.token ?? token,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: DsBotao(
                      label: primaryAction.label,
                      onPressed: () => Navigator.of(context).pop(primaryAction.value),
                      variante: primaryAction.variante,
                      token: primaryAction.token ?? token,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
