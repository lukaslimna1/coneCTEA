import 'package:flutter/material.dart';

/// Definição centralizada da paleta de cores do sistema ConeCTEA.
/// Baseada no design system "Night Blue" com estética Glassmorphism.
class AppColors {
  // --- PALETA NIGHT BLUE (DARK MODE PADRÃO) ---
  static const Color primary = Color(0xFF7C3AED); // Roxo ConeCTEA (Soft Purple Premium)
  static const Color cyan = Color(0xFF14D9D0); // Ciano ConeCTEA (Neon)
  
  // Fundos
  static const Color background = Color(0xFF071326); // Azul Noite Profundo (Navy Black)
  static const Color cardBackground = Color(0xFF0B1D3A); // Cards principais
  static const Color cardElevated = Color(0xFF102A4C); // Cards em destaque
  static const Color borderLight = Color(0xFF1E4A7A); // Bordas sutis
  
  // Textos
  static const Color textPrimary = Color(0xFFF8FAFC); // Branco suave
  static const Color textSecondary = Color(0xFFB8C7E6); // Azul claro acinzentado
  
  // Status
  static const Color statusGreen = Color(0xFF34D399); // Verde Sucesso
  static const Color alertOrange = Color(0xFFF59E0B); // Laranja Alerta
  static const Color errorRed = Color(0xFFEF4444); // Vermelho Erro

  // Tipografia dos Cards
  static const Color cardTitle = Color(0xFFF8FAFC);
  static const Color cardSubtitle = Color(0xFFD6E2F5);
  static const Color cardMutedText = Color(0xFF9FB2D6);

  // Surfaces e Fundos Elevados
  static const Color surfaceDark = Color(0xFF0A2145);
  static const Color surfaceCard = Color(0xFF10315E);
  static const Color surfaceCardHover = Color(0xFF163F72);

  // Ícones e Contêineres de Ícones
  static const Color iconPrimary = Color(0xFFF8FAFC);
  static const Color iconSecondary = Color(0xFFB8C7E6);
  static const Color iconMuted = Color(0xFF8FA3C7);
  static const Color purpleIconBg = Color(0x267C3AED);
  static const Color cyanIconBg = Color(0x2614D9D0);
  static const Color greenIconBg = Color(0x2634D399);
  static const Color orangeIconBg = Color(0x26F59E0B);

  // CTAs e Inputs
  static const Color ctaText = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFF10315E);
  static const Color inputBorder = Color(0xFF2A5B8F);
  static const Color inputPlaceholder = Color(0xFF9FB2D6);

  // Compatibilidade com código legado (mapeando para a nova paleta)
  static const Color darkBlue = Color(0xFF071B3A);
  static const Color backgroundLight = Color(0xFF071B3A);
  static const Color backgroundPremium = Color(0xFF071B3A);
  static const Color whiteCard = Color(0xFF0E2A52);
  static const Color shadowColor = Color(0x1A000000);
  static const Color successGreen = Color(0xFF34D399);
  
  // Cores Administrativas
  static const Color adminPositive = Color(0xFF34D399);
  static const Color adminAnalysis = Color(0xFFF59E0B);
  static const Color adminRequest = Color(0xFF3B82F6);
  static const Color adminDanger = Color(0xFFEF4444);
  static const Color adminBlock = Color(0xFF1F2937);

  // Mapeamento de cores legadas (Correção de Erros de Compilação)
  static const Color purpleLight = Color(0xFF123867); // Mapeado para cardElevated
  static const Color cardBlue = Color(0xFF1E4A7A); // Mapeado para borderLight
  static const Color warning = Color(0xFFF59E0B); // Mapeado para alertOrange
  static const Color statusOrange = Color(0xFFF59E0B); // Mapeado para alertOrange
  static const Color teal = Color(0xFF14D9D0); // Mapeado para cyan
  static const Color purple = Color(0xFF7C3AED);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Gradientes
  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF102A4C),
      Color(0xFF0B1D3A),
      Color(0xFF071326),
    ],
  );

  static const LinearGradient premiumCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF102A4C),
      Color(0xFF0B1D3A),
      Color(0xFF08162D),
    ],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14D9D0), Color(0xFF0EA8A1)],
  );
}
