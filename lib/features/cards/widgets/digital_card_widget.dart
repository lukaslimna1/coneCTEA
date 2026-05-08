import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../models/digital_card.dart';
import '../../../models/member.dart';

class DigitalCardWidget extends StatefulWidget {
  final DigitalCard? card;
  final Member member;
  final bool showBack;
  final bool enableParallax;
  final bool enableEntryAnimation;
  final bool isStatic;
  final bool? showCpf;
  final VoidCallback? onToggleCpf;

  const DigitalCardWidget({
    super.key,
    this.card,
    required this.member,
    this.showBack = false,
    this.enableParallax = true,
    this.enableEntryAnimation = true,
    this.isStatic = false,
    this.showCpf,
    this.onToggleCpf,
  });

  @override
  State<DigitalCardWidget> createState() => _DigitalCardWidgetState();
}

class _DigitalCardWidgetState extends State<DigitalCardWidget> {
  bool _internalShowCpf = false;

  bool get _effectiveShowCpf => widget.showCpf ?? _internalShowCpf;
  
  void _handleToggleCpf() {
    if (widget.onToggleCpf != null) {
      widget.onToggleCpf?.call();
    } else {
      setState(() => _internalShowCpf = !_internalShowCpf);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isStatic) {
      return AspectRatio(
        aspectRatio: 1.58,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 450,
              height: 450 / 1.58,
              child: widget.showBack
                  ? _BackCard(
                      member: widget.member, 
                      card: widget.card,
                      showCpf: _effectiveShowCpf,
                      onToggleCpf: _handleToggleCpf,
                    )
                  : _FrontCard(member: widget.member, card: widget.card),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.58, // Standard credit card aspect ratio
      child: _SensorsCardWrapper(
        enabled: widget.enableParallax,
        enableEntryAnimation: widget.enableEntryAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 450, // Premium width
                  height: 450 / 1.58,
                  child: widget.showBack
                      ? _BackCard(
                          member: widget.member, 
                          card: widget.card,
                          showCpf: _effectiveShowCpf,
                          onToggleCpf: _handleToggleCpf,
                        )
                      : _FrontCard(member: widget.member, card: widget.card),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  ANIMATED SENSOR WRAPPER (3D PARALLAX)
// ═══════════════════════════════════════════════════
class _SensorsCardWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool enableEntryAnimation;
  const _SensorsCardWrapper({
    required this.child, 
    this.enabled = true,
    this.enableEntryAnimation = true,
  });

  @override
  State<_SensorsCardWrapper> createState() => _SensorsCardWrapperState();
}

class _SensorsCardWrapperState extends State<_SensorsCardWrapper> with SingleTickerProviderStateMixin {
  double _pitch = 0.0;
  double _yaw = 0.0;
  StreamSubscription? _accelerometerSubscription;
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Entry Animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: widget.enableEntryAnimation ? 0.95 : 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: widget.enableEntryAnimation ? 0.0 : 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );
    _entryController.forward();

    // Parallax sensor - using gyroscope or accelerometer
    if (widget.enabled) {
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        setState(() {
          // Clamp to avoid extreme angles and invert for natural feeling
          _pitch = (event.y * 0.03).clamp(-0.15, 0.15);
          _yaw = (-event.x * 0.03).clamp(-0.15, 0.15);
        });
      });
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (!widget.enabled) return;
        // Only use mouse tilt if sensors aren't active or on desktop/web
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          final localPosition = event.localPosition;
          
          // Calculate relative position (-1.0 to 1.0)
          final relX = (localPosition.dx / size.width) * 2 - 1;
          final relY = (localPosition.dy / size.height) * 2 - 1;
          
          setState(() {
            _yaw = (relX * 0.1).clamp(-0.15, 0.15);
            _pitch = (-relY * 0.1).clamp(-0.15, 0.15);
          });
        }
      },
      onExit: (_) {
        setState(() {
          _yaw = 0.0;
          _pitch = 0.0;
        });
      },
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: TweenAnimationBuilder(
                tween: Tween<Offset>(begin: Offset.zero, end: Offset(_yaw, _pitch)),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, Offset offset, child) {
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX(offset.dy)
                    ..rotateY(offset.dx);
                  
                  return Transform(
                    transform: matrix,
                    alignment: FractionalOffset.center,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  CARD BACKGROUND (WAVE)
// ═══════════════════════════════════════════════════
class _CardBackground extends StatefulWidget {
  final Widget child;
  final bool isFront;

  const _CardBackground({required this.child, this.isFront = true});

  @override
  State<_CardBackground> createState() => _CardBackgroundState();
}

class _CardBackgroundState extends State<_CardBackground> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Wave entry animation stops after 2 seconds for a clean presentation
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
                      Color(0xFF060E1F),
                      Color(0xFF0B1733),
                      Color(0xFF0D1B3E),
                    ]
                  : const [
                      Color(0xFF080F20),
                      Color(0xFF0A1530),
                      Color(0xFF0D1B3E),
                    ],
            ),
          ),
        ),

        // Watermark logo no verso (visível em branco sobre escuro)
        if (!widget.isFront)
          Positioned(
            right: -20,
            bottom: -40,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: SvgPicture.asset(
                  'assets/images/logo_horizontal.svg',
                  height: 280,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
  }
}

