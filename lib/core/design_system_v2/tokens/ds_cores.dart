import 'package:flutter/material.dart';

/// Cores base do Design System V2 do ConeCTEA.
///
/// Esta classe concentra a paleta estrutural do app:
/// - fundos Night Blue;
/// - superfícies Dark Glass;
/// - textos;
/// - bordas;
/// - cores de ação;
/// - cores de apoio para inputs, ícones e estados.
///
/// Importante:
/// Cores semânticas de áreas do app devem usar DsTokenVisual.
/// Cores de status devem usar DsTokenStatus.
class DsCores {
  DsCores._();

  // Fundos principais
  static const Color background = Color(0xFF071326);
  static const Color surface = Color(0xFF0B1D3A);
  static const Color surfaceElevated = Color(0xFF102A4C);
  static const Color surfaceCard = Color(0xFF10315E);
  static const Color surfaceCardHover = Color(0xFF163F72);

  // Glassmorphism
  static const Color glass = Color(0x990B1D3A); // 60% opacidade
  static const Color glassStrong = Color(0xD90B1D3A); // 85% opacidade

  // Bordas
  static const Color border = Color(0xFF1E4A7A);
  static const Color borderStrong = Color(0xFF2A5B8F);

  // Textos
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFB8C7E6);
  static const Color textMuted = Color(0xFF9FB2D6);

  // Ações e acentos base
  static const Color primary = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF14D9D0);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Fundos suaves para ícones, selos e estados leves
  static const Color primarySoft = Color(0x267C3AED);
  static const Color cyanSoft = Color(0x2614D9D0);
  static const Color successSoft = Color(0x2634D399);
  static const Color warningSoft = Color(0x26F59E0B);
  static const Color dangerSoft = Color(0x26EF4444);

  // Inputs
  static const Color inputBackground = Color(0xA60F172A);
  static const Color inputBorder = Color(0x1AFFFFFF);
  static const Color inputFocusBorder = Color(0xFF7C3AED);
  static const Color inputPlaceholder = Color(0x4DB8C7E6);
  static const Color inputIcon = Color(0xFFFFFFFF);
  static const Color inputSuffixIcon = Color(0x80B8C7E6);

  // Ícones
  static const Color iconPrimary = Color(0xFFF8FAFC);
  static const Color iconSecondary = Color(0xFFB8C7E6);
  static const Color iconMuted = Color(0xFF8FA3C7);

  // Gradiente principal de fundo/tela
  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF102A4C),
      Color(0xFF0B1D3A),
      Color(0xFF071326),
    ],
  );

  // Gradiente premium neutro para cards
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF102A4C),
      Color(0xFF0B1D3A),
      Color(0xFF08162D),
    ],
  );

  // Gradientes de ação
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C3AED),
      Color(0xFF5B21B6),
    ],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF14D9D0),
      Color(0xFF0EA8A1),
    ],
  );
}
