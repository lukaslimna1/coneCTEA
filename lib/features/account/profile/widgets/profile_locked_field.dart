import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

class ProfileLockedField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alwaysLocked;
  final VoidCallback? onTap;

  const ProfileLockedField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.alwaysLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (alwaysLocked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Alterar via Suporte',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.alertOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.alertOrange),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
