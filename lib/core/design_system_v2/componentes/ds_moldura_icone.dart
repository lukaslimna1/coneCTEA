import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';

/// Moldura oficial de ícone do Design System V2 do ConeCTEA.
///
/// Define o padrão visual para ícones destacados:
/// - fundo suave baseado na cor semântica;
/// - borda opcional;
/// - radius consistente;
/// - glow sutil opcional;
/// - tamanho controlado;
/// - cor do ícone configurável.
///
/// A feature escolhe o ícone e a cor semântica.
/// O Design System controla a moldura.
class DsMolduraIcone extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double? iconSize;
  final double? radius;
  final bool showBorder;
  final bool subtleGlow;
  final double borderWidth;
  final String? semanticsLabel;

  const DsMolduraIcone({
    super.key,
    required this.icon,
    required this.accentColor,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = DsTamanhos.iconFrameMd,
    this.iconSize,
    this.radius,
    this.showBorder = true,
    this.subtleGlow = false,
    this.borderWidth = 1.5,
    this.semanticsLabel,
  })  : assert(size > 0),
        assert(iconSize == null || iconSize > 0),
        assert(borderWidth >= 0);

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? DsRaios.md;
    final effectiveIconSize = iconSize ?? DsTamanhos.iconMd;
    final effectiveIconColor = iconColor ?? accentColor;
    final effectiveBackground =
        backgroundColor ?? DsCores.iconFrameBackground.withValues(alpha: 0.75);
    final effectiveBorder =
        borderColor ?? accentColor.withValues(alpha: 0.45);

    return Semantics(
      label: semanticsLabel,
      image: semanticsLabel != null,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: showBorder
                ? Border.all(
                    color: effectiveBorder,
                    width: borderWidth,
                  )
                : null,
            boxShadow: [
              if (subtleGlow)
                ...DsSombras.glow(
                  accentColor,
                  alpha: 0.12,
                  blurRadius: 10,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: effectiveIconSize,
            ),
          ),
        ),
      ),
    );
  }
}