class _GeometricFluidPainter extends CustomPainter {
  final bool isFront;
  final double animationProgress; // 0.0 to 1.0

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

    // Gradiente roxo neon → ciano (identidade ConeCTEA)
    final paintNeon = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFA143FF), // Roxo neon
          Color(0xFF8155FF), // Violeta
          Color(0xFF00D8D0), // Ciano/teal
        ],
        stops: [0.0, 0.5, 1.0],
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
          Paint()..color = const Color(0xFF00D8D0).withValues(alpha: 0.8));
      canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.22), 3.5 * dp,
          Paint()..color = const Color(0xFFA143FF).withValues(alpha: 0.9));
      canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.92), 2.5 * dp,
          Paint()..color = const Color(0xFF00D8D0).withValues(alpha: 0.7));
    }
  }

  void _drawBackShapes(Canvas canvas, Size size) {
    final shift = (1.0 - animationProgress) * 30;

    // Linha neon no fundo do verso
    final paintCyan = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x007C3AED), Color(0x8814B8A6), Color(0x007C3AED)],
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

// ═══════════════════════════════════════════════════
//  FRENTE (FRONT)
// ═══════════════════════════════════════════════════
class _FrontCard extends StatelessWidget {
  final Member member;
  final DigitalCard? card;
  const _FrontCard({required this.member, this.card});

  @override
  Widget build(BuildContext context) {
    final birthStr = _parseDate(member.dateOfBirth);
    final validStr = card != null ? _parseDate(card!.validUntil.toIso8601String()) : '--/--/----';
    final validationToken = card != null ? card!.cardNumber : '----';
    
    final bool hasValidBloodType = member.bloodType.isNotEmpty && 
        !member.bloodType.toLowerCase().contains('não sei') && 
        !member.bloodType.toLowerCase().contains('prefiro');

    return _CardBackground(
      isFront: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28.0, 28.0, 28.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Logo & Top Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/images/logo_horizontal.svg',
                  height: 32,
                  placeholderBuilder: (context) => Text(
                    'ConeCTEA',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                
                // Pills side by side
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Validity Pill — roxo neon translúcido
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA143FF).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFFA143FF), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            validStr,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status Pill — ciano neon translúcido
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D8D0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00D8D0).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF00D8D0), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            'ATIVA',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00D8D0),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'CARTEIRINHA DE IDENTIFICAÇÃO',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PESSOA COM TRANSTORNO DO ESPECTRO AUTISTA',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            
            const Spacer(),

            // Member Data Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Avatar Circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.initials,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        birthStr,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (member.responsibleName.isNotEmpty)
                        Text(
                          'Resp: ${member.responsibleName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (hasValidBloodType)
                        Text(
                          'Tipo Sanguíneo: ${member.bloodType}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF6B6B), // Vermelho claro sobre escuro
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Footer Token Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Token Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag_rounded, color: const Color(0xFF00D8D0), size: 10),
                      const SizedBox(width: 4),
                      Text(
                        'TOKEN: ',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        validationToken,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  VERSO (BACK)
// ═══════════════════════════════════════════════════
class _BackCard extends StatelessWidget {
  final Member member;
  final DigitalCard? card;
  final bool showCpf;
  final VoidCallback onToggleCpf;
  
  const _BackCard({
    required this.member, 
    this.card,
    required this.showCpf,
    required this.onToggleCpf,
  });

  @override
  Widget build(BuildContext context) {
    final validationToken = card != null ? card!.cardNumber : '----';
    // O QRCode agora contém apenas o Token (ID) para busca interna
    final qrData = validationToken;
    final validStr = card != null ? _parseDate(card!.validUntil.toIso8601String()) : '--/--/----';

    return _CardBackground(
      isFront: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Row(
          children: [
            // Left Content (Data)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INFORMAÇÕES ADICIONAIS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00D8D0), // Ciano neon
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA143FF), // Roxo neon
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: onToggleCpf,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildBackItem(
                        'CPF', 
                        showCpf ? _fmtCpf(member.cpf) : '***.***.***-**',
                        trailing: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            showCpf ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: const Color(0xFF00D8D0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (member.cid?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          border: Border.all(color: const Color(0xFFA143FF).withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CID: ${member.cid}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA143FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                  _buildBackItem('CIDADE / UF', '${member.city} / ${member.state}'),
                  _buildBackItem('CONTATO DE EMERGÊNCIA', member.emergencyContact),
                  
                  const Spacer(),
                  
                  // Legal Text
                  Text(
                    'Este documento é pessoal e intransferível.\nA autenticidade pode ser verificada via QR Code.\nVálido em todo território nacional.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // QR Code Section
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 110.0,
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1A1F71),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A1F71),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VALIDAR AUTENTICIDADE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      children: const [
                        TextSpan(text: 'Cone', style: TextStyle(color: Color(0xFFA143FF))),
                        TextSpan(text: 'CTEA', style: TextStyle(color: Color(0xFF00D8D0))),
                      ],
                    ),
                  ),
                  Text(
                    'Família TEA Bauru',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#TODOSPELOAUTISMO',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00D8D0),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackItem(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════

String _parseDate(String? raw) {
  if (raw == null || raw.isEmpty) return '---';
  try {
    final d = DateTime.parse(raw);
    return DateFormat('dd/MM/yyyy').format(d);
  } catch (_) {
    return raw;
  }
}

String _fmtCpf(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  return cpf;
}


