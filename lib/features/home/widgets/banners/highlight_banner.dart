import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class BannerTheme {
  final List<Color> backgroundColors;
  final List<Color> primaryGlowColors;
  final List<Color> secondaryGlowColors;
  final Widget customIllustration;
  final String? illustrationAssetPath;
  final Color ctaColor;
  final Color ctaTextColor;

  const BannerTheme({
    required this.backgroundColors,
    required this.primaryGlowColors,
    required this.secondaryGlowColors,
    required this.customIllustration,
    this.illustrationAssetPath,
    required this.ctaColor,
    required this.ctaTextColor,
  });
}

/// Banner institucional premium com design rico em glow, profundidade e ilustrações customizadas.
class HighlightBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;
  final DsCorVisual semanticToken;
  final BannerTheme theme;

  const HighlightBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
    required this.semanticToken,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundColors,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Brilho decorativo dinâmico primário
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: theme.primaryGlowColors,
                    ),
                  ),
                ),
              ),
              // Brilho decorativo dinâmico secundário
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: theme.secondaryGlowColors,
                    ),
                  ),
                ),
              ),
              // Illustration decorativa robusta em Flutter puro ou asset futuro
              if (theme.illustrationAssetPath != null)
                Positioned(
                  right: -40,
                  bottom: -20,
                  top: 20,
                  child: Opacity(
                    opacity: 0.32,
                    child: Image.asset(
                      theme.illustrationAssetPath!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                theme.customIllustration,
              // Camada de proteção de leitura sutil à esquerda
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),
              // Conteúdo textual
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DsSelo.fromCorVisual(
                      label: eyebrow,
                      token: semanticToken,
                      compact: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.58,
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD6E1F0),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.ctaColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: theme.ctaColor.withValues(alpha: 0.5),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                           ),
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctaLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.ctaTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: theme.ctaTextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Camada clicável em todo o container
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
