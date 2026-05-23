import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **DsAvatar** — Componente de Avatar Oficial da Design System V2 (DS V2).
///
/// Apresenta o usuário em formato circular com estética Night Blue / Dark Glass Premium.
/// Consome a lógica centralizada de 20 paletas neon/tech unificada da DS V2.
class DsAvatar extends StatelessWidget {
  /// As iniciais a serem renderizadas no avatar (máximo de 2 caracteres).
  final String initials;

  /// Diâmetro total do avatar.
  final double size;

  /// Semente opcional para determinar a paleta de cores de forma determinística.
  final String? paletteSeed;

  /// URL opcional da imagem de perfil do usuário.
  final String? imageUrl;

  /// Rótulo de acessibilidade (Semantics).
  final String? semanticLabel;

  /// Se deve exibir um brilho (glow) luminoso externo sutil em torno do avatar.
  final bool showGlow;

  /// Se o avatar representa um usuário inativo (aplica tons acinzentados).
  final bool isInactive;

  /// Se o avatar está selecionado (renderiza um anel de destaque externo premium).
  final bool isSelected;

  const DsAvatar({
    super.key,
    required this.initials,
    this.size = 44.0,
    this.paletteSeed,
    this.imageUrl,
    this.semanticLabel,
    this.showGlow = false,
    this.isInactive = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Obtém a paleta unificada de 20 cores da DS V2
    final DsPaletteAvatar palette = DsPaletasAvatar.getDeterministicPalette(paletteSeed, initials);
    final Color primaryColor = palette.primary;

    // Espessura do anel luminoso principal (borderWidth)
    final double effectiveBorderWidth = (size * 0.055).clamp(1.5, 3.5);

    // Gradiente do anel luminoso principal (Neon ativo ou Prata inativo)
    final List<Color> ringGradient = isInactive
        ? [
            const Color(0xFF94A3B8).withValues(alpha: 0.5),
            const Color(0xFFE2E8F0),
            const Color(0xFF475569).withValues(alpha: 0.4),
            const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ]
        : palette.ringColors;

    // Tamanho do corpo interno do avatar dependendo se há anel de seleção ativo
    final double selectionGap = isSelected ? 4.0 : 0.0;
    final double avatarSize = size - (selectionGap * 2);

    return Semantics(
      label: semanticLabel ?? 'Avatar de $initials',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Anel de Destaque para Estado Selecionado (isSelected)
            if (isSelected && !isInactive)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.8),
                    width: 2.0,
                  ),
                ),
              ),

            // 2. Glow Luminoso Sutil
            if (showGlow && !isInactive)
              Container(
                width: avatarSize * 0.9,
                height: avatarSize * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.18),
                      blurRadius: avatarSize * 0.25,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
              ),

            // 3. Anel Luminoso Sweep Principal do Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: ringGradient,
                  stops: const [0.0, 0.33, 0.66, 1.0],
                  transform: const GradientRotation(-1.5),
                ),
              ),
            ),

            // 4. Corpo "Lunar Glass" do Avatar
            Container(
              width: avatarSize - (effectiveBorderWidth * 2),
              height: avatarSize - (effectiveBorderWidth * 2),
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
                  // Reflexo de Vidro Diagonal
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: const Alignment(-0.8, -0.8),
                          end: const Alignment(0.8, 0.8),
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.02),
                          ],
                          stops: const [0.0, 0.25, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Brilho Superior
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: avatarSize * 0.32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo: Imagem de perfil ou Iniciais como Fallback
                  Center(
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitials(avatarSize),
                          )
                        : _buildInitials(avatarSize),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(double targetSize) {
    String display = initials.trim();
    if (display.isEmpty) {
      display = '--';
    } else if (display.length > 1) {
      final parts = display.split(RegExp(r'\s+'));
      if (parts.length > 1) {
        display = '${parts.first[0]}${parts.last[0]}';
      } else {
        display = display.substring(0, 2);
      }
    }

    return Text(
      display.toUpperCase(),
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        color: Colors.white.withValues(alpha: 0.95),
        fontSize: targetSize * 0.38,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
    );
  }
}
