import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/constants/text_styles.dart';

/// Widget de "pílula" para exibição de status (Ativa, Em Análise, etc).
/// Mapeia os estados do backend para labels e cores amigáveis ao usuário.
class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String rawStatus = status.toLowerCase();
    
    Color color;
    Color bgColor;
    String label;

    if (rawStatus == 'active' || rawStatus == 'ativa' || rawStatus == 'approved' || rawStatus == 'aprovada') {
      color = AppColors.statusGreen;
      bgColor = AppColors.greenIconBg;
      label = 'Ativa';
    } else if (rawStatus == 'waiting_approval' || rawStatus == 'under_review' || rawStatus == 'analise' || rawStatus == 'pending') {
      color = AppColors.alertOrange;
      bgColor = AppColors.orangeIconBg;
      label = 'Em Análise';
    } else if (rawStatus == 'waiting_docs') {
      color = AppColors.cyan;
      bgColor = AppColors.cyanIconBg;
      label = 'Aguardando Docs';
    } else if (rawStatus == 'reviewing_data') {
      color = AppColors.alertOrange;
      bgColor = AppColors.orangeIconBg;
      label = 'Revisar Dados';
    } else if (rawStatus == 'rejected' || rawStatus == 'rejeitada') {
      color = AppColors.errorRed;
      bgColor = AppColors.errorRed.withValues(alpha: 0.14);
      label = 'Reprovada';
    } else if (rawStatus == 'expired' || rawStatus == 'vencida') {
      color = AppColors.cardMutedText;
      bgColor = AppColors.surfaceDark;
      label = 'Vencida';
    } else if (rawStatus == 'suspended' || rawStatus == 'suspensa') {
      color = AppColors.adminBlock;
      bgColor = Colors.black.withValues(alpha: 0.2);
      label = 'Suspensa';
    } else if (rawStatus == 'renewing') {
      color = const Color(0xFF3B82F6);
      bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.16);
      label = 'Renovando';
    } else {
      color = AppColors.alertOrange;
      bgColor = AppColors.orangeIconBg;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
