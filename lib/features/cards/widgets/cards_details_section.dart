import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';

class CardsDetailsSection extends StatelessWidget {
  final DateTime validUntil;
  final bool showBack;
  final VoidCallback onToggleBack;
  final VoidCallback onOpenFullScreen;
  final VoidCallback onAddDependent;

  const CardsDetailsSection({
    super.key,
    required this.validUntil,
    required this.showBack,
    required this.onToggleBack,
    required this.onOpenFullScreen,
    required this.onAddDependent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datas e Status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIconsRegular.calendarCheck,
                  label: 'Válida até',
                  value: DateFormat('dd/MM/yyyy').format(validUntil),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBlock(
                  icon: PhosphorIconsRegular.checkCircle,
                  label: 'Situação',
                  value: 'ATIVA',
                  isStatus: true,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Botões de Ação
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: PremiumButton(
                  text: 'Ver carteirinha',
                  variant: PremiumButtonVariant.primary,
                  icon: PhosphorIconsRegular.identificationCard,
                  onPressed: onOpenFullScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  text: showBack ? 'Ver frente' : 'Ver verso',
                  variant: PremiumButtonVariant.outline,
                  textColor: Colors.white,
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  onPressed: onToggleBack,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Botão Secundário: Cadastrar novo dependente
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: PremiumButton(
            text: 'Cadastrar novo dependente',
            variant: PremiumButtonVariant.glass,
            icon: PhosphorIconsRegular.userPlus,
            onPressed: onAddDependent,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBlock({
    required IconData icon,
    required String label,
    required String value,
    bool isStatus = false,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isStatus ? AppColors.statusGreen : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.cardSubtitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isStatus ? AppColors.statusGreen : AppColors.cardTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
