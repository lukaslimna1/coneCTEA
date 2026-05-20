import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

/// Componente oficial da DS V2 para o botão "Voltar".
///
/// Criado como um selo/cápsula horizontal que agrupa ícone e texto na mesma peça.
/// Utiliza por padrão a intenção de cor [DsCores.conta] e o ícone [PhosphorIconsRegular.caretLeft].
class DsBotaoVoltar extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final DsCorVisual? token;
  final bool enabled;
  final EdgeInsetsGeometry? margin;
  final String? semanticsLabel;

  const DsBotaoVoltar({
    super.key,
    this.onPressed,
    this.label = 'Voltar',
    this.icon,
    this.token,
    this.enabled = true,
    this.margin,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEffectivelyEnabled = enabled && onPressed != null;
    final effectiveToken = token ?? DsCores.conta;

    // Fundo dark glass/fumê
    final effectiveBackground = DsCores.iconFrameBackground.withValues(alpha: 0.70);
    // Borda com cor de intenção
    final effectiveBorder = effectiveToken.accent.withValues(alpha: 0.40);

    final effectiveIconColor = isEffectivelyEnabled
        ? effectiveToken.accent
        : DsCores.textMuted.withValues(alpha: 0.5);

    final effectiveTextColor = isEffectivelyEnabled
        ? Colors.white
        : DsCores.textMuted.withValues(alpha: 0.5);

    final effectiveIcon = icon ?? PhosphorIconsRegular.caretLeft;

    Widget buttonContent = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: DsEspacamentos.md),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: effectiveBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            effectiveIcon,
            color: effectiveIconColor,
            size: DsTamanhos.iconSm,
          ),
          const SizedBox(width: DsEspacamentos.sm),
          Text(
            label,
            style: DsTipografia.body.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );

    Widget result = Semantics(
      label: semanticsLabel ?? label,
      button: true,
      enabled: isEffectivelyEnabled,
      child: GestureDetector(
        onTap: isEffectivelyEnabled ? onPressed : null,
        child: buttonContent,
      ),
    );

    if (margin != null) {
      result = Padding(
        padding: margin!,
        child: result,
      );
    }

    return result;
  }
}
