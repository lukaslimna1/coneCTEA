import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';

class CardsEmptyState extends StatelessWidget {
  final VoidCallback onAddMember;

  const CardsEmptyState({super.key, required this.onAddMember});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.identificationCard,
              size: 72,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma carteira emitida',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cadastre um membro e envie a documentação\npara receber sua identificação digital.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.cardSubtitle,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: PremiumButton(
              text: 'Cadastrar membro',
              onPressed: onAddMember,
              icon: PhosphorIconsRegular.plusCircle,
            ),
          ),
        ],
      ),
    );
  }
}
