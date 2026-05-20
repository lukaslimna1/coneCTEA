import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';

/// Centralização de estilos tipográficos do Design System V2.
///
/// Diretriz:
/// - Outfit para títulos, labels curtos e botões;
/// - Inter para leitura real, descrições, formulários e textos informativos.
///
/// A tipografia prioriza:
/// - legibilidade;
/// - contraste;
/// - espaçamento confortável;
/// - previsibilidade visual;
/// - segurança contra overflow em cards.
class DsTipografia {
  DsTipografia._();

  /// Título principal de página interna.
  static TextStyle get pageTitle => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: DsCores.textPrimary,
        letterSpacing: -0.4,
        height: 1.12,
      );

  /// Subtítulo de página.
  static TextStyle get pageSubtitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: DsCores.textSecondary,
        height: 1.45,
      );

  /// Título de seção.
  static TextStyle get sectionTitle => GoogleFonts.outfit(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: DsCores.textPrimary,
        height: 1.18,
      );

  /// Label curto de seção.
  ///
  /// Usar apenas para rótulos pequenos e curtos.
  /// Evitar frases longas em uppercase.
  static TextStyle get sectionLabel => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: DsCores.textSecondary,
        letterSpacing: 0.8,
        height: 1.2,
      );

  /// Título principal dentro de cards.
  ///
  /// Mantido controlado para funcionar em cards compactos e grids.
  static TextStyle get cardTitle => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: DsCores.textPrimary,
        height: 1.18,
      );

  /// Descrição dentro de cards.
  ///
  /// Legível sem estourar cards de Hub.
  /// Componentes devem usar maxLines e ellipsis.
  static TextStyle get cardDescription => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: DsCores.textSecondary,
        height: 1.35,
      );

  /// Texto atenuado/secundário dentro de cards.
  static TextStyle get cardMuted => GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: DsCores.textMuted,
        height: 1.3,
      );

  /// Texto padrão de leitura.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: DsCores.textPrimary,
        height: 1.45,
      );

  /// Texto secundário de leitura curta.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: DsCores.textSecondary,
        height: 1.4,
      );

  /// Texto de legenda, metadado ou rodapé.
  ///
  /// Não usar para instruções importantes.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: DsCores.textMuted,
        height: 1.35,
      );

  /// Texto informativo, avisos e explicações de suporte.
  static TextStyle get infoBody => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: DsCores.textSecondary,
        height: 1.5,
      );

  /// Texto legal/termos/privacidade.
  static TextStyle get legalBody => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: DsCores.textSecondary,
        height: 1.58,
      );

  /// Título interno de textos legais ou informativos.
  static TextStyle get legalTitle => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DsCores.textPrimary,
        height: 1.25,
      );

  /// Estilo padrão para texto de botões grandes.
  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
        height: 1.15,
      );

  /// Estilo padrão para texto de botões menores.
  static TextStyle get buttonSmall => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
        height: 1.15,
      );

  /// Rótulo pequeno para identificação ou agrupamento.
  static TextStyle get label => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: DsCores.textSecondary,
        height: 1.2,
      );

  /// Label padrão de campos de formulário.
  static TextStyle get inputLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: DsCores.textPrimary,
        height: 1.2,
      );

  /// Texto digitado em campos de formulário.
  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      );

  /// Placeholder/hint em campos de formulário.
  static TextStyle get inputHint => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: DsCores.inputPlaceholder,
        height: 1.3,
      );
}
