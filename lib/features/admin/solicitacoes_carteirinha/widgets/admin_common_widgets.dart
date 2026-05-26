import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';
import 'package:conectea/core/widgets/premium/status_action_button.dart';

class AdminSectionTitle extends StatelessWidget {
  final String title;
  const AdminSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class AdminDetailRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isSensitive;
  final Widget? customValue;

  const AdminDetailRow({
    super.key, 
    required this.label, 
    this.value = '',
    this.isSensitive = false,
    this.customValue,
  });

  @override
  State<AdminDetailRow> createState() => _AdminDetailRowState();
}

class _AdminDetailRowState extends State<AdminDetailRow> {
  bool _showValue = false;

  @override
  Widget build(BuildContext context) {
    String displayedValue = widget.value;
    if (widget.isSensitive && !_showValue) {
      // Mascaramento simples: 123.***.***-45
      if (widget.value.length >= 11) {
        final digits = widget.value.replaceAll(RegExp(r'\D'), '');
        if (digits.length == 11) {
          displayedValue = '${digits.substring(0, 3)}.***.***-${digits.substring(9)}';
        } else {
          displayedValue = '***.***.***-**';
        }
      } else {
        displayedValue = '********';
      }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrowScreen = screenWidth < 380;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: isNarrowScreen ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          widget.customValue ?? Row(
            children: [
              Expanded(
                child: Text(
                  displayedValue,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.isSensitive) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showValue ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                    color: ConecteaVisualTokens.privacidade.accent,
                  ),
                  onPressed: () => setState(() => _showValue = !_showValue),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AdminDocumentLink extends StatelessWidget {
  final String label;
  final String url;
  final IconData iconData;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const AdminDocumentLink({
    super.key,
    required this.label,
    required this.url,
    required this.iconData,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = url.isNotEmpty && url.startsWith('http');
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrowScreen = screenWidth < 380;
    final docColor = StatusVisualTokens.fromStatus('waiting_docs').primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasUrl
            ? docColor.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUrl
              ? docColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: hasUrl ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isNarrowScreen ? 10 : 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasUrl
                      ? docColor.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: hasUrl ? docColor : AppColors.textSecondary.withValues(alpha: 0.4),
                  size: isNarrowScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isNarrowScreen ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasUrl ? 'Toque para visualizar arquivo' : 'Não enviado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: hasUrl ? docColor : AppColors.textSecondary.withValues(alpha: 0.6),
                        fontWeight: hasUrl ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUrl) ...[
                if (onDelete != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: isNarrowScreen ? 8 : 12),
                ],
                Icon(
                  Icons.arrow_forward_ios,
                  color: docColor,
                  size: isNarrowScreen ? 14 : 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String status;
  final String label;
  final bool isCurrent;
  final VoidCallback onTap;

  const AdminStatusChip({
    super.key,
    required this.status,
    required this.label,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = StatusVisualTokens.fromStatus(status);

    return GestureDetector(
      onTap: isCurrent ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF020617).withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? tokens.pillBorder : tokens.primary.withValues(alpha: 0.2),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: tokens.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (isCurrent)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.pillBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent) ...[
                  Icon(tokens.icon, size: 14, color: tokens.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isCurrent
                        ? tokens.primary
                        : Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminRoleChip extends StatelessWidget {
  final bool isAdmin;
  const AdminRoleChip({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final color = isAdmin ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'USUÁRIO',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class AdminActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isOutline;

  const AdminActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumButton(
      text: label,
      icon: icon,
      colorOverride: color,
      variant: isOutline ? PremiumButtonVariant.outline : PremiumButtonVariant.primary,
      onPressed: onTap,
      height: 48,
      isExpanded: false,
    );
  }
}

class AdminStatusActionButton extends StatelessWidget {
  final String label;
  final String statusKey;
  final VoidCallback onTap;
  final IconData? iconOverride;

  const AdminStatusActionButton({
    super.key,
    required this.label,
    required this.statusKey,
    required this.onTap,
    this.iconOverride,
  });

  @override
  Widget build(BuildContext context) {
    return StatusActionButton(
      label: label,
      statusKey: statusKey,
      onTap: onTap,
      iconOverride: iconOverride,
    );
  }
}

