import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';

import 'dart:math' as math;

class DsLoadingSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const DsLoadingSpinner({
    super.key,
    this.size = DsTamanhos.iconLg,
    this.strokeWidth = 5.0,
  });

  @override
  State<DsLoadingSpinner> createState() => _DsLoadingSpinnerState();
}

class _DsLoadingSpinnerState extends State<DsLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return SizedBox(
          width: widget.size * 1.6,
          height: widget.size,
          child: CustomPaint(
            painter: _InfinityPainter(
              strokeWidth: widget.strokeWidth,
              rotation: _controller.value * 2 * math.pi,
            ),
          ),
        );
      },
    );
  }
}

class _InfinityPainter extends CustomPainter {
  final double strokeWidth;
  final double rotation;

  _InfinityPainter({
    required this.strokeWidth,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Draw the infinity symbol path using bezier curves
    final path = Path();
    path.moveTo(w * 0.5, h * 0.5);
    
    // Right loop
    path.cubicTo(
      w * 0.7, h * 0.1, 
      w * 1.0, h * 0.1, 
      w * 1.0, h * 0.5,
    );
    path.cubicTo(
      w * 1.0, h * 0.9, 
      w * 0.7, h * 0.9, 
      w * 0.5, h * 0.5,
    );

    // Left loop
    path.cubicTo(
      w * 0.3, h * 0.1, 
      0, h * 0.1, 
      0, h * 0.5,
    );
    path.cubicTo(
      0, h * 0.9, 
      w * 0.3, h * 0.9, 
      w * 0.5, h * 0.5,
    );

    // Create the rotating sweep gradient based on the animation value
    final rect = Rect.fromLTWH(0, 0, w, h);
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(rotation),
      colors: [
        DsCores.admin.accent,
        DsCores.sucesso.accent,
        DsCores.suporte.accent,
        DsCores.conta.accent,
        DsCores.admin.accent,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = sweepGradient.createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InfinityPainter oldDelegate) {
    return oldDelegate.rotation != rotation || 
           oldDelegate.strokeWidth != strokeWidth;
  }
}
