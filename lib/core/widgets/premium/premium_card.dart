import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/constants/design_tokens.dart';
import 'package:conectea/core/constants/text_styles.dart';

/// Card customizado com estética Premium (Glassmorphism).
/// Oferece suporte a títulos, subtítulos, gradientes e estados interativos.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final bool hasBorder;
  final bool hasGradient;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Border? borderOverride;

  const PremiumCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding,
    this.margin,
    this.radius,
    this.width,
    this.height,
    this.backgroundColor,
    this.hasBorder = true,
    this.hasGradient = false,
    this.shadow,
    this.onTap,
    this.borderOverride,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.cardSubtitle,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        child,
      ],
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        border:
            borderOverride ??
            (hasBorder
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null),
        boxShadow:
            shadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
        gradient: hasGradient ? AppColors.premiumCardGradient : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        child: Stack(
          fit: height != null ? StackFit.expand : StackFit.loose,
          children: [
            // Decoração de Fundo (apenas se houver gradiente)
            if (hasGradient)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            // Conteúdo
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
                  child: cardContent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
