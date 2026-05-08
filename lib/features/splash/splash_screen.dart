import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gradiente oficial da marca ConeCTEA
// ─────────────────────────────────────────────────────────────────────────────
const List<Color> _brandColors = [
  Color(0xFFA143FF),
  Color(0xFF9B46FF),
  Color(0xFF8155FF),
  Color(0xFF527FF2),
  Color(0xFF1BB3DB),
  Color(0xFF00D7D3),
  Color(0xFF00D8D0),
];

const _brandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: _brandColors,
  stops: [0.0, 0.20, 0.35, 0.50, 0.60, 0.70, 1.0],
);

// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _logoCtrl;    // entrada da logo
  late final AnimationController _contentCtrl; // entrada do texto
  late final AnimationController _shimmerCtrl; // loop: shimmer + fundo
  late final AnimationController _rippleCtrl;  // loop: ripples
  late final AnimationController _exitCtrl;    // saída

  // Animations
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080612),
    ));
    _initControllers();
    _initAnimations();
    _runSequence();
  }

  void _initControllers() {
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _initAnimations() {
    _logoFade = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.easeOutCubic,
    ));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInQuart),
    );
  }

  Future<void> _runSequence() async {
    debugPrint("Splash: Sequence started");
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    debugPrint("Splash: Logo starting");
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    debugPrint("Splash: Content starting");
    _contentCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    debugPrint("Splash: Checking session");

    try {
      final session = Supabase.instance.client.auth.currentSession;
      debugPrint("Splash: Session check done, session: ${session != null}");
      
      _shimmerCtrl.stop();
      _rippleCtrl.stop();
      debugPrint("Splash: Stopping animations and exiting");
      await _exitCtrl.forward();
      if (!mounted) return;

      final target = session != null ? '/home' : '/login';
      debugPrint("Splash: Navigating to $target");
      context.go(target);
    } catch (e) {
      debugPrint("Splash: Error during sequence: $e");
      // Fallback para evitar carregamento infinito em caso de erro crítico
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _shimmerCtrl.dispose();
    _rippleCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _exitOpacity,
      child: Scaffold(
        backgroundColor: const Color(0xFF080612),
        body: Stack(
          children: [
            // ── 1. Fundo com gradiente radial respirando ──────────────
            Positioned.fill(
              child: _AnimatedBackground(ctrl: _shimmerCtrl),
            ),

            // ── 2. Layout principal em coluna ─────────────────────────
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Área central: logo + ripples juntos
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Aura brilhante atrás
                            _GlowAura(ctrl: _shimmerCtrl),
                            // Ripples de onda
                            _RippleRings(ctrl: _rippleCtrl),
                            // Logo com shimmer
                            ScaleTransition(
                              scale: _logoScale,
                              child: FadeTransition(
                                opacity: _logoFade,
                                child: _LogoWithShimmer(ctrl: _shimmerCtrl),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tagline
                    FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: _Tagline(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divisor sutil
                    FadeTransition(
                      opacity: _contentFade,
                      child: _GradientDivider(),
                    ),

                    // Rodapé com loading
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 52),
                          child: FadeTransition(
                            opacity: _contentFade,
                            child: _LoadingIndicator(ctrl: _shimmerCtrl),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fundo animado
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController ctrl;
  const _AnimatedBackground({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final pulse = (math.sin(ctrl.value * math.pi * 2) * 0.5 + 0.5);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.4,
              colors: [
                Color.lerp(
                  const Color(0xFF1E0B45),
                  const Color(0xFF2D1260),
                  pulse,
                )!,
                const Color(0xFF080612),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aura brilhante (glow) atrás da logo
// ─────────────────────────────────────────────────────────────────────────────
class _GlowAura extends StatelessWidget {
  final AnimationController ctrl;
  const _GlowAura({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final pulse = math.sin(ctrl.value * math.pi * 2) * 0.5 + 0.5;
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF6B3BD6).withValues(alpha: 0.25 + pulse * 0.10),
                const Color(0xFF00D7D3).withValues(alpha: 0.08 + pulse * 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ripple rings ao redor da logo
// ─────────────────────────────────────────────────────────────────────────────
class _RippleRings extends StatelessWidget {
  final AnimationController ctrl;
  const _RippleRings({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return SizedBox(
          width: 340,
          height: 340,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(ctrl.value, 0.00, 140, const Color(0xFF8155FF)),
              _ring(ctrl.value, 0.30, 190, const Color(0xFF527FF2)),
              _ring(ctrl.value, 0.60, 240, const Color(0xFF00D7D3)),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double t, double offset, double maxR, Color color) {
    final phase = ((t + offset) % 1.0);
    final size = maxR * phase;
    final opacity = (1.0 - phase) * 0.35;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo com shimmer deslizante
// ─────────────────────────────────────────────────────────────────────────────
class _LogoWithShimmer extends StatelessWidget {
  final AnimationController ctrl;
  const _LogoWithShimmer({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final shift = ctrl.value; // 0..1

        // O ponto brilhante desliza da esquerda para a direita
        final shimmer = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFA143FF),
            const Color(0xFF8155FF),
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFF00D7D3),
            const Color(0xFFA143FF),
          ],
          stops: [
            0.0,
            (shift - 0.05).clamp(0.0, 1.0),
            shift.clamp(0.0, 1.0),
            (shift + 0.12).clamp(0.0, 1.0),
            1.0,
          ],
        );

        return ShaderMask(
          shaderCallback: (bounds) => shimmer.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tagline
// ─────────────────────────────────────────────────────────────────────────────
class _Tagline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          // Texto principal com gradiente da marca
          ShaderMask(
            shaderCallback: (bounds) => _brandGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Acolher, Conscientizar\ne Fortalecer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white, // substituído pelo ShaderMask
                height: 1.5,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Subtítulo
          Text(
            'FAMÍLIA TEA BAURU',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 4.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divisor com gradiente
// ─────────────────────────────────────────────────────────────────────────────
class _GradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Color(0xFF8155FF),
              Color(0xFF00D7D3),
              Colors.transparent,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicador de carregamento (3 dots pulsantes)
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingIndicator extends StatelessWidget {
  final AnimationController ctrl;
  const _LoadingIndicator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (ctrl.value + i / 3.0) % 1.0;
                final scale = 0.6 + math.sin(phase * math.pi) * 0.4;
                final opacity = 0.25 + math.sin(phase * math.pi) * 0.75;
                final color = Color.lerp(
                  const Color(0xFF8155FF),
                  const Color(0xFF00D7D3),
                  i / 2.0,
                )!;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: opacity),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: opacity * 0.7),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              'Carregando...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }
}
