import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tokens_visuais.dart';

/// Selo genérico oficial do Design System V2 do ConeCTEA.
///
/// Usado para tags e categorias secundárias, como:
/// - Em breve;
/// - Protegido;
/// - Novo;
/// - Beta;
/// - Restrito;
/// - Admin Dev.
///
/// Importante:
/// Este componente NÃO deve representar status de carteirinha ou solicitação.
/// Status terão componente próprio no futuro, baseado em DsTokenStatus.
class DsSelo extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData? icon;
  final Color? iconColor;
  final bool compact;
  final bool uppercase;
  final double borderWidth;
  final double? maxWidth;

  const DsSelo({
    super.key,
    required this.label,
    required this.labelColor,
    required this.backgroundColor,
    required this.borderColor,
    this.icon,
    this.iconColor,
    this.compact = false,
    this.uppercase = true,
    this.borderWidth = 1.0,
    this.maxWidth,
  }) : assert(borderWidth >= 0);

  /// Cria um selo genérico usando as definições semânticas de um [DsTokenVisual].
  ///
  /// Não usar este construtor para status de carteirinha/solicitação.
  DsSelo.fromTokenVisual({
    super.key,
    required this.label,
    required DsTokenVisual token,
    this.icon,
    this.iconColor,
    this.compact = false,
    this.uppercase = true,
    this.borderWidth = 1.0,
    this.maxWidth,
  })  : labelColor = token.accent,
        backgroundColor = token.softBackground,
        borderColor = token.border,
        assert(borderWidth >= 0);

  @override
  Widget build(BuildContext context) {
    final verticalPadding = compact ? 3.0 : 6.0;
    final horizontalPadding = compact ? DsEspacamentos.sm : DsEspacamentos.md;
    final effectiveIconSize = compact ? 12.0 : 14.0;
    final effectiveIconColor = iconColor ?? labelColor;
    final effectiveLabel = uppercase ? label.toUpperCase() : label;

    final textStyle = DsTipografia.bodySmall.copyWith(
      color: labelColor,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 10 : 12,
      height: 1.1,
    );

    final labelWidget = Text(
      effectiveLabel,
      style: textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      softWrap: false,
    );

    final content = Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DsRaios.pill),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: effectiveIconSize,
              color: effectiveIconColor,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          if (maxWidth == null) labelWidget else Flexible(child: labelWidget),
        ],
      ),
    );

    if (maxWidth == null) {
      return content;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: content,
    );
  }
}
