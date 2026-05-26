import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card de acesso rápido premium com design Night Blue (Glassmorphism).
/// Utilizado na HomeView para atalhos principais.
class QuickAccessCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width, maxWidth: width),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0A192F), // Tom de fundo profundo
                    Color(0xFF060D1A), // Quase preto como o background real
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0x2494A3B4), // rgba(148,163,184,0.14)
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Camada de vidro sutil
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.025),
                      ),
                    ),
                  ),
                  // Efeito de luz sutil no canto (Glow)
                  Positioned(
                    bottom: -40,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.12),
                            accentColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Borda superior colorida
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 14,
                      left: 16,
                      right: 16,
                      bottom: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bloco Superior: Ícone + Textos
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Moldura do ícone
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF020617,
                                ).withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.50),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      icon,
                                      color: const Color(0xFFF8FAFC),
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF8FAFC),
                                      height: 1.05,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFB8C2D6),
                                      height: 1.26,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // CTA Button
                        Container(
                          height: 40,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F234B,
                            ).withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.65),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ctaLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: accentColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
