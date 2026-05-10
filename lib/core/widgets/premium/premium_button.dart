import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/constants/design_tokens.dart';
import 'package:conectea/core/constants/text_styles.dart';

/// Variantes de estilo disponíveis para o PremiumButton.
enum PremiumButtonVariant { primary, secondary, outline, ghost, danger, premium, glass }

/// Botão customizado seguindo o design system Premium do ConeCTEA.
/// Suporta múltiplos estados (carregando, desabilitado) e variantes visuais.
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? colorOverride;
  final Color? textColor;
  final bool isExpanded;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 54,
    this.colorOverride,
    this.textColor,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isEnabled = onPressed != null && !isLoading;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48, // Altura mínima para alvo de toque mobile
        maxWidth: width ?? (isExpanded ? double.infinity : double.maxFinite),
      ),
      child: SizedBox(
        width: width ?? (isExpanded ? double.infinity : null),
        height: height,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isEnabled ? 1.0 : 0.6,
          child: _buildButtonBody(),
        ),
      ),
    );
  }

  Widget _buildButtonBody() {
    switch (variant) {
      case PremiumButtonVariant.premium:
        return _buildGradientButton(
          colors: AppColors.premiumGradient.colors,
        );
      case PremiumButtonVariant.primary:
        return _buildGradientButton(
          colors: colorOverride != null 
            ? [colorOverride!, colorOverride!.withValues(alpha: 0.8)] 
            : [AppColors.primary, const Color(0xFF1E3A8A)], // Azul profundo
        );
      case PremiumButtonVariant.secondary:
        return _buildSolidButton(
          color: colorOverride ?? AppColors.surfaceCard,
          textColor: textColor ?? (colorOverride != null ? Colors.white : AppColors.textPrimary),
        );
      case PremiumButtonVariant.outline:
        return _buildOutlineButton(
          color: colorOverride ?? AppColors.cyan,
          textColor: textColor,
        );
      case PremiumButtonVariant.ghost:
        return _buildGhostButton(colorOverride: colorOverride);
      case PremiumButtonVariant.danger:
        return _buildOutlineButton(color: colorOverride ?? AppColors.errorRed);
      case PremiumButtonVariant.glass:
        return _buildGlassButton();
    }
  }

  Widget _buildGradientButton({required List<Color> colors}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _buildContent(textColor ?? Colors.white),
      ),
    );
  }

  Widget _buildOutlineButton({required Color color, Color? textColor}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildContent(textColor ?? color),
    );
  }

  Widget _buildSolidButton({required Color color, required Color textColor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildContent(textColor),
    );
  }

  Widget _buildGhostButton({Color? colorOverride}) {
    final color = colorOverride ?? AppColors.cyan;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildContent(color),
    );
  }

  Widget _buildGlassButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xA60F172A), // Base Dark Glass
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: const Color(0x2E94A3B8), // Borda Glass
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            alignment: Alignment.center,
            child: _buildContent(const Color(0xFFF8FAFC)), // Cor Gelo/Branco para variante Glass
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
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
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: AppTextStyles.buttonLabel.copyWith(color: textColor),
        ),
      ],
    );
  }
}
