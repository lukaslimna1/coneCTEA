import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Card especial para serviços futuros (Em breve) com ilustração premium.
class EmBreveServiceCard extends StatelessWidget {
  final double width;
  final Color accentColor;

  const EmBreveServiceCard({
    super.key,
    required this.width,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 170,
      child: Material(
        color: Colors.transparent,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0B1D3A), // Fundo azul profundo
                Color(0xFF060D1A), // Centro quase preto
                Color(0xFF0A192F), // Tom escuro navy
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0x2494A3B4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Camada de vidro sutil
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),

              // --- ILUSTRAÇÃO VIVA (Lado Direito) ---

              // 1. Glow de Fundo (Acento Roxo)
              Positioned(
                right: -50,
                top: -20,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.18),
                        accentColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Glow de Fundo (Acento Ciano)
              Positioned(
                right: 20,
                bottom: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF22D3EE).withValues(alpha: 0.15),
                        const Color(0xFF22D3EE).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Estrelas/Dots (Profundidade)
              ...List.generate(6, (index) {
                final positions = [
                  const Offset(0.45, 0.25),
                  const Offset(0.55, 0.45),
                  const Offset(0.40, 0.60),
                  const Offset(0.65, 0.20),
                  const Offset(0.75, 0.50),
                  const Offset(0.85, 0.30),
                ];
                final sizes = [3.0, 2.0, 4.0, 2.5, 3.5, 2.0];
                final opacities = [0.15, 0.10, 0.20, 0.12, 0.18, 0.10];
                
                return Positioned(
                  left: width * positions[index].dx,
                  top: 170 * positions[index].dy,
                  child: Container(
                    width: sizes[index],
                    height: sizes[index],
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacities[index]),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),

              // 4. PNG Illustration (O Foguete Premium)
              Positioned(
                right: -10,
                bottom: -15,
                child: Opacity(
                  opacity: 0.65,
                  child: Image.asset(
                    'assets/images/coming_soon.png',
                    width: 165,
                    height: 165,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 5. Brilho extra sobre a imagem
              Positioned(
                right: 30,
                bottom: 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.08),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),

              // --- CONTEÚDO E ESTRUTURA ---

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
                        const Color(0xFF22D3EE),
                        const Color(0xFF60A5FA),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Moldura do ícone
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF020617).withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Em breve',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Text(
                                      'NOVO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Recursos, programas e novidades\nchegando para você.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // CTA Estilo Rodapé
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            'Aguardar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 12,
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
    );
  }
}
