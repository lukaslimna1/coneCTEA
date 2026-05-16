import 'package:flutter/material.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

/// Classe que encapsula todas as informações visuais de um status na HomeView.
class HomeStatusInfo {
  final String shortLabel;
  final String fullLabel;
  final Color color;
  final Color pillBackground;
  final Color pillBorder;
  final IconData icon;
  final bool isActive;
  final bool isRejected;
  final bool showJustification;
  final String? deadlineTitle;
  final String? deadlineMessage;
  final String? secondaryActionLabel;

  const HomeStatusInfo({
    required this.shortLabel,
    required this.fullLabel,
    required this.color,
    required this.pillBackground,
    required this.pillBorder,
    required this.icon,
    this.isActive = false,
    this.isRejected = false,
    this.showJustification = false,
    this.deadlineTitle,
    this.deadlineMessage,
    this.secondaryActionLabel,
  });
}

/// Helper para centralizar as regras repetidas de formatação de status.
/// Evita múltiplos `switches` extensos nos arquivos de UI.
class HomeStatusHelper {
  static String getEffectiveStatus({
    required String memberStatus,
    CardRequest? memberRequest,
  }) {
    // Se houver request atual não finalizada, ela deve ter prioridade sobre status antigo da carteirinha.
    if (memberRequest != null) {
      final reqStatus = memberRequest.status.toLowerCase();
      // Status de fluxo/transição que devem prevalecer sobre o status do membro (que pode estar 'active' ou outro)
      if (reqStatus != 'active' && reqStatus != 'approved') {
        return reqStatus;
      }
    }
    return memberStatus.toLowerCase();
  }

  /// 1. Status do Carrossel de Membros
  /// Usa o status efetivo unificado.
  static HomeStatusInfo memberStatus(String rawStatus, {CardRequest? memberRequest}) {
    final status = getEffectiveStatus(
      memberStatus: rawStatus,
      memberRequest: memberRequest,
    );
    final tokens = StatusVisualTokens.fromStatus(status);

    return HomeStatusInfo(
      shortLabel: tokens.label,
      fullLabel: tokens.label,
      color: tokens.primary,
      pillBackground: tokens.pillBackground,
      pillBorder: tokens.pillBorder,
      icon: tokens.icon,
      isActive: status == 'active' || status == 'ativa',
    );
  }

  /// 2. Status da Carteirinha Digital (Documento Digital)
  static HomeStatusInfo digitalCardStatus(
    String rawStatus, {
    CardRequest? memberRequest,
    bool isExpired = false,
  }) {
    final status = getEffectiveStatus(
      memberStatus: rawStatus,
      memberRequest: memberRequest,
    );
    final effectiveStatus = isExpired ? 'expired' : status;
    final tokens = StatusVisualTokens.fromStatus(effectiveStatus);

    String? deadlineTitle;
    String? deadlineMessage;
    String? secondaryActionLabel;

    final DateTime? deadline = memberRequest?.expiresAt;
    final String dateStr = deadline != null
        ? '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}'
        : '';

    switch (effectiveStatus) {
      case 'waiting_approval':
      case 'under_review':
      case 'pending':
        deadlineTitle = 'Prazo de aprovação';
        deadlineMessage = 'A análise da carteirinha pode levar até 5 dias úteis, caso não existam pendências no cadastro ou nos documentos.';
        secondaryActionLabel = 'Ver prazo de aprovação';
        break;
      case 'waiting_docs':
        deadlineTitle = 'Documentos solicitados';
        deadlineMessage = dateStr.isNotEmpty
            ? 'Envie os documentos até $dateStr.'
            : 'Envie os documentos solicitados para continuar.';
        secondaryActionLabel = 'Ver documentos solicitados';
        break;
      case 'reviewing_data':
        deadlineTitle = 'Dados para revisar';
        deadlineMessage = dateStr.isNotEmpty
            ? 'Corrija os dados até $dateStr.'
            : 'Revise os dados solicitados para continuar.';
        secondaryActionLabel = 'Ver dados para revisão';
        break;
      case 'renewing':
        deadlineTitle = 'Prazo da renovação';
        deadlineMessage = 'A renovação pode levar de 5 a 10 dias úteis, dependendo da análise e da necessidade de novas informações.';
        secondaryActionLabel = 'Ver prazo da renovação';
        break;
      case 'expired':
        // Sem botão secundário específico
        deadlineTitle = 'Vencida';
        deadlineMessage = 'Solicite a renovação para continuar utilizando.';
        secondaryActionLabel = null;
        break;
      case 'rejected':
        deadlineTitle = 'Motivo da reprovação';
        deadlineMessage = 'Verifique o motivo para entender como proceder.';
        secondaryActionLabel = 'Ver motivo da reprovação';
        break;
      case 'suspended':
        deadlineTitle = 'Motivo da suspensão';
        deadlineMessage = 'Entre em contato com o suporte do projeto.';
        secondaryActionLabel = 'Ver motivo da suspensão';
        break;
    }

    return HomeStatusInfo(
      shortLabel: tokens.label,
      fullLabel: tokens.label,
      color: tokens.primary,
      pillBackground: tokens.pillBackground,
      pillBorder: tokens.pillBorder,
      icon: tokens.icon,
      isActive: effectiveStatus == 'active' || effectiveStatus == 'approved',
      isRejected: effectiveStatus == 'rejected',
      showJustification: secondaryActionLabel != null,
      deadlineTitle: deadlineTitle,
      deadlineMessage: deadlineMessage,
      secondaryActionLabel: secondaryActionLabel,
    );
  }
}
