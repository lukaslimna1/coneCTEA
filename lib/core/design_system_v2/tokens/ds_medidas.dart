import 'package:flutter/material.dart';

/// Tokens de espaçamento do Design System V2.
///
/// Usados para paddings, gaps e margens recorrentes.
class DsEspacamentos {
  DsEspacamentos._();

  static const double none = 0.0;
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Padding lateral padrão de tela.
  static const double edge = 24.0;
}

/// Tokens de arredondamento de bordas do Design System V2.
class DsRaios {
  DsRaios._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
  static const double xxl = 32.0;

  static const double button = 22.0;
  static const double input = 16.0;
  static const double card = 24.0;
  static const double modal = 28.0;
  static const double pill = 999.0;
}

/// Tokens de tamanho recorrente do Design System V2.
///
/// Usados para evitar alturas e tamanhos mágicos espalhados em componentes.
class DsTamanhos {
  DsTamanhos._();

  static const double minTouchTarget = 48.0;

  static const double buttonHeight = 50.0;
  static const double buttonHeightSmall = 42.0;

  static const double inputHeight = 54.0;
  static const double inputHeightSmall = 46.0;

  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  static const double iconFrameSm = 42.0;
  static const double iconFrameMd = 48.0;
  static const double iconFrameLg = 56.0;
}

/// Definições de sombras e glows do Design System V2.
class DsSombras {
  DsSombras._();

  static const List<BoxShadow> none = [];

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get dark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.50),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Sombra padrão para cards premium.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Sombra para elementos elevados, como modais e painéis flutuantes.
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// Sombra para modais premium.
  static List<BoxShadow> get modal => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  /// Glow genérico controlado por cor.
  static List<BoxShadow> glow(
    Color color, {
    double alpha = 0.12,
    double blurRadius = 18,
    double spreadRadius = 0,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  /// Glow semântico sutil para cards, ícones e destaques de baixa intensidade.
  static List<BoxShadow> semanticGlow(Color color) {
    return glow(
      color,
      alpha: 0.06,
      blurRadius: 22,
      spreadRadius: 0,
    );
  }
}
