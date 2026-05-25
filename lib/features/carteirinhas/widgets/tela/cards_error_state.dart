import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';

class CardsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const CardsErrorState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone de erro estilizado
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.alertOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.alertOrange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                PhosphorIconsRegular.warningCircle,
                color: AppColors.alertOrange,
                size: 64,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Título
            Text(
              'Não foi possível carregar suas carteirinhas',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Descrição
            Text(
              'Verifique sua conexão e tente novamente em instantes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.cardSubtitle,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botão de ação
            SizedBox(
              width: 200,
              child: PremiumButton(
                text: 'Tentar novamente',
                variant: PremiumButtonVariant.primary,
                icon: PhosphorIconsRegular.arrowsClockwise,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
