import 'package:flutter/material.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

class AdminStatusHelper {
  static Color getStatusColor(String status) {
    return StatusVisualTokens.fromStatus(status).primary;
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
    return StatusVisualTokens.fromStatus(status).icon;
  }
}
