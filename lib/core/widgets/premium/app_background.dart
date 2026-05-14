import 'package:flutter/material.dart';
import 'package:conectea/core/constants/colors.dart';

/// Plano de fundo dinâmico do aplicativo com estética "Night Blue".
/// Inclui gradientes radiais (glows) e um padrão de pontos (grid) sutil.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showDots;
  final bool showGlows;

  const AppBackground({
    super.key,
    required this.child,
    this.showDots = true,
    this.showGlows = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Fundo Base (Azul Noite Profundo - Gradiente Oficial)
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.nightGradient,
          ),
        ),

        if (showGlows) ...[
          // 2. Brilho Radial no Topo Direito (Glow Azul)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cardElevated.withValues(alpha: 0.20), // Aumentado para visibilidade mobile
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Brilho Radial no Centro Esquerda (Glow Ciano)
          Positioned(
            top: 200,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15), // Aumentado para profundidade
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],

        if (showDots)
          // 4. Padrão de Pontos Refinado (Premium Grid)
          const Positioned.fill(
            child: Opacity(opacity: 0.03, child: DotGridPainter()),
          ),

        // 5. Conteúdo Principal
        child,
      ],
    );
  }
}

/// Widget que desenha uma grade de pontos sutil.
class DotGridPainter extends StatelessWidget {
  const DotGridPainter({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

/// Pintor customizado para a grade de pontos.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
