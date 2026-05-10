import 'package:flutter/material.dart';

/// Tokens de espaçamento para manter a consistência visual.
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double edge = 24.0;
}

/// Tokens de arredondamento de bordas.
class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
  static const double button = 22.0;
}

/// Definições de sombras do sistema.
class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get dark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
