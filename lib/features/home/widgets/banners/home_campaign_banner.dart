import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class BannerTheme {
  final List<Color> backgroundColors;
  final List<Color> primaryGlowColors;
  final List<Color> secondaryGlowColors;
  final Color ctaColor;
  final Color ctaTextColor;

  // Configuração estruturada da arte decorativa
  final String? illustrationAssetPath;
  final double illustrationOpacity;
  final double illustrationWidthFactor;
  final double illustrationRightOffset;
  final BoxFit illustrationFit;
  final Alignment illustrationAlignment;
  final Widget? customIllustration; // Retrocompatibilidade ou fallback

  const BannerTheme({
    required this.backgroundColors,
    required this.primaryGlowColors,
    required this.secondaryGlowColors,
    required this.ctaColor,
    required this.ctaTextColor,
    this.illustrationAssetPath,
    this.illustrationOpacity = 0.35,
    this.illustrationWidthFactor = 0.65,
    this.illustrationRightOffset = -10,
    this.illustrationFit = BoxFit.cover,
    this.illustrationAlignment = Alignment.centerRight,
    this.customIllustration,
  });
}

/// Banner institucional premium com design rico em glow, profundidade e ilustrações customizadas.
class HomeCampaignBanner extends StatelessWidget {
  final String eyebrow;
  final IconData? eyebrowIcon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onTap;
  final DsCorVisual semanticToken;
  final BannerTheme theme;

  const HomeCampaignBanner({
    super.key,
    required this.eyebrow,
    this.eyebrowIcon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.onTap,
    required this.semanticToken,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 280),
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
              // Illustration decorativa robusta parametrizada e centralizada
              if (theme.illustrationAssetPath != null)
                Positioned(
                  right: theme.illustrationRightOffset,
                  top: 8,
                  bottom: -16, // Permite que a arte sangre na base e não force a altura
                  width: MediaQuery.of(context).size.width * theme.illustrationWidthFactor,
                  child: Opacity(
                    opacity: theme.illustrationOpacity,
                    child: Image.asset(
                      theme.illustrationAssetPath!,
                      fit: theme.illustrationFit,
                      alignment: theme.illustrationAlignment,
                    ),
                  ),
                )
              else if (theme.customIllustration != null)
                theme.customIllustration!,
              // Camada de proteção de leitura sutil à esquerda (reduzida drasticamente)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.40],
                    ),
                  ),
                ),
              ),
              // Conteúdo textual
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DsSelo.fromCorVisual(
                      label: eyebrow,
                      icon: eyebrowIcon,
                      token: semanticToken,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.70, // Texto mais livre, avança sobre a imagem
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.72,
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD6E1F0),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(), // Empurra o CTA para a base (o bottom padding fixa o espaçamento inferior)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.ctaColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: onTap != null
                            ? [
                                BoxShadow(
                                  color: theme.ctaColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctaLabel,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.ctaTextColor,
                            ),
                          ),
                          if (onTap != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: theme.ctaTextColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Camada clicável em todo o container se houver callback
              if (onTap != null)
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
