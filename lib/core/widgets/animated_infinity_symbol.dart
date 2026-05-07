import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedInfinitySymbol extends StatefulWidget {
  final double width;
  final double height;
  
  const AnimatedInfinitySymbol({
    super.key,
    this.width = 150,
    this.height = 70,
  });

  @override
  State<AnimatedInfinitySymbol> createState() => _AnimatedInfinitySymbolState();
}

class _AnimatedInfinitySymbolState extends State<AnimatedInfinitySymbol> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: InfinityPainter(_controller.value),
        );
      },
    );
  }
}

class InfinityPainter extends CustomPainter {
  final double animationValue;

  InfinityPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Parâmetros para curva suave do infinito
    path.moveTo(w * 0.5, h * 0.5);
    // Lado direito
    path.cubicTo(w * 0.6, 0, w, 0, w, h * 0.5);
    path.cubicTo(w, h, w * 0.6, h, w * 0.5, h * 0.5);
    // Lado esquerdo
    path.cubicTo(w * 0.4, 0, 0, 0, 0, h * 0.5);
    path.cubicTo(0, h, w * 0.4, h, w * 0.5, h * 0.5);

    // Cores da Neurodiversidade (TEA)
    final colors = [
      const Color(0xFFFF3B30), // Vermelho
      const Color(0xFFFF9500), // Laranja
      const Color(0xFFFFCC00), // Amarelo
      const Color(0xFF34C759), // Verde
      const Color(0xFF007AFF), // Azul
      const Color(0xFFAF52DE), // Roxo
      const Color(0xFFFF3B30), // Retorna ao Vermelho
    ];

    final rect = Rect.fromLTWH(0, 0, w, h);
    
    // O SweepGradient girando cria o efeito de "fluxo" pela linha
    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(animationValue * 2 * math.pi),
      center: Alignment.center,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sombra suave para o traço
    final shadowPaint = Paint()
      ..color = colors[5].withValues(alpha: 0.2) // Sombra roxa suave
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant InfinityPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
