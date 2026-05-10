import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

/// Configuração global do tema do Flutter para o aplicativo.
/// Implementa o "Night Mode" como padrão e define estilos de componentes (Botões, Inputs, Cards).
class AppTheme {
  /// Retorna o tema principal do aplicativo (Escuro/Night).
  static ThemeData get nightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.cyan,
        surface: AppColors.surfaceCard,
        error: AppColors.errorRed,
        onSurface: AppColors.cardTitle,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // Configuração de Tipografia Global
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: AppColors.cardTitle, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: AppColors.cardTitle, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: AppColors.cardTitle, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(color: AppColors.cardTitle, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: AppColors.cardTitle),
        bodyMedium: GoogleFonts.inter(color: AppColors.cardTitle),
        bodySmall: GoogleFonts.inter(color: AppColors.cardSubtitle),
        labelLarge: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),

      // Estilização de Botões Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.ctaText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      
      // Estilização de Botões de Contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cardTitle,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // Estilização de Campos de Entrada (Night Edition)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.inputPlaceholder),
        prefixIconColor: AppColors.iconMuted,
        suffixIconColor: AppColors.iconMuted,
      ),

      // Estilização de Cards Padrão
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),

      // Estilização da Barra de Navegação Inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.iconMuted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  /// Retorna o tema claro (Manteúdo para compatibilidade futura).
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      // Configurações simplificadas para fallback
    );
  }
}
