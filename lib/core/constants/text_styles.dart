import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

/// Centralização de estilos tipográficos utilizando Google Fonts.
/// Define a hierarquia visual de títulos, corpos, botões e legendas.
class AppTextStyles {
  /// Título de página padrão (Páginas internas).
  static TextStyle get pageTitle => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => pageTitle;

  /// Título secundário (Subseções).
  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Título terciário.
  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Título de página em destaque (Home/Destaques).
  static TextStyle get pageTitleLarge => GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      );

  /// Subtítulo descritivo abaixo de títulos de página.
  static TextStyle get pageSubtitle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// Rótulo pequeno para identificação de seções (Eyebrow text).
  static TextStyle get sectionLabel => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary.withValues(alpha: 0.8),
        letterSpacing: 1.2,
      );

  /// Título principal dentro de Cards.
  static TextStyle get cardTitle => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Descrição textual dentro de Cards.
  static TextStyle get cardDescription => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.cardSubtitle,
        height: 1.4,
      );

  /// Texto secundário ou desativado dentro de Cards.
  static TextStyle get cardMuted => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.cardMutedText,
      );

  /// Estilo padrão para texto de botões.
  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  /// Estilo para texto de botões pequenos.
  static TextStyle get buttonSmall => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  /// Texto de legenda ou rodapé.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Texto de corpo grande.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  /// Texto de corpo médio (Padrão).
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Texto de corpo pequeno.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Rótulo para botões de ação rápida.
  static TextStyle get buttonLabel => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
}
