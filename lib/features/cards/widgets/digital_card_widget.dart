import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/digital_card.dart';

class DigitalCardWidget extends StatelessWidget {
  final DigitalCard card;
  final String holderName; // For convenience if we don't want to parse frontData here

  const DigitalCardWidget({
    super.key, 
    required this.card,
    this.holderName = 'NOME DO TITULAR',
  });

  @override
  Widget build(BuildContext context) {
    // Try to get name from frontData if not provided
    final name = card.frontData['name'] ?? holderName;
    final cpf = card.frontData['cpf'] ?? '000.000.000-00';

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBlue,
            Color(0xFF0056D2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          _buildLogo(),
          _buildChip(),
          _buildUserInfo(name, cpf),
          _buildCardInfo(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Positioned(
      top: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ConeCTEA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'CARTEIRINHA DIGITAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip() {
    return Positioned(
      top: 10,
      left: 0,
      child: Container(
        width: 45,
        height: 35,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, String cpf) {
    return Positioned(
      bottom: 45,
      left: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CPF: $cpf',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'VALIDADE: ${card.validUntil.month}/${card.validUntil.year}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Nº ${card.cardNumber}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
