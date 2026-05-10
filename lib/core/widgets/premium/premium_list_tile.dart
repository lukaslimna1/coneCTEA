import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/constants/design_tokens.dart';
import 'package:conectea/core/constants/text_styles.dart';
import 'package:conectea/core/widgets/premium/premium_icon_tile.dart';

/// Item de lista padronizado com o design system Premium.
/// Combina um PremiumIconTile com textos de título/subtítulo e ações.
class PremiumListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final Color? titleColor;

  const PremiumListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              PremiumIconTile(
                icon: icon,
                iconColor: iconColor,
                backgroundColor: iconBackgroundColor,
                size: PremiumIconSize.medium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 16,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.cardMuted,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron)
                const Icon(
                  PhosphorIconsRegular.caretRight,
                  color: AppColors.iconMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
