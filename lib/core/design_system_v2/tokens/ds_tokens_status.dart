import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Token semântico de status do Design System V2 do ConeCTEA.
///
/// Usado para estados de carteirinha e solicitação, como:
/// - ativa;
/// - aguardando aprovação;
/// - aguardando documentação;
/// - revisão de dados;
/// - reprovada;
/// - vencida;
/// - suspensa;
/// - renovação.
///
/// Importante:
/// Este token não deve ser usado para áreas comuns do app.
/// Áreas como Conta, Segurança, Privacidade e Suporte usam DsTokenVisual.
///
/// Regra atual do produto:
/// No fluxo de carteirinha, approved e active apontam para o mesmo estado visual:
/// Carteirinha Ativa.
///
/// O banco atual persiste active, não approved.
class DsTokenStatus {
  final String statusKey;
  final String label;
  final String shortLabel;
  final String semanticLabel;
  final Color primary;
  final Color harmonic;
  final Color pillBackground;
  final Color pillBorder;
  final Color border;
  final Color iconColor;
  final Color ctaAccent;
  final IconData icon;

  const DsTokenStatus({
    required this.statusKey,
    required this.label,
    required this.shortLabel,
    required this.semanticLabel,
    required this.primary,
    required this.harmonic,
    required this.pillBackground,
    required this.pillBorder,
    required this.border,
    required this.iconColor,
    required this.ctaAccent,
    required this.icon,
  });

  /// Retorna um token visual de status a partir do valor técnico salvo no app/banco.
  ///
  /// Aceita variações com maiúsculas, espaços ou hífen.
  factory DsTokenStatus.fromStatus(String? status) {
    final normalized = _normalize(status);

    switch (normalized) {
      case 'active':
      case 'approved':
      case 'ativa':
      case 'ativo':
      case 'aprovada':
      case 'aprovado':
        return active;

      case 'waiting_approval':
      case 'under_review':
      case 'pending':
      case 'analise':
      case 'em_analise':
      case 'aguardando_aprovacao':
        return waitingApproval;

      case 'waiting_docs':
      case 'waiting_documentation':
      case 'awaiting_docs':
      case 'awaiting_documentation':
      case 'document_pending':
      case 'docs_required':
      case 'aguardando_documentacao':
        return waitingDocs;

      case 'reviewing_data':
      case 'data_review':
      case 'data_revision':
      case 'requesting_data_review':
      case 'requested_data_review':
      case 'solicitando_revisao_dados':
      case 'revisar_dados':
        return reviewingData;

      case 'rejected':
      case 'refused':
      case 'reprovada':
      case 'reprovado':
      case 'rejeitada':
      case 'rejeitado':
        return rejected;

      case 'expired':
      case 'vencida':
      case 'vencido':
      case 'expirada':
      case 'expirado':
        return expired;

      case 'suspended':
      case 'suspensa':
      case 'suspenso':
        return suspended;

      case 'renewing':
      case 'renewal':
      case 'waiting_renewal':
      case 'awaiting_renewal':
      case 'aguardando_renovacao':
        return renewing;

      default:
        return fallback;
    }
  }

