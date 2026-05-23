import 'package:flutter/material.dart';

/// **DsPaletteAvatar** — Representa uma paleta de cores neon/tech premium para avatares na DS V2.
class DsPaletteAvatar {
  final Color primary;
  final Color harmonic;
  final Color contrast;

  const DsPaletteAvatar({
    required this.primary,
    required this.harmonic,
    required this.contrast,
  });

  /// Cores sequenciais para compor o anel luminoso sweep (primary -> harmonic -> contrast -> primary).
  List<Color> get ringColors => [primary, harmonic, contrast, primary];
}

/// **DsPaletasAvatar** — Centralizador de paletas neon oficiais da DS V2 do ConeCTEA.
class DsPaletasAvatar {
  DsPaletasAvatar._();

  /// Lista estável de 20 paletas premium neon oficiais do ConeCTEA DS V2 (P01 a P20).
  ///
  /// IMPORTANTE: A ordem destas paletas deve permanecer estritamente estável após a
  /// adoção definitiva do aplicativo em produção para assegurar que a semente determinística
  /// dos avatares dos usuários não mude abruptamente.
  static const List<DsPaletteAvatar> premiumPalettes = [
    DsPaletteAvatar(primary: Color(0xFF8B3DFF), harmonic: Color(0xFF2F80ED), contrast: Color(0xFF14D9D0)), // P01
    DsPaletteAvatar(primary: Color(0xFF39FF14), harmonic: Color(0xFF00B894), contrast: Color(0xFF0077FF)), // P02
    DsPaletteAvatar(primary: Color(0xFFFF6B00), harmonic: Color(0xFFFFD60A), contrast: Color(0xFFFF2D95)), // P03
    DsPaletteAvatar(primary: Color(0xFFF000FF), harmonic: Color(0xFF6D28D9), contrast: Color(0xFF00E5FF)), // P04
    DsPaletteAvatar(primary: Color(0xFF00FF85), harmonic: Color(0xFF00C2A8), contrast: Color(0xFF245BFF)), // P05
    DsPaletteAvatar(primary: Color(0xFF3A0CA3), harmonic: Color(0xFF4361EE), contrast: Color(0xFF4CC9F0)), // P06
    DsPaletteAvatar(primary: Color(0xFFFF3366), harmonic: Color(0xFFFF8A00), contrast: Color(0xFFFFE600)), // P07
    DsPaletteAvatar(primary: Color(0xFFB517FF), harmonic: Color(0xFF7209B7), contrast: Color(0xFF00F5D4)), // P08
    DsPaletteAvatar(primary: Color(0xFF00A3FF), harmonic: Color(0xFF7B2CFF), contrast: Color(0xFF00FFB2)), // P09
    DsPaletteAvatar(primary: Color(0xFFFF1744), harmonic: Color(0xFFD500F9), contrast: Color(0xFF2979FF)), // P10
    DsPaletteAvatar(primary: Color(0xFFA3FF12), harmonic: Color(0xFF18FFFF), contrast: Color(0xFF651FFF)), // P11
    DsPaletteAvatar(primary: Color(0xFFAA00FF), harmonic: Color(0xFF304FFE), contrast: Color(0xFF64FFDA)), // P12
    DsPaletteAvatar(primary: Color(0xFFFF3D00), harmonic: Color(0xFFFFEA00), contrast: Color(0xFF00B0FF)), // P13
    DsPaletteAvatar(primary: Color(0xFF00E676), harmonic: Color(0xFF1DE9B6), contrast: Color(0xFF6200EA)), // P14
    DsPaletteAvatar(primary: Color(0xFFFF00A8), harmonic: Color(0xFF7C4DFF), contrast: Color(0xFF00FFF0)), // P15
    DsPaletteAvatar(primary: Color(0xFFFFD700), harmonic: Color(0xFFFFA500), contrast: Color(0xFFFF4500)), // P16
    DsPaletteAvatar(primary: Color(0xFF00F2FE), harmonic: Color(0xFF4FACFE), contrast: Color(0xFF0000FF)), // P17
    DsPaletteAvatar(primary: Color(0xFFAB47BC), harmonic: Color(0xFFEC407A), contrast: Color(0xFFFF7043)), // P18
    DsPaletteAvatar(primary: Color(0xFF80F3B9), harmonic: Color(0xFF2DE1FC), contrast: Color(0xFF07BEB8)), // P19
    DsPaletteAvatar(primary: Color(0xFFFF3300), harmonic: Color(0xFFD80032), contrast: Color(0xFF2B2D42)), // P20
  ];

  /// Seleciona de forma 100% determinística uma paleta com base em uma semente
  /// ou fallback por iniciais, usando o operador % 20.
  static DsPaletteAvatar getDeterministicPalette(String? paletteSeed, String initials) {
    if (paletteSeed != null && paletteSeed.isNotEmpty) {
      return premiumPalettes[paletteSeed.hashCode.abs() % premiumPalettes.length];
    }

    final int seed = initials.isNotEmpty
        ? initials.codeUnits.fold(0, (prev, element) => prev + element)
        : 0;
    return premiumPalettes[seed.abs() % premiumPalettes.length];
  }
}
