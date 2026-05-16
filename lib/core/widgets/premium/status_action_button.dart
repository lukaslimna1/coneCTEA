import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

/// Um botão premium com estética "Dark Glass" que consome os tokens de status.
/// Ideal para ações administrativas ou ações do usuário vinculadas a um status específico.
class StatusActionButton extends StatelessWidget {
  final String label;
  final String statusKey;
  final VoidCallback? onTap;
  final IconData? iconOverride;
  final bool isLoading;
  final double? width;
  final double height;
  final bool isExpanded;
  final double fontSize;
  final double iconSize;
  final EdgeInsets? padding;

  const StatusActionButton({
    super.key,
    required this.label,
    required this.statusKey,
    this.onTap,
    this.iconOverride,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.isExpanded = false,
    this.fontSize = 11,
    this.iconSize = 18,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = StatusVisualTokens.fromStatus(statusKey);
    final icon = iconOverride ?? tokens.icon;
    final bool isEnabled = onTap != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 32,
          maxWidth: width ?? (isExpanded ? double.infinity : double.maxFinite),
        ),
        child: SizedBox(
          width: width ?? (isExpanded ? double.infinity : null),
          height: height,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 3),
              boxShadow: [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onTap : null,
                borderRadius: BorderRadius.circular(height / 3),
                child: Container(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(height / 3),
                    border: Border.all(
                      color: tokens.pillBorder.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            height: iconSize,
                            width: iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: iconSize,
                                color: tokens.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  label.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w900,
                                    color: tokens.primary,
                                    letterSpacing: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
