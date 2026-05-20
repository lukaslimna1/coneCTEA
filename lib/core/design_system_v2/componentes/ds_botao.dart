import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

enum DsBotaoVariante { primario, secundario, ghost, contorno, perigo }

/// Botão oficial do Design System V2 do ConeCTEA.
/// 
/// A API pública segue convenções Flutter/Dart.
/// A identidade visual segue a nomenclatura e tokens da DS V2.
class DsBotao extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DsBotaoVariante variante;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  const DsBotao({
    super.key,
    required this.label,
    this.onPressed,
    this.variante = DsBotaoVariante.primario,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = DsTamanhos.buttonHeight,
  });

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: _isEnabled ? 1.0 : 0.55,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.backgroundColor,
              gradient: style.gradient,
              borderRadius: BorderRadius.circular(DsRaios.button),
              border: Border.all(
                color: style.borderColor,
                width: style.borderWidth,
              ),
              boxShadow: style.shadows,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(DsRaios.button),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _isEnabled ? onPressed : null,
                borderRadius: BorderRadius.circular(DsRaios.button),
                splashColor: style.textColor.withValues(alpha: 0.10),
                highlightColor: style.textColor.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsEspacamentos.lg,
                  ),
                  child: Center(
                    child: _buildContent(style.textColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _DsBotaoStyle _resolveStyle() {
    switch (variante) {
      case DsBotaoVariante.primario:
        return _DsBotaoStyle(
          gradient: DsCores.primaryGradient,
          textColor: Colors.white,
          borderColor: Colors.white.withValues(alpha: 0.15),
          borderWidth: 1,
          shadows: DsSombras.glow(
            DsCores.primary,
            alpha: 0.18,
            blurRadius: 16,
          ),
        );

      case DsBotaoVariante.secundario:
        return _DsBotaoStyle(
          backgroundColor: DsCores.surfaceElevated,
          textColor: DsCores.textPrimary,
          borderColor: Colors.white.withValues(alpha: 0.08),
          borderWidth: 1,
        );

      case DsBotaoVariante.ghost:
        return _DsBotaoStyle(
          backgroundColor: Colors.transparent,
          textColor: DsCores.cyan,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );

      case DsBotaoVariante.contorno:
        return _DsBotaoStyle(
          backgroundColor: DsCores.cyan.withValues(alpha: 0.05),
          textColor: DsCores.cyan,
          borderColor: DsCores.cyan.withValues(alpha: 0.70),
          borderWidth: 1.4,
        );

      case DsBotaoVariante.perigo:
        return _DsBotaoStyle(
          backgroundColor: DsCores.danger.withValues(alpha: 0.08),
          textColor: DsCores.danger,
          borderColor: DsCores.danger.withValues(alpha: 0.55),
          borderWidth: 1.4,
        );
    }
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: DsTamanhos.iconSm,
        width: DsTamanhos.iconSm,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: DsTamanhos.iconSm, color: textColor),
          const SizedBox(width: DsEspacamentos.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: DsTipografia.button.copyWith(color: textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _DsBotaoStyle {
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const _DsBotaoStyle({
    this.backgroundColor,
    this.gradient,
    required this.textColor,
    required this.borderColor,
    required this.borderWidth,
    this.shadows,
  });
}
