import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintReviewMandatorySection**
/// Renderiza apenas a seção "Entram sempre" da revisão de impressão,
/// listando informações obrigatórias e estáticas.
class PrintReviewMandatorySection extends StatelessWidget {
  const PrintReviewMandatorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Entram sempre',
          description: 'Essas informações fazem parte da identificação comunitária e não podem ser removidas.',
        ),
        const SizedBox(height: 12),
        DsCard(
          backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.35),
          borderColor: Colors.white.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulletItem('Nome completo ou nome social'),
              const SizedBox(height: 10),
              _buildBulletItem('TEA-ID'),
              const SizedBox(height: 10),
              _buildBulletItem('Validade'),
              const SizedBox(height: 10),
              _buildBulletItem('QR Code'),
              const SizedBox(height: 10),
              _buildBulletItem('Logos ConeCTEA e Família TEA Bauru'),
              const SizedBox(height: 10),
              _buildBulletItem(
                'Aviso legal da carteirinha comunitária',
                isImportant: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DsTipografia.cardTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: DsTipografia.caption.copyWith(
            color: DsCores.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String text, {bool isImportant = false}) {
    final Color bulletColor = isImportant ? DsCores.alerta.accent : DsCores.carteirinha.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pequeno círculo visual customizado com brilho luminoso sutil
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bulletColor,
            boxShadow: [
              BoxShadow(
                color: bulletColor.withValues(alpha: 0.35),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
              fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
