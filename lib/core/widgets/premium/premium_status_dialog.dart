import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/constants/text_styles.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';

/// Diálogo premium para exibição de justificativas e detalhes de status.
/// Design refinado: Lunar Glass / Night Blue Premium.
/// Puramente informativo, sem botões de ação de negócio.
class PremiumStatusDialog extends StatelessWidget {
  final HomeStatusInfo statusInfo;
  final String notes;

  const PremiumStatusDialog({
    super.key,
    required this.statusInfo,
    required this.notes,
  });

  /// Método estático facilitador para exibir o diálogo.
  static Future<void> show(
    BuildContext context, {
    required HomeStatusInfo statusInfo,
    required String notes,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: PremiumStatusDialog(
          statusInfo: statusInfo,
          notes: notes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = statusInfo.color;
    final title = statusInfo.deadlineTitle ?? statusInfo.fullLabel;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: PremiumCard(
          padding: EdgeInsets.zero,
          radius: 28,
          borderOverride: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Compacto e Refinado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Ícone Sóbrio
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        statusInfo.icon,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo Scrollável (360dp Safety)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (statusInfo.deadlineMessage != null) ...[
                        _buildSection(
                          'INFORMAÇÃO IMPORTANTE',
                          statusInfo.deadlineMessage!,
                          color: color,
                          isHighlight: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (notes.isNotEmpty && statusInfo.shouldShowTeamDetails) ...[
                        _buildSection(
                          'DETALHES DA EQUIPE',
                          notes,
                          color: color,
                          isHighlight: true,
                        ),
                      ],
                      if (statusInfo.deadlineMessage == null && notes.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Nenhuma observação adicional.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Rodapé com Botão único 'Entendido'
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: PremiumButton(
                  text: 'Entendido',
                  variant: PremiumButtonVariant.primary,
                  colorOverride: color,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String label,
    String content, {
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: isHighlight ? 0.7 : 0.4),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isHighlight ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isHighlight ? 0.15 : 0.08),
            ),
          ),
          child: Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.95),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

