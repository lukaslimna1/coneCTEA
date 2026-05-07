import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/digital_card.dart';
import 'widgets/digital_card_widget.dart';

class CardsView extends StatelessWidget {
  const CardsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for demonstration
    final sampleCard = DigitalCard(
      id: '1',
      memberId: 'm1',
      userId: 'u1',
      cardNumber: '4588 2311 0092',
      status: 'active',
      validUntil: DateTime(2025, 12, 31),
      issuedAt: DateTime.now(),
      frontData: {
        'name': 'Lucas Silva',
        'cpf': '123.456.789-00',
      },
      backData: {},
      qrValidationUrl: 'https://example.com/verify/1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meus Cartões',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse suas carteirinhas digitais cadastradas.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          DigitalCardWidget(card: sampleCard),
          const SizedBox(height: 20),
          _buildAddCardButton(),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Solicitar Nova Carteirinha',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
