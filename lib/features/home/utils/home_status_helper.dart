import 'package:flutter/material.dart';
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
  });
}

/// Helper para centralizar as regras repetidas de formatação de status.
/// Evita múltiplos `switches` extensos nos arquivos de UI.
class HomeStatusHelper {
  /// 1. Status do Carrossel de Membros
  /// Preserva o switch antigo, onde apenas 'active'/'ativa' fica verde.
  static HomeStatusInfo memberStatus(String rawStatus) {
    final status = rawStatus.toLowerCase();
    final tokens = StatusVisualTokens.fromStatus(status);

    switch (status) {
      case 'active':
      case 'ativa':
        return HomeStatusInfo(
          shortLabel: 'Ativa',
          fullLabel: tokens.label,
          color: tokens.primary,
          pillBackground: tokens.pillBackground,
          pillBorder: tokens.pillBorder,
          icon: tokens.icon,
          isActive: true,
        );
      default:
        return HomeStatusInfo(
          shortLabel: status == 'waiting_docs'
              ? 'Aguardando Docs'
              : status == 'reviewing_data'
              ? 'Revisar Dados'
              : status == 'rejected'
              ? 'Reprovada'
              : status == 'expired'
              ? 'Vencida'
              : status == 'renewing'
              ? 'Em Renovação'
              : 'Em Análise',
          fullLabel: tokens.label,
          color: tokens.primary,
          pillBackground: tokens.pillBackground,
          pillBorder: tokens.pillBorder,
          icon: tokens.icon,
        );
    }
  }

  /// 2. Status da Carteirinha Digital (Documento Digital)
  /// Preserva o switch antigo completo da `_buildCarteirinhaSection`.
  static HomeStatusInfo digitalCardStatus(
    String rawStatus, {
    bool isExpired = false,
  }) {
    final effectiveStatus = isExpired ? 'expired' : rawStatus.toLowerCase();
    final tokens = StatusVisualTokens.fromStatus(effectiveStatus);

    return HomeStatusInfo(
      shortLabel: tokens.label,
      fullLabel: tokens.label,
      color: tokens.primary,
      pillBackground: tokens.pillBackground,
      pillBorder: tokens.pillBorder,
      icon: tokens.icon,
      isActive: effectiveStatus == 'active' || effectiveStatus == 'approved',
      isRejected: effectiveStatus == 'rejected',
      showJustification:
          effectiveStatus != 'active' &&
          effectiveStatus != 'approved' &&
          effectiveStatus != 'expired',
    );
  }

  /// 3. Status de Solicitação em Andamento
  /// Preserva o switch antigo, SEM o caso de 'renewing'.
  static HomeStatusInfo ongoingRequestStatus(String rawStatus) {
    final status = rawStatus.toLowerCase();
    final tokens = StatusVisualTokens.fromStatus(status);

    return HomeStatusInfo(
      shortLabel: tokens.label,
      fullLabel: tokens.label,
      color: tokens.primary,
      pillBackground: tokens.pillBackground,
      pillBorder: tokens.pillBorder,
      icon: tokens.icon,
      isActive: status == 'active' || status == 'approved',
    );
  }
}
