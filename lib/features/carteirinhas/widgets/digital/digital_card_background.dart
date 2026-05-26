import 'package:flutter/material.dart';

/// Widget responsável pela base visual/fundo da carteirinha digital.
/// Contém gradientes, marca d'água e formas geométricas fluidas premium ("Sapphire Luxe").
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

class _DigitalCardBackgroundState extends State<DigitalCardBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Animação de entrada wave suave que para após 2.5 segundos para apresentação limpa
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
            // Fundo escuro gradiente (Safira Deep-Navy - Contraste monumental de luxo)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isFront
                      ? const [
                          Color(
                            0xFF020B1E,
                          ), // Sapphire Luxe - Azul Noite Escuro Sofisticado (Substitui o quase preto)
                          Color(
                            0xFF0A2254,
                          ), // Sapphire Luxe - Azul Safira Profundo Luminoso
                          Color(
                            0xFF143B80,
                          ), // Sapphire Luxe - Azul Safira Real Vibrante (Nuance mais clara e viva)
                        ]
                      : const [
                          Color(0xFF020B1E),
                          Color(0xFF0A2254),
                          Color(
                            0xFF163C7F,
                          ), // Nuance ligeiramente mais clara no canto do verso
                        ],
                ),
              ),
            ),

            // Marca d'água ConeCTEA (Posicionamento e opacidade ultra-sutis para sofisticação abstrata)
            Positioned(
              right: size.width * 0.05,
              bottom: size.height * 0.02,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.07, // Opacidade delicada de 7%
                  child: Image.asset(
                    'assets/images/conectea_icon.png',
                    height: size.height * 0.46, // Proporção refinada
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),

            // Formas de luz e filamentos finos Lines Lux premium
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final progress = Curves.easeOutQuart.transform(
                      _waveController.value,
                    );
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

            // Conteúdo principal (fotos, dados, labels, QR Code)
            widget.child,
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
    // 1. Desenhar a borda de vidro reflexiva com feixes de luz direcionais (Chanfro 2.5D lapidado)
    _drawGlowingBorder(canvas, size);

    if (!isFront) {
      _drawBackShapes(canvas, size);
      return;
    }

    // Controle dinâmico sutil da animação (suavidade e elegância premium)
    final shift = (1.0 - animationProgress) * 35;

    // ==========================================
    // CAMADA DE VÉUS SUAVES DE LUZ (Auroras Volumétricas Translúcidas)
    // ==========================================

    // Véu 1 (Neblina Ciano no Canto Inferior Direito - Suporte e profundidade)
    final paintVeil1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0x1414D9D0), // Ciano ultra-suave (8%)
              const Color(0x042563EB), // Azul Royal (2%)
              const Color(0x00000000), // Totalmente transparente
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.85 + shift,
                size.height * 0.85 + shift,
              ),
              radius: size.width * 0.5,
            ),
          )
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38.0);

    canvas.drawCircle(
      Offset(size.width * 0.85 + shift, size.height * 0.85 + shift),
      size.width * 0.5,
      paintVeil1,
    );

    // Véu 2 (Aurora Azul Safira no Canto Superior Esquerdo - Equilíbrio de cores)
    final paintVeil2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0x102563EB), // Azul Safira sutil (6%)
              const Color(0x0314D9D0), // Ciano (1%)
              const Color(0x00000000), // Transparente
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.20 - shift,
                size.height * 0.20 - shift,
              ),
              radius: size.width * 0.45,
            ),
          )
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32.0);

    canvas.drawCircle(
      Offset(size.width * 0.20 - shift, size.height * 0.20 - shift),
      size.width * 0.45,
      paintVeil2,
    );

    // Véu 3 (Aurora Central de Luz Ciano - Textura de profundidade no centro dos dados)
    final paintVeil3 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0x0B14D9D0), // Ciano sutilíssimo (4%)
              const Color(0x00000000), // Transparente
            ],
            stops: const [0.0, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.60, size.height * 0.45),
              radius: size.width * 0.35,
            ),
          )
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28.0);

    canvas.drawCircle(
      Offset(size.width * 0.60, size.height * 0.45),
      size.width * 0.35,
      paintVeil3,
    );

    // ==========================================
    // DUAS LINHAS FINAS E SEMI-LUMINOSAS (Lines Lux - Curvas Cúbicas de Bézier em S)
    // ==========================================

    // LINHA 1 (Órbita Inferior Assimétrica)
    final path1 = Path()
      ..moveTo(-50, size.height * 0.85)
      ..cubicTo(
        size.width * 0.35 - shift * 0.5,
        size.height * 0.96, // Ponto de controle 1
        size.width * 0.68 - shift * 0.3,
        size.height * 0.55, // Ponto de controle 2
        size.width + 50,
        size.height * 0.38, // Ponto final
      );

    // Pintura do Glow Amplo e Etéreo para a Linha 1 (Evita linhas duras na tela)
    final glowPaint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x002563EB), // Entrada invisível
          const Color(0x1B2563EB), // Safira Glow suave (10%)
          const Color(0x2814D9D0), // Ciano Glow suave (15%)
          const Color(0x0014D9D0), // Saída invisível
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    // Pintura do Filamento Fino de Luz (Lines Lux) para a Linha 1
    final corePaint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x0014D9D0), // Transparente nas pontas
          const Color(0xCC2563EB), // Safira (80% opacidade)
          const Color(0xFFFFFFFF), // Core branco brilhante para realce de luz
          const Color(0xCC14D9D0), // Ciano (80% opacidade)
          const Color(0x0014D9D0), // Transparente nas pontas
        ],
        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawPath(path1, glowPaint1);
    canvas.drawPath(path1, corePaint1);

    // LINHA 2 (Órbita Direita/Superior Assimétrica)
    final path2 = Path()
      ..moveTo(size.width * 0.52, size.height + 50)
      ..cubicTo(
        size.width * 0.72 + shift * 0.3,
        size.height * 0.88, // Ponto de controle 1
        size.width * 0.86 + shift * 0.5,
        size.height * 0.42, // Ponto de controle 2
        size.width * 0.98,
        size.height * 0.08, // Ponto final
      );

    // Pintura do Glow Amplo e Etéreo para a Linha 2
    final glowPaint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x0014D9D0), // Invisível
          const Color(0x2214D9D0), // Ciano Glow suave (13%)
          const Color(0x1B2563EB), // Safira Glow suave (10%)
          const Color(0x002563EB), // Invisível
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    // Pintura do Filamento Fino de Luz (Lines Lux) para a Linha 2
    final corePaint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x002563EB), // Transparente nas pontas
          const Color(0xBB14D9D0), // Ciano (73% opacidade)
          const Color(0xFFFFFFFF), // Core branco brilhante
          const Color(0xBB2563EB), // Safira (73% opacidade)
          const Color(0x002563EB), // Transparente nas pontas
        ],
        stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    canvas.drawPath(path2, glowPaint2);
    canvas.drawPath(path2, corePaint2);

    // Micro-partículas estelares de poeira (sutis e dispersas para profundidade extra-fina)
    if (animationProgress > 0.15) {
      final dp = (animationProgress - 0.15) / 0.85;
      final particlePaint1 = Paint()
        ..color = const Color(0xFF14D9D0).withValues(alpha: 0.08 * dp);
      final particlePaint2 = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.12 * dp);
      final particlePaint3 = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.06 * dp);

      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.38),
        1.2,
        particlePaint1,
      );
      canvas.drawCircle(
        Offset(size.width * 0.90, size.height * 0.28),
        0.8,
        particlePaint2,
      );
      canvas.drawCircle(
        Offset(size.width * 0.42, size.height * 0.82),
        1.5,
        particlePaint3,
      );
      canvas.drawCircle(
        Offset(size.width * 0.76, size.height * 0.62),
        0.7,
        particlePaint2,
      );
    }
  }

  /// Desenha a moldura com efeito 2.5D de vidro polido com feixes de luz direcionais concentrados nas extremidades
  void _drawGlowingBorder(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    // Glow estendido nas bordas (foco nos chanfros e cantos principais)
    final borderGlowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x3314D9D0), // Ciano suave (topo esquerdo)
          Color(0xFF2563EB), // Destaque Safira intenso (topo direito)
          Color(0x112563EB), // Suave (lateral direita)
          Color(0xFF14D9D0), // Destaque Ciano intenso (canto inferior direito)
          Color(0x2214D9D0), // Suave (base)
        ],
        stops: [0.0, 0.35, 0.6, 0.8, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // Contorno sólido hiper-fino e brilhante (Reflexo real na borda física de cristal)
    final borderCorePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x44FFFFFF), // Reflexo sutil
          Color(
            0xFFFFFFFF,
          ), // Destaque de luz intensa branca (topo esquerdo/centro)
          Color(0x442563EB), // Safira
          Color(0xFF14D9D0), // Destaque Ciano intenso (canto inferior direito)
          Color(0x22FFFFFF), // Base
        ],
        stops: [0.0, 0.25, 0.55, 0.85, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;

    canvas.drawRRect(rrect, borderGlowPaint);
    canvas.drawRRect(rrect, borderCorePaint);
  }

  void _drawBackShapes(Canvas canvas, Size size) {
    final shift = (1.0 - animationProgress) * 15;

    // Fundo do verso - Véu de luz ciano/azul sutil no canto superior direito (Evita 100% os textos e o QR Code)
    final paintBackNeon = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(
            0x00020B1E,
          ), // Invisível harmonizado com o novo fundo azul noite
          Color(0x1C2563EB), // Safira suave (11%)
          Color(0x2B14D9D0), // Ciano suave (17%)
          Color(0x00020B1E),
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);

    // Contorno de luz brilhante e ultra-fino para o verso (Canto superior direito)
    final paintBackStroke = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x002563EB),
          Color(0x882563EB), // Safira (53%)
          Color(0xFFFFFFFF), // Core luminoso branco
          Color(0x8814D9D0), // Ciano (53%)
          Color(0x0014D9D0),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    // Curva cúbica no topo e no canto superior direito, mantendo toda a base e o meio desobstruídos
    final path = Path()
      ..moveTo(size.width * 0.48, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.04 + shift * 0.4,
        size.width * 0.84,
        size.height * 0.16 + shift * 0.8,
        size.width,
        size.height * 0.28 + shift,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paintBackNeon);

    final pathStroke = Path()
      ..moveTo(size.width * 0.48, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.04 + shift * 0.4,
        size.width * 0.84,
        size.height * 0.16 + shift * 0.8,
        size.width,
        size.height * 0.28 + shift,
      );
    canvas.drawPath(pathStroke, paintBackStroke);
  }

  @override
  bool shouldRepaint(covariant _GeometricFluidPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isFront != isFront;
  }
}
