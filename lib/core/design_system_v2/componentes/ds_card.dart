import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';

/// Card base oficial do Design System V2 do ConeCTEA.
///
/// Define a casca visual premium dos cards:
/// - corpo Dark Glass / Night Blue neutro;
/// - borda translúcida;
/// - radius consistente;
/// - sombra escura sutil;
/// - gradiente neutro opcional;
/// - acento superior opcional;
/// - glow semântico opcional.
///
/// A cor semântica nunca deve pintar o corpo inteiro do card.
/// Ela deve aparecer apenas em detalhes controlados.
class DsCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showTopAccent;
  final bool showGlow;
  final bool hasGradient;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final double borderWidth;
  final double topAccentHeight;

  const DsCard({
    super.key,
    required this.child,
    this.accentColor,
    this.backgroundColor,
    this.borderColor,
    this.showTopAccent = false,
    this.showGlow = false,
    this.hasGradient = false,
    this.onTap,
    this.padding,
    this.margin,
    this.radius,
    this.borderWidth = 1.0,
    this.topAccentHeight = 3.0,
  })  : assert(borderWidth >= 0),
        assert(topAccentHeight >= 0);

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? DsRaios.card;
    final effectiveAccent = accentColor ?? DsCores.carteirinha.accent;
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: 0.08);

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ?? DsCores.glass,
          gradient: hasGradient ? DsCores.cardGradient : null,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: Border.all(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
          boxShadow: [
            ...DsSombras.card,
            if (showGlow && accentColor != null)
              ...DsSombras.semanticGlow(accentColor!),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Stack(
            children: [
              if (showTopAccent && accentColor != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: topAccentHeight,
                    color: accentColor,
                  ),
                ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(effectiveRadius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(effectiveRadius),
                  splashColor: effectiveAccent.withValues(alpha: 0.10),
                  highlightColor: effectiveAccent.withValues(alpha: 0.06),
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(DsEspacamentos.lg),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
