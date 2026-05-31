import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

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



  @override
  Widget build(BuildContext context) {
    // Seleção da paleta determinística
    final DsPaletteAvatar palette = _getDeterministicPalette();

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

    final double effectiveBorderWidth =
        borderWidth ?? (size * 0.05).clamp(1.5, 3.5);

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
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitials(size),
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

  DsPaletteAvatar _getDeterministicPalette() {
    return DsPaletasAvatar.getDeterministicPalette(paletteSeed, initials);
  }
}
