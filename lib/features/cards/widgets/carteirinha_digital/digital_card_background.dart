import 'package:flutter/material.dart';

/// Widget responsável pela base visual/fundo da carteirinha digital.
/// Contém gradientes, marca d'água e formas geométricas fluidas.
class DigitalCardBackground extends StatefulWidget {
  final Widget child;
  final bool isFront;

  const DigitalCardBackground({
    super.key,
    required this.child,
    this.isFront = true,
  });

  @override
  State<DigitalCardBackground> createState() => _DigitalCardBackgroundState();
}

class _DigitalCardBackgroundState extends State<DigitalCardBackground> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Animação de entrada wave para após 2 segundos para uma apresentação limpa
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _waveController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            // Fundo escuro gradiente (azul-noite institucional)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isFront
                      ? const [
                          Color(0xFF0C2445), // Azul Noite Profundo
                          Color(0xFF10315E), // Azul Noite Principal
                          Color(0xFF1B3D71), // Azul Médio
                        ]
                      : const [
                          Color(0xFF0C2445),
                          Color(0xFF0D1B3E),
                          Color(0xFF10315E),
                        ],
                ),
              ),
            ),

            // Marca d'água (Símbolo marca d’água 60% a 80% da altura da carteirinha, bem transparente)
            Positioned(
              right: -size.width * 0.1,
              bottom: -size.height * 0.1,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08, // Opacidade entre 6% e 12%
                  child: Image.asset(
                    'assets/images/conectea_icon.png',
                    height: size.height * 0.75, // Proporção de 75% da altura
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),

            // Formas geométricas fluidas animadas
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final progress = Curves.easeOutQuart.transform(_waveController.value);
                    return CustomPaint(
                      painter: _GeometricFluidPainter(
                        isFront: widget.isFront,
                        animationProgress: progress,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Conteúdo principal
            widget.child,

            // Borda premium brilhante
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GeometricFluidPainter extends CustomPainter {
  final bool isFront;
  final double animationProgress; // 0.0 a 1.0

  _GeometricFluidPainter({
    required this.isFront,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isFront) {
      _drawBackShapes(canvas, size);
      return;
    }

    final shift = (1.0 - animationProgress) * 50;

    // Gradiente institucional (Azul Noite → Prata/Azul Claro)
    final paintNeon = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF2C5282), // Azul Médio
          Color(0xFF4299E1), // Azul Claro
          Color(0xFFE2E8F0), // Prata
        ],
        stops: [0.0, 0.6, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Azul profundo semi-transparente para contraste
    final paintDeep = Paint()
      ..color = const Color(0x44000D2A)
      ..style = PaintingStyle.fill;

    // Forma topo-direita
    final pathTop = Path()
      ..moveTo(size.width * 0.45 + shift, 0)
      ..lineTo(size.width * 0.65, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.25, size.width, size.height * 0.2 - shift)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(pathTop, paintDeep);

    final pathTopNeon = Path()
      ..moveTo(size.width * 0.6 + shift, 0)
      ..lineTo(size.width * 0.75, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.15, size.width, size.height * 0.1 - shift)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(pathTopNeon, paintNeon);

    // Forma baixo-direita
    final pathBotDeep = Path()
      ..moveTo(size.width * 0.25 - shift, size.height)
      ..lineTo(size.width * 0.65, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.45, size.width, size.height * 0.35 + shift)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(pathBotDeep, paintDeep);

    final pathBotNeon = Path()
      ..moveTo(size.width * 0.45 - shift, size.height)
      ..lineTo(size.width * 0.75, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.6, size.width, size.height * 0.5 + shift)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(pathBotNeon, paintNeon);

    // Pontos decorativos flutuantes
    if (animationProgress > 0.1) {
      final dp = (animationProgress - 0.1) / 0.9;
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 6.0 * dp,
          Paint()..color = const Color(0xFF4299E1).withValues(alpha: 0.4));
      canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.22), 3.5 * dp,
          Paint()..color = const Color(0xFFE2E8F0).withValues(alpha: 0.5));
      canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.92), 2.5 * dp,
          Paint()..color = const Color(0xFF2C5282).withValues(alpha: 0.3));
    }
  }

  void _drawBackShapes(Canvas canvas, Size size) {
    final shift = (1.0 - animationProgress) * 30;

    // Linha neon no fundo do verso
    final paintCyan = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x0010315E), Color(0x664299E1), Color(0x0010315E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.85 + shift)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.75 + shift, size.width, size.height * 0.9 + shift)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paintCyan);
  }

  @override
  bool shouldRepaint(covariant _GeometricFluidPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.isFront != isFront;
  }
}
