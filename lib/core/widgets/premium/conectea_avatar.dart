import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Componente Mestre de Avatar do ConeCTEA - Refinamento Premium Circular.
/// 
/// Identidade visual proprietária:
/// - Formato Circular (Foco em representação humana).
/// - Fundo "Lunar Glass" (Dark Glass com reflexos diagonais).
/// - Anel "Em Breve" (Gradiente triplo luminoso de alta performance).
/// - Paleta Determinística (Identidade visual pessoal baseada no titular).
class ConecteaAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? accentColor;
  final String? imageUrl;
  final String? role;
  final String? semanticLabel;
  final double? borderWidth;
  final bool showGlow;
  final bool isInactive;
  final String? paletteSeed;

  const ConecteaAvatar({
    super.key,
    required this.initials,
    required this.size,
    this.accentColor,
    this.imageUrl,
    this.role,
    this.semanticLabel,
    this.borderWidth,
    this.showGlow = false,
    this.isInactive = false,
    this.paletteSeed,
  });

  /// Paletas premium neon/tech oficiais do ConeCTEA (P01 a P15).
  /// A ordem desta lista deve permanecer estável após o lançamento para manter a identidade determinística.
  static const List<_ConecteaPalette> _premiumPalettes = [
    _ConecteaPalette(primary: Color(0xFF8B3DFF), harmonic: Color(0xFF2F80ED), contrast: Color(0xFF14D9D0)), // P01 - ConeCTEA Classic
    _ConecteaPalette(primary: Color(0xFF39FF14), harmonic: Color(0xFF00B894), contrast: Color(0xFF0077FF)), // P02 - Matrix Aurora
    _ConecteaPalette(primary: Color(0xFFFF6B00), harmonic: Color(0xFFFFD60A), contrast: Color(0xFFFF2D95)), // P03 - Solar Pulse
    _ConecteaPalette(primary: Color(0xFFF000FF), harmonic: Color(0xFF6D28D9), contrast: Color(0xFF00E5FF)), // P04 - Cyber Magenta
    _ConecteaPalette(primary: Color(0xFF00FF85), harmonic: Color(0xFF00C2A8), contrast: Color(0xFF245BFF)), // P05 - Emerald Circuit
    _ConecteaPalette(primary: Color(0xFF3A0CA3), harmonic: Color(0xFF4361EE), contrast: Color(0xFF4CC9F0)), // P06 - Royal Laser
    _ConecteaPalette(primary: Color(0xFFFF3366), harmonic: Color(0xFFFF8A00), contrast: Color(0xFFFFE600)), // P07 - Hyper Coral
    _ConecteaPalette(primary: Color(0xFFB517FF), harmonic: Color(0xFF7209B7), contrast: Color(0xFF00F5D4)), // P08 - Toxic Violet
    _ConecteaPalette(primary: Color(0xFF00A3FF), harmonic: Color(0xFF7B2CFF), contrast: Color(0xFF00FFB2)), // P09 - Ice Voltage
    _ConecteaPalette(primary: Color(0xFFFF1744), harmonic: Color(0xFFD500F9), contrast: Color(0xFF2979FF)), // P10 - Neon Ruby
    _ConecteaPalette(primary: Color(0xFFA3FF12), harmonic: Color(0xFF18FFFF), contrast: Color(0xFF651FFF)), // P11 - Acid Lime
    _ConecteaPalette(primary: Color(0xFFAA00FF), harmonic: Color(0xFF304FFE), contrast: Color(0xFF64FFDA)), // P12 - Deep Plasma
    _ConecteaPalette(primary: Color(0xFFFF3D00), harmonic: Color(0xFFFFEA00), contrast: Color(0xFF00B0FF)), // P13 - Flame Tech
    _ConecteaPalette(primary: Color(0xFF00E676), harmonic: Color(0xFF1DE9B6), contrast: Color(0xFF6200EA)), // P14 - Quantum Green
    _ConecteaPalette(primary: Color(0xFFFF00A8), harmonic: Color(0xFF7C4DFF), contrast: Color(0xFF00FFF0)), // P15 - Pink Circuit
  ];

  @override
  Widget build(BuildContext context) {
    // Seleção da paleta determinística
    final _ConecteaPalette palette = _getDeterministicPalette();
    
    // A cor de acento manual só sobrescreve se não houver paletteSeed (respeitando a regra do titular)
    final Color primaryColor = (paletteSeed == null || paletteSeed!.isEmpty) 
        ? (accentColor ?? palette.primary) 
        : palette.primary;
    
    // Gradiente do Anel (Ativo: Neon Tech | Inativo: Dimmed Silver)
    final List<Color> ringGradient = isInactive
      ? [
          const Color(0xFF94A3B8).withValues(alpha: 0.5),
          const Color(0xFFE2E8F0),
          const Color(0xFF475569).withValues(alpha: 0.4),
          const Color(0xFF94A3B8).withValues(alpha: 0.5),
        ]
      : palette.ringColors;
    
    final double effectiveBorderWidth = borderWidth ?? (size * 0.05).clamp(1.5, 3.5);

    return Semantics(
      label: semanticLabel ?? 'Avatar de $initials',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Aura de Profundidade (Glow sutil)
            if (showGlow && !isInactive)
              Container(
                width: size * 0.9,
                height: size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: size * 0.25,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

            // 2. Anel Premium (Moldura Luminosa Sweep)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: ringGradient,
                  stops: const [0.0, 0.33, 0.66, 1.0],
                  transform: const GradientRotation(-1.5),
                ),
              ),
            ),

            // 3. Fundo "Lunar Glass" (Corpo do Avatar)
            Container(
              width: size - (effectiveBorderWidth * 2),
              height: size - (effectiveBorderWidth * 2),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isInactive
                      ? [const Color(0xFF475569), const Color(0xFF1E293B)]
                      : [const Color(0xFF0F172A), const Color(0xFF020617)],
                ),
              ),
              child: Stack(
                children: [
                  // 4. Reflexo de Vidro Diagonal
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: const Alignment(-0.8, -0.8),
                          end: const Alignment(0.8, 0.8),
                          colors: [
                            Colors.white.withValues(alpha: 0.07),
                            Colors.white.withValues(alpha: 0.02),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.01),
                          ],
                          stops: const [0.0, 0.2, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 5. Brilho Superior
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: size * 0.3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 6. Conteúdo (Imagem ou Iniciais)
                  Center(
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildInitials(size),
                          )
                        : _buildInitials(size),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(double size) {
    String display = initials.trim();
    if (display.length > 1) {
      final parts = display.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        display = "${parts.first[0]}${parts.last[0]}";
      } else {
        display = display.substring(0, 2);
      }
    }
    
    return Text(
      display.toUpperCase(),
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        color: Colors.white.withValues(alpha: 0.95),
        fontSize: size * 0.38,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  _ConecteaPalette _getDeterministicPalette() {
    // A paletteSeed (ID do titular) é a prioridade absoluta
    if (paletteSeed != null && paletteSeed!.isNotEmpty) {
      return _premiumPalettes[paletteSeed.hashCode.abs() % _premiumPalettes.length];
    }
    
    // Fallback: determinístico pelas iniciais
    final int seed = initials.isNotEmpty ? initials.codeUnits.fold(0, (prev, element) => prev + element) : 0;
    return _premiumPalettes[seed.abs() % _premiumPalettes.length];
  }
}

/// Representa uma paleta neon/tech do ConeCTEA.
class _ConecteaPalette {
  final Color primary;
  final Color harmonic;
  final Color contrast;

  const _ConecteaPalette({
    required this.primary,
    required this.harmonic,
    required this.contrast,
  });

  /// Gera a lista de cores para o gradiente do anel (primary -> harmonic -> contrast -> primary).
  List<Color> get ringColors => [primary, harmonic, contrast, primary];
}
