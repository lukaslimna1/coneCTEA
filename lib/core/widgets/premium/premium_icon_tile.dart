import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';

/// Tamanhos pré-definidos para o PremiumIconTile.
enum PremiumIconSize { small, medium, large, hero }

/// Widget de ícone encapsulado em um container estilizado com o design system.
/// Utilizado em listas, cards e cabeçalhos.
class PremiumIconTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final PremiumIconSize size;
  final double? customSize;

  const PremiumIconTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = PremiumIconSize.medium,
    this.customSize,
  });

  @override
  Widget build(BuildContext context) {
    double containerSize;
    double iconSize;
    double borderRadius;

    switch (size) {
      case PremiumIconSize.small:
        containerSize = 40;
        iconSize = 20;
        borderRadius = 12;
        break;
      case PremiumIconSize.medium:
        containerSize = 48;
        iconSize = 24;
        borderRadius = 16;
        break;
      case PremiumIconSize.large:
        containerSize = 56;
        iconSize = 28;
        borderRadius = 20;
        break;
      case PremiumIconSize.hero:
        containerSize = 72;
        iconSize = 36;
        borderRadius = 24;
        break;
    }

    if (customSize != null) {
      containerSize = customSize!;
      iconSize = containerSize * 0.5;
    }

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.purpleIconBg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: iconSize,
        ),
      ),
    );
  }
}
