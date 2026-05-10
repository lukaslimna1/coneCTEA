import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';

class AdminStatusHelper {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
      case 'em análise':
        return AppColors.adminAnalysis;
      case 'active':
      case 'approved':
      case 'aprovada':
      case 'ativa':
        return AppColors.adminPositive;
      case 'waiting_docs':
        return AppColors.adminRequest;
      case 'reviewing_data':
        return AppColors.adminAnalysis;
      case 'rejected':
      case 'rejeitada':
        return AppColors.adminDanger;
      case 'suspended':
      case 'suspensa':
        return AppColors.adminBlock;
      case 'expired':
      case 'expirada':
        return Colors.brown;
      case 'renewing':
      case 'aguardando renovação':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
        return 'EM ANÁLISE';
      case 'approved':
      case 'active':
        return 'ATIVA / APROVADA';
      case 'rejected':
        return 'REJEITADA';
      case 'waiting_docs':
        return 'AGUARDANDO DOCS';
      case 'reviewing_data':
        return 'REVISAR DADOS';
      case 'suspended':
        return 'SUSPENSA';
      case 'expired':
      case 'expirada':
        return 'EXPIRADA';
      case 'renewing':
      case 'aguardando renovação':
        return 'AGUARDANDO RENOVAÇÃO';
      default:
        return status.toUpperCase();
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
        return Icons.hourglass_empty;
      case 'approved':
      case 'active':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'waiting_docs':
        return Icons.description_outlined;
      case 'reviewing_data':
        return Icons.edit_note_outlined;
      case 'suspended':
        return Icons.pause_circle_outline;
      case 'expired':
        return Icons.event_busy_outlined;
      case 'renewing':
        return Icons.autorenew_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
