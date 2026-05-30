import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RequestBeneficiaryChoiceSheet extends StatelessWidget {
  const RequestBeneficiaryChoiceSheet({super.key});

  /// Exibe o bottom sheet de escolha e retorna true se "Para mim", false se "Outro", ou null se cancelado.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: DsCores.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => const RequestBeneficiaryChoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DsCores.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quem é o beneficiário?',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DsCores.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha para quem você está solicitando esta carteirinha.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DsCores.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildChoiceCard(
              context: context,
              title: 'Para mim',
              description:
                  'Usar meus dados da conta para preencher o cadastro.',
              icon: PhosphorIconsRegular.user,
              iconColor: DsCores.conta.accent,
              onTap: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            _buildChoiceCard(
              context: context,
              title: 'Outro dependente',
              description:
                  'Cadastrar uma pessoa diferente, como filho(a), familiar ou dependente.',
              icon: PhosphorIconsRegular.users,
              iconColor: DsCores.dependente.accent,
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DsRaios.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DsCores.inputBackground,
          borderRadius: BorderRadius.circular(DsRaios.card),
          border: Border.all(color: DsCores.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DsCores.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: DsCores.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              PhosphorIconsRegular.caretRight,
              color: DsCores.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