  static String _normalize(String? status) {
    return (status ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static final DsTokenStatus active = _token(
    statusKey: 'active',
    label: 'Ativa',
    shortLabel: 'ATIVA',
    semanticLabel: 'Carteirinha ativa',
    primary: const Color(0xFF00FF85),
    harmonic: const Color(0xFF1DE9B6),
    iconColor: const Color(0xFF00FF85),
    icon: PhosphorIconsFill.checkCircle,
  );

  static final DsTokenStatus waitingApproval = _token(
    statusKey: 'waiting_approval',
    label: 'Em análise',
    shortLabel: 'ANÁLISE',
    semanticLabel: 'Aguardando aprovação',
    primary: const Color(0xFFF59E0B),
    harmonic: const Color(0xFFFBBF24),
    iconColor: const Color(0xFFFCD34D),
    icon: PhosphorIconsFill.clockCountdown,
    pillAlpha: 0.13,
    pillBorderAlpha: 0.30,
  );

  static final DsTokenStatus waitingDocs = _token(
    statusKey: 'waiting_docs',
    label: 'Aguardando documentação',
    shortLabel: 'DOCS',
    semanticLabel: 'Aguardando envio de documentação',
    primary: const Color(0xFF22D3EE),
    harmonic: const Color(0xFF2DD4BF),
    iconColor: const Color(0xFFA5F3FC),
    icon: PhosphorIconsFill.files,
    pillAlpha: 0.12,
    pillBorderAlpha: 0.35,
  );

  static final DsTokenStatus reviewingData = _token(
    statusKey: 'reviewing_data',
    label: 'Revisão de dados',
    shortLabel: 'REVISAR',
    semanticLabel: 'Solicitando revisão de dados',
    primary: const Color(0xFFFF7A1A),
    harmonic: const Color(0xFFFFB020),
    iconColor: const Color(0xFFFFA94D),
    icon: PhosphorIconsFill.warningCircle,
    pillAlpha: 0.13,
    pillBorderAlpha: 0.30,
  );

  static final DsTokenStatus rejected = _token(
    statusKey: 'rejected',
    label: 'Reprovada',
    shortLabel: 'REPROVADA',
    semanticLabel: 'Solicitação reprovada',
    primary: const Color(0xFFE11D48),
    harmonic: const Color(0xFFFB7185),
    iconColor: const Color(0xFFFB7185),
    icon: PhosphorIconsFill.xCircle,
    pillAlpha: 0.13,
    pillBorderAlpha: 0.30,
  );

  static final DsTokenStatus expired = _token(
    statusKey: 'expired',
    label: 'Vencida',
    shortLabel: 'VENCIDA',
    semanticLabel: 'Carteirinha vencida',
    primary: const Color(0xFFCBD5E1),
    harmonic: const Color(0xFF94A3B8),
    iconColor: const Color(0xFFE2E8F0),
    icon: PhosphorIconsFill.calendarX,
    pillAlpha: 0.10,
    pillBorderAlpha: 0.25,
  );

  static final DsTokenStatus suspended = _token(
    statusKey: 'suspended',
    label: 'Suspensa',
    shortLabel: 'SUSPENSA',
    semanticLabel: 'Carteirinha suspensa',
    primary: const Color(0xFFC0A878),
    harmonic: const Color(0xFF8B7355),
    iconColor: const Color(0xFFF5E6B8),
    icon: PhosphorIconsFill.lockKey,
    pillAlpha: 0.12,
    pillBorderAlpha: 0.35,
  );

  static final DsTokenStatus renewing = _token(
    statusKey: 'renewing',
    label: 'Renovação',
    shortLabel: 'RENOVAÇÃO',
    semanticLabel: 'Aguardando renovação',
    primary: const Color(0xFF8B3DFF),
    harmonic: const Color(0xFF22D3EE),
    iconColor: const Color(0xFFB794FF),
    icon: PhosphorIconsFill.arrowsClockwise,
    pillAlpha: 0.12,
    pillBorderAlpha: 0.30,
  );

  static final DsTokenStatus fallback = _token(
    statusKey: 'fallback',
    label: 'Status',
    shortLabel: 'STATUS',
    semanticLabel: 'Status não identificado',
    primary: const Color(0xFFCBD5E1),
    harmonic: const Color(0xFF94A3B8),
    iconColor: const Color(0xFFE2E8F0),
    icon: PhosphorIconsFill.question,
    pillAlpha: 0.10,
    pillBorderAlpha: 0.25,
  );

  static DsTokenStatus _token({
    required String statusKey,
    required String label,
    required String shortLabel,
    required String semanticLabel,
    required Color primary,
    required Color harmonic,
    required Color iconColor,
    required IconData icon,
    Color? ctaAccent,
    double pillAlpha = 0.12,
    double pillBorderAlpha = 0.25,
  }) {
    return DsTokenStatus(
      statusKey: statusKey,
      label: label,
      shortLabel: shortLabel,
      semanticLabel: semanticLabel,
      primary: primary,
      harmonic: harmonic,
      pillBackground: primary.withValues(alpha: pillAlpha),
      pillBorder: primary.withValues(alpha: pillBorderAlpha),
      border: primary,
      iconColor: iconColor,
      ctaAccent: ctaAccent ?? primary,
      icon: icon,
    );
  }
}
