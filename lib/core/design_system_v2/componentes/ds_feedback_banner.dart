import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

enum DsFeedbackTipo {
  sucesso,
  erro,
  alerta,
  info,
}

class DsFeedbackBanner extends StatelessWidget {
  final String mensagem;
  final String? titulo;
  final DsFeedbackTipo tipo;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry padding;

  const DsFeedbackBanner({
    super.key,
    required this.mensagem,
    this.titulo,
    this.tipo = DsFeedbackTipo.info,
    this.onDismiss,
    this.padding = const EdgeInsets.only(bottom: DsEspacamentos.md),
  });

  DsCorVisual get _tokenColor {
    switch (tipo) {
      case DsFeedbackTipo.sucesso:
        return DsCores.sucesso;
      case DsFeedbackTipo.erro:
        return DsCores.perigo;
      case DsFeedbackTipo.alerta:
        return DsCores.alerta;
      case DsFeedbackTipo.info:
        return DsCores.conta;
    }
  }

  IconData get _iconData {
    switch (tipo) {
      case DsFeedbackTipo.sucesso:
        return PhosphorIconsFill.checkCircle;
      case DsFeedbackTipo.erro:
        return PhosphorIconsFill.xCircle;
      case DsFeedbackTipo.alerta:
        return PhosphorIconsFill.warningCircle;
      case DsFeedbackTipo.info:
        return PhosphorIconsFill.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = _tokenColor;

    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRaios.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(DsEspacamentos.md),
            decoration: BoxDecoration(
              color: DsCores.glassStrong,
              borderRadius: BorderRadius.circular(DsRaios.card),
              border: Border.all(
                color: token.accent.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: token.accent.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconData,
                  color: token.accent,
                  size: DsTamanhos.iconMd,
                ),
                const SizedBox(width: DsEspacamentos.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (titulo != null && titulo!.isNotEmpty) ...[
                        Text(
                          titulo!,
                          style: DsTipografia.body.copyWith(
                            color: DsCores.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        mensagem,
                        style: DsTipografia.body.copyWith(
                          color: DsCores.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: DsEspacamentos.sm),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(DsRaios.pill),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          PhosphorIconsRegular.x,
                          size: DsTamanhos.iconSm,
                          color: DsCores.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DsFeedback {
  static void showSnackBar({
    required BuildContext context,
    required String mensagem,
    String? titulo,
    DsFeedbackTipo tipo = DsFeedbackTipo.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: DsFeedbackBanner(
          mensagem: mensagem,
          titulo: titulo,
          tipo: tipo,
          padding: EdgeInsets.zero,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: duration,
      ),
    );
  }
}

