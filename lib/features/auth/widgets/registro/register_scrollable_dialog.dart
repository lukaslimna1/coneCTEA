import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';

class RegisterScrollableDialog extends StatelessWidget {
  final String title;
  final String content;

  const RegisterScrollableDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isTerms = title.contains('Termos');
    return AlertDialog(
      backgroundColor: const Color(0xFF0C2445),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Icon(
            isTerms ? PhosphorIcons.fileText() : PhosphorIcons.shieldCheck(),
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            text: 'Compreendido',
            onPressed: () => Navigator.pop(context),
            icon: PhosphorIcons.check(),
          ),
        ),
      ],
    );
  }
}
