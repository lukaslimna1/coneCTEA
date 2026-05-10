import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color>? iconGradient;

  const PremiumHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF04152B),
            const Color(0xFF031226).withValues(alpha: 0.95),
            const Color(0xFF020C1C),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 7.1 Luz central suave (Radial Gradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    const Color(0xFF22D3EE).withValues(alpha: 0.06),
                    const Color(0xFF60A5FA).withValues(alpha: 0.04),
                    const Color(0xFFA855F7).withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 6.2 Grids pontilhados laterais
          Positioned(
            left: 20,
            top: 100,
            child: _DottedGrid(
              rows: 10,
              columns: 6,
              color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            right: 20,
            top: 100,
            child: _DottedGrid(
              rows: 10,
              columns: 6,
              color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),
              Stack(
                alignment: Alignment.center,
                children: [
                  // 5) GLOW / BRILHO DO CÍRCULO
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.22),
                          blurRadius: 34,
                          spreadRadius: 2,
                          offset: const Offset(-10, -10),
                        ),
                        BoxShadow(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.18),
                          blurRadius: 34,
                          spreadRadius: 2,
                          offset: const Offset(10, 10),
                        ),
                      ],
                    ),
                  ),

                  // 4) BORDA DO CÍRCULO (Anel externo sutil)
                  Container(
                    width: 195,
                    height: 195,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),

                  // 3) CÍRCULO / ORBE ATRÁS DO ÍCONE
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF071326),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 1.0,
                        colors: [
                          const Color(0xFF9333EA).withValues(alpha: 0.3), // Roxo
                          const Color(0xFF4F46E5).withValues(alpha: 0.2), // Azul
                          const Color(0xFF071326).withValues(alpha: 0.1), // Fundo
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow sutil atrás do ícone para dar profundidade sem criar artefatos
                          Transform.scale(
                            scale: 1.1,
                            child: Icon(
                              icon,
                              size: 84,
                              color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                            ),
                          ),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: iconGradient ?? [
                                  const Color(0xFFA855F7), // Roxo Neon
                                  const Color(0xFF6366F1), // Indigo Neon
                                  const Color(0xFF22D3EE), // Ciano Neon
                                ],
                              ).createShader(bounds);
                            },
                            child: Icon(
                              icon,
                              size: 84,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 6.1 Pontos flutuantes ao redor do círculo
                  ..._buildFloatingPoints(),
                ],
              ),
              const SizedBox(height: 40),
              // 8) TÍTULO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 58,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF8FAFC),
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 8) SUBTÍTULO
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB8C2D6),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingPoints() {
    final points = [
      // (Offset x, Offset y, size, color, opacity)
      const _PointData(-100, -80, 12, Color(0xFFA855F7), 0.9), // Esquerda superior
      const _PointData(-110, 20, 6, Color(0xFF22D3EE), 0.8),  // Esquerda média
      const _PointData(90, -90, 8, Color(0xFF60A5FA), 0.75), // Direita superior
      const _PointData(110, -30, 14, Color(0xFF8B5CF6), 0.85), // Direita média
      const _PointData(70, 90, 10, Color(0xFF22D3EE), 0.8),   // Direita inferior
      const _PointData(-60, 110, 8, Color(0xFFA855F7), 0.6),  // Esquerda inferior
    ];

    return points.map((p) {
      return Positioned(
        left: 110 + p.x, // 110 is center of 220 container
        top: 110 + p.y,
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.color.withValues(alpha: p.opacity),
            boxShadow: [
              BoxShadow(
                color: p.color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _PointData {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double opacity;

  const _PointData(this.x, this.y, this.size, this.color, this.opacity);
}

class _DottedGrid extends StatelessWidget {
  final int rows;
  final int columns;
  final Color color;

  const _DottedGrid({
    required this.rows,
    required this.columns,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(columns, (c) {
            return Container(
              margin: const EdgeInsets.all(4),
              width: 2.5,
              height: 2.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            );
          }),
        );
      }),
    );
  }
}
