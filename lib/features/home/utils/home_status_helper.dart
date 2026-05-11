import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';

/// Classe que encapsula todas as informações visuais de um status na HomeView.
class HomeStatusInfo {
  final String shortLabel;
  final String fullLabel;
  final Color color;
  final IconData icon;
  final bool isActive;
  final bool isRejected;
  final bool showJustification;

  const HomeStatusInfo({
    required this.shortLabel,
    required this.fullLabel,
    required this.color,
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

    switch (status) {
      case 'active':
      case 'ativa':
        return const HomeStatusInfo(
          shortLabel: 'Ativa',
          fullLabel: 'ATIVA',
          color: AppColors.statusGreen,
          icon: Icons.check_circle_rounded,
          isActive: true, // Garante que a bolinha do chip fique verde
        );
      case 'waiting_approval':
      case 'under_review':
      case 'analise':
        return const HomeStatusInfo(
          shortLabel: 'Em Análise',
          fullLabel: 'EM ANÁLISE',
          color: AppColors.alertOrange,
          icon: Icons.history_rounded,
        );
      case 'waiting_docs':
        return const HomeStatusInfo(
          shortLabel: 'Aguardando Docs',
          fullLabel: 'AGUARDANDO DOCS',
          color: AppColors.alertOrange, // Legado: apenas ativo era verde, resto laranja no chip
          icon: Icons.file_present_rounded,
        );
      case 'reviewing_data':
        return const HomeStatusInfo(
          shortLabel: 'Revisar Dados',
          fullLabel: 'REVISAR DADOS',
          color: AppColors.alertOrange,
          icon: Icons.edit_note_rounded,
        );
      case 'rejected':
      case 'rejeitada':
        return const HomeStatusInfo(
          shortLabel: 'Reprovada',
          fullLabel: 'REPROVADA',
          color: AppColors.alertOrange,
          icon: Icons.error_outline_rounded,
        );
      case 'suspended':
      case 'suspensa':
        return const HomeStatusInfo(
          shortLabel: 'Suspensa',
          fullLabel: 'SUSPENSA',
          color: AppColors.alertOrange,
          icon: Icons.block_rounded,
        );
      case 'expired':
      case 'vencida':
        return const HomeStatusInfo(
          shortLabel: 'Vencida',
          fullLabel: 'VENCIDA',
          color: AppColors.alertOrange,
          icon: Icons.event_busy_rounded,
        );
      case 'renewing':
        return const HomeStatusInfo(
          shortLabel: 'Em Renovação',
          fullLabel: 'EM RENOVAÇÃO',
          color: AppColors.alertOrange,
          icon: Icons.autorenew_rounded,
        );
      default:
        return const HomeStatusInfo(
          shortLabel: 'Em Análise',
          fullLabel: 'EM ANÁLISE',
          color: AppColors.alertOrange,
          icon: Icons.pending_actions_rounded,
        );
    }
  }

  /// 2. Status da Carteirinha Digital (Documento Digital)
  /// Preserva o switch antigo completo da `_buildCarteirinhaSection`.
  static HomeStatusInfo digitalCardStatus(String rawStatus, {bool isExpired = false}) {
    final effectiveStatus = isExpired ? 'expired' : rawStatus.toLowerCase();

    switch (effectiveStatus) {
      case 'active':
      case 'ativa':
      case 'approved':
      case 'aprovada':
        return const HomeStatusInfo(
          shortLabel: 'Ativa',
          fullLabel: 'ATIVA',
          color: AppColors.statusGreen,
          icon: Icons.check_circle_rounded,
          isActive: true,
        );
      case 'waiting_approval':
      case 'under_review':
      case 'analise':
        return const HomeStatusInfo(
          shortLabel: 'Em Análise',
          fullLabel: 'EM ANÁLISE',
          color: AppColors.alertOrange,
          icon: Icons.history_rounded,
        );
      case 'waiting_docs':
        return const HomeStatusInfo(
          shortLabel: 'Aguardando Docs',
          fullLabel: 'AGUARDANDO DOCS',
          color: AppColors.cardBlue,
          icon: Icons.file_present_rounded,
          showJustification: true,
        );
      case 'reviewing_data':
        return const HomeStatusInfo(
          shortLabel: 'Revisar Dados',
          fullLabel: 'REVISAR DADOS',
          color: AppColors.alertOrange,
          icon: Icons.edit_note_rounded,
          showJustification: true,
        );
      case 'rejected':
      case 'rejeitada':
        return const HomeStatusInfo(
          shortLabel: 'Reprovada',
          fullLabel: 'REPROVADA',
          color: AppColors.errorRed,
          icon: Icons.error_outline_rounded,
          isRejected: true,
          showJustification: true,
        );
      case 'suspended':
      case 'suspensa':
        return const HomeStatusInfo(
          shortLabel: 'Suspensa',
          fullLabel: 'SUSPENSA',
          color: AppColors.adminBlock,
          icon: Icons.block_rounded,
          showJustification: true,
        );
      case 'expired':
      case 'vencida':
        return const HomeStatusInfo(
          shortLabel: 'Vencida',
          fullLabel: 'VENCIDA',
          color: Colors.brown,
          icon: Icons.event_busy_rounded,
        );
      case 'renewing':
      case 'renovacao':
        return const HomeStatusInfo(
          shortLabel: 'Renovação',
          fullLabel: 'RENOVAÇÃO',
          color: AppColors.primary,
          icon: Icons.autorenew_rounded,
        );
      default:
        return const HomeStatusInfo(
          shortLabel: 'Em Análise',
          fullLabel: 'EM ANÁLISE',
          color: AppColors.alertOrange,
          icon: Icons.pending_actions_rounded,
        );
    }
  }

  /// 3. Status de Solicitação em Andamento
  /// Preserva o switch antigo, SEM o caso de 'renewing'.
  static HomeStatusInfo ongoingRequestStatus(String rawStatus) {
    final status = rawStatus.toLowerCase();

    switch (status) {
      case 'active':
      case 'ativa':
      case 'approved':
      case 'aprovada':
        return const HomeStatusInfo(
          shortLabel: 'Ativa',
          fullLabel: 'ATIVA',
          color: AppColors.statusGreen,
          icon: Icons.check_circle_rounded,
          isActive: true,
        );
      case 'waiting_approval':
      case 'under_review':
      case 'analise':
        return const HomeStatusInfo(
          shortLabel: 'Em Análise',
          fullLabel: 'EM ANÁLISE',
          color: AppColors.alertOrange,
          icon: Icons.history_rounded,
        );
      case 'waiting_docs':
        return const HomeStatusInfo(
          shortLabel: 'Aguardando Docs',
          fullLabel: 'AGUARDANDO DOCS',
          color: AppColors.cardBlue,
          icon: Icons.file_present_rounded,
        );
      case 'reviewing_data':
        return const HomeStatusInfo(
          shortLabel: 'Revisar Dados',
          fullLabel: 'REVISAR DADOS',
          color: AppColors.alertOrange,
          icon: Icons.edit_note_rounded,
        );
      case 'rejected':
      case 'rejeitada':
        return const HomeStatusInfo(
          shortLabel: 'Reprovada',
          fullLabel: 'REPROVADA',
          color: AppColors.errorRed,
          icon: Icons.error_outline_rounded,
        );
      case 'suspended':
      case 'suspensa':
        return const HomeStatusInfo(
          shortLabel: 'Suspensa',
          fullLabel: 'SUSPENSA',
          color: AppColors.adminBlock,
          icon: Icons.block_rounded,
        );
      case 'expired':
      case 'vencida':
        return const HomeStatusInfo(
          shortLabel: 'Vencida',
          fullLabel: 'VENCIDA',
          color: Colors.brown,
          icon: Icons.event_busy_rounded,
        );
      default:
        // Fallback padrão, incluindo renewing exatamente como no comportamento legado.
        return const HomeStatusInfo(
          shortLabel: 'Em Análise',
          fullLabel: 'EM ANÁLISE',
          color: AppColors.alertOrange,
          icon: Icons.pending_actions_rounded,
        );
    }
  }
}
