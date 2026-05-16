import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tokens visuais premium para estados de solicitações e carteirinhas.
/// Segue a estética Night Blue: vibrante, neon e alto contraste.
class StatusVisualTokens {
  final String label;
  final Color primary;
  final Color harmonic;
  final Color pillBackground;
  final Color border;
  final Color pillBorder;
  final Color iconColor;
  final Color ctaAccent;
  final IconData icon;

  const StatusVisualTokens({
    required this.label,
    required this.primary,
    required this.harmonic,
    required this.pillBackground,
    required this.pillBorder,
    required this.border,
    required this.iconColor,
    required this.ctaAccent,
    required this.icon,
  });

  /// Retorna os tokens visuais baseados no status técnico.
  factory StatusVisualTokens.fromStatus(String? status) {
    final s = status?.toLowerCase() ?? '';

    switch (s) {
      case 'active':
      case 'approved':
        return StatusVisualTokens(
          label: 'ATIVA',
          primary: const Color(0xFF00FF85),
          harmonic: const Color(0xFF1DE9B6),
          pillBackground: const Color(0xFF00FF85).withValues(alpha: 0.12),
          pillBorder: const Color(0xFF00FF85).withValues(alpha: 0.25),
          border: const Color(0xFF00FF85),
          iconColor: const Color(0xFF00FF85),
          ctaAccent: const Color(0xFF00FF85),
          icon: PhosphorIconsFill.checkCircle,
        );

      case 'waiting_approval':
      case 'under_review':
      case 'pending':
        return StatusVisualTokens(
          label: 'EM ANÁLISE',
          primary: const Color(0xFFF59E0B),
          harmonic: const Color(0xFFFBBF24),
          pillBackground: const Color(0xFFF59E0B).withValues(alpha: 0.13),
          pillBorder: const Color(0xFFF59E0B).withValues(alpha: 0.30),
          border: const Color(0xFFF59E0B),
          iconColor: const Color(0xFFFCD34D),
          ctaAccent: const Color(0xFFF59E0B),
          icon: PhosphorIconsFill.clockCountdown,
        );

      case 'waiting_docs':
        return StatusVisualTokens(
          label: 'ENVIAR DOCS',
          primary: const Color(0xFF22D3EE),
          harmonic: const Color(0xFF2DD4BF),
          pillBackground: const Color(0xFF22D3EE).withValues(alpha: 0.12),
          pillBorder: const Color(0xFF22D3EE).withValues(alpha: 0.35),
          border: const Color(0xFF22D3EE),
          iconColor: const Color(0xFFA5F3FC),
          ctaAccent: const Color(0xFF22D3EE),
          icon: PhosphorIconsFill.files,
        );

      case 'reviewing_data':
        return StatusVisualTokens(
          label: 'REVISAR',
          primary: const Color(0xFFFF7A1A),
          harmonic: const Color(0xFFFFB020),
          pillBackground: const Color(0xFFFF7A1A).withValues(alpha: 0.13),
          pillBorder: const Color(0xFFFF7A1A).withValues(alpha: 0.30),
          border: const Color(0xFFFF7A1A),
          iconColor: const Color(0xFFFFA94D),
          ctaAccent: const Color(0xFFFF7A1A),
          icon: PhosphorIconsFill.warningCircle,
        );

      case 'rejected':
        return StatusVisualTokens(
          label: 'REPROVADA',
          primary: const Color(0xFFE11D48),
          harmonic: const Color(0xFFFB7185),
          pillBackground: const Color(0xFFE11D48).withValues(alpha: 0.13),
          pillBorder: const Color(0xFFE11D48).withValues(alpha: 0.30),
          border: const Color(0xFFE11D48),
          iconColor: const Color(0xFFFB7185),
          ctaAccent: const Color(0xFFE11D48),
          icon: PhosphorIconsFill.xCircle,
        );

      case 'suspended':
        return StatusVisualTokens(
          label: 'SUSPENSA',
          primary: const Color(0xFFC0A878),
          harmonic: const Color(0xFF8B7355),
          pillBackground: const Color(0xFFC0A878).withValues(alpha: 0.12),
          pillBorder: const Color(0xFFC0A878).withValues(alpha: 0.35),
          border: const Color(0xFFC0A878),
          iconColor: const Color(0xFFF5E6B8),
          ctaAccent: const Color(0xFFC0A878),
          icon: PhosphorIconsFill.lockKey,
        );

      case 'expired':
        return StatusVisualTokens(
          label: 'VENCIDA',
          primary: const Color(0xFFCBD5E1),
          harmonic: const Color(0xFF94A3B8),
          pillBackground: const Color(0xFFCBD5E1).withValues(alpha: 0.10),
          pillBorder: const Color(0xFFCBD5E1).withValues(alpha: 0.25),
          border: const Color(0xFFCBD5E1),
          iconColor: const Color(0xFFE2E8F0),
          ctaAccent: const Color(0xFFCBD5E1),
          icon: PhosphorIconsFill.calendarX,
        );

      case 'renewing':
        return StatusVisualTokens(
          label: 'RENOVAÇÃO',
          primary: const Color(0xFF8B3DFF),
          harmonic: const Color(0xFF22D3EE),
          pillBackground: const Color(0xFF8B3DFF).withValues(alpha: 0.12),
          pillBorder: const Color(0xFF8B3DFF).withValues(alpha: 0.30),
          border: const Color(0xFF8B3DFF),
          iconColor: const Color(0xFFB794FF),
          ctaAccent: const Color(0xFF8B3DFF),
          icon: PhosphorIconsFill.arrowsClockwise,
        );

      default:
        return StatusVisualTokens(
          label: 'STATUS',
          primary: const Color(0xFFCBD5E1),
          harmonic: const Color(0xFF94A3B8),
          pillBackground: const Color(0xFFCBD5E1).withValues(alpha: 0.10),
          pillBorder: const Color(0xFFCBD5E1).withValues(alpha: 0.25),
          border: const Color(0xFFCBD5E1),
          iconColor: const Color(0xFFE2E8F0),
          ctaAccent: const Color(0xFFCBD5E1),
          icon: PhosphorIconsFill.question,
        );
    }
  }
}
