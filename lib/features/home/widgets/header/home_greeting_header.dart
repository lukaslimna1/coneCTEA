import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeGreetingHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback onQrTap;

  const HomeGreetingHeader({
    super.key,
    required this.displayName,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $displayName!',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cardTitle,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Que bom te ver por aqui.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardSubtitle,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onQrTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: const Icon(
                PhosphorIconsBold.qrCode,
                color: AppColors.cardTitle,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
