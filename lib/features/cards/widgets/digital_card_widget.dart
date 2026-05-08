import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../models/digital_card.dart';
import '../../../models/member.dart';

class DigitalCardWidget extends StatelessWidget {
  final DigitalCard? card;
  final Member member;
  final bool showBack;
  final bool enableParallax;
  final bool enableEntryAnimation;

  const DigitalCardWidget({
    super.key,
    this.card,
    required this.member,
    this.showBack = false,
    this.enableParallax = true,
    this.enableEntryAnimation = true,
    this.isStatic = false,
  });

  final bool isStatic;

  @override
  Widget build(BuildContext context) {
    if (isStatic) {
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
              child: showBack
                  ? _BackCard(member: member, card: card)
                  : _FrontCard(member: member, card: card),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.58, // Standard credit card aspect ratio
      child: _SensorsCardWrapper(
        enabled: enableParallax,
        enableEntryAnimation: enableEntryAnimation,
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
                  child: showBack
                      ? _BackCard(member: member, card: card)
                      : _FrontCard(member: member, card: card),
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
    // Premium fluid gradients matching the provided images
    final waveColors = widget.isFront 
        ? const [
            Color(0xFF06B6D4), // Cyan 500
            Color(0xFF0284C7), // Light Blue
            Color(0xFF2563EB), // Vibrant Blue
            Color(0xFF1E3A8A), // Deep Navy
          ] 
        : const [
            Color(0xFFE0F2FE), // Very light blue
            Color(0xFFBAE6FD), // Light cyan
          ]; // Extremely subtle lighter blue for back

    return Stack(
      children: [
        // Background color
        Container(color: Colors.white),

        // Watermark on the back (Puzzle head icon if available, or logo)
        if (!widget.isFront)
          Positioned(
            right: 0,
            bottom: -50,
            child: Opacity(
              opacity: 0.03,
              child: SvgPicture.asset(
                'assets/images/logo_horizontal.svg', 
                height: 300,
              ),
            ),
          ),
          
        // Animated Geometric Fluid Design
        Positioned.fill(
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

        // Main Content
        widget.child,

        // Premium Border highlight
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
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

    // Premium Logo Gradient Colors
    const premiumColors = [
      Color(0xFFA143FF), // 0% Roxo vibrante
      Color(0xFF9B46FF), // 20% Roxo violeta
      Color(0xFF8155FF), // 35% Violeta azulado
      Color(0xFF527FF2), // 50% Azul médio
      Color(0xFF1BB3DB), // 60% Azul ciano
      Color(0xFF00D7D3), // 70% Turquesa
      Color(0xFF00D8D0), // 100% Ciano/verde água
    ];
    const premiumStops = [0.0, 0.2, 0.35, 0.5, 0.6, 0.7, 1.0];

    final paintPremium = Paint()
      ..shader = const LinearGradient(
        colors: premiumColors,
        stops: premiumStops,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // A darker, elegant variant for contrast
    final paintNavyAccent = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A1F71), Color(0xFF071F4F)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Top-Right Fluid Geometric Shape
    final pathTop = Path();
    pathTop.moveTo(size.width * 0.45 + shift, 0);
    pathTop.lineTo(size.width * 0.65, size.height * 0.15); 
    pathTop.quadraticBezierTo(size.width * 0.85, size.height * 0.25, size.width, size.height * 0.2 - shift); 
    pathTop.lineTo(size.width, 0);
    pathTop.close();
    canvas.drawPath(pathTop, paintNavyAccent);

    final pathTopPremium = Path();
    pathTopPremium.moveTo(size.width * 0.6 + shift, 0);
    pathTopPremium.lineTo(size.width * 0.75, size.height * 0.1);
    pathTopPremium.quadraticBezierTo(size.width * 0.9, size.height * 0.15, size.width, size.height * 0.1 - shift);
    pathTopPremium.lineTo(size.width, 0);
    pathTopPremium.close();
    canvas.drawPath(pathTopPremium, paintPremium);

    // Bottom-Right Large Overlapping Fluid Geometric Shapes
    final pathBotNavy = Path();
    pathBotNavy.moveTo(size.width * 0.25 - shift, size.height);
    pathBotNavy.lineTo(size.width * 0.65, size.height * 0.55);
    pathBotNavy.quadraticBezierTo(size.width * 0.9, size.height * 0.45, size.width, size.height * 0.35 + shift);
    pathBotNavy.lineTo(size.width, size.height);
    pathBotNavy.close();
    canvas.drawPath(pathBotNavy, paintNavyAccent);

    final pathBotPremium = Path();
    pathBotPremium.moveTo(size.width * 0.45 - shift, size.height);
    pathBotPremium.lineTo(size.width * 0.75, size.height * 0.65);
    pathBotPremium.quadraticBezierTo(size.width * 0.95, size.height * 0.6, size.width, size.height * 0.5 + shift);
    pathBotPremium.lineTo(size.width, size.height);
    pathBotPremium.close();
    canvas.drawPath(pathBotPremium, paintPremium);

    // Abstract Modern Floating Circles
    if (animationProgress > 0.1) {
      final dotProgress = (animationProgress - 0.1) / 0.9;
      final paintDotCyan = Paint()..color = const Color(0xFF00D7D3);
      final paintDotPurple = Paint()..color = const Color(0xFFA143FF);
      
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 6.0 * dotProgress, paintDotCyan);
      canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.22), 3.0 * dotProgress, paintDotPurple);
      canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.92), 2.0 * dotProgress, paintDotCyan);
    }
  }

  void _drawBackShapes(Canvas canvas, Size size) {
    // Subtle fluid wave for the back
    final shift = (1.0 - animationProgress) * 30;
    
    final paintLightCyan = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.85 + shift);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.75 + shift, size.width, size.height * 0.9 + shift);
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paintLightCyan);
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
                      color: const Color(0xFF1A1F71),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                
                // Pills side by side
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Validity Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A), // Deep Navy
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 10),
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
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF0D9488), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            'ATIVA',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0D9488),
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
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PESSOA COM TRANSTORNO DO ESPECTRO AUTISTA',
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B), // Stronger than 334155
                fontSize: 8,
                fontWeight: FontWeight.w900, // bolder
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
                      colors: [Color(0xFFE0F2FE), Color(0xFFF3E8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8155FF).withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.initials,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1F71), // Deep navy
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
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        birthStr,
                        style: GoogleFonts.inter(
                          color: Colors.black,
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
                            color: const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (hasValidBloodType)
                        Text(
                          'Tipo Sanguíneo: ${member.bloodType}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFDC2626), // Vermelho destaque
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
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, color: Color(0xFF1E293B), size: 10),
                      const SizedBox(width: 4),
                      Text(
                        'TOKEN: ',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        validationToken,
                        style: GoogleFonts.inter(
                          color: Colors.black,
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
  const _BackCard({required this.member, this.card});

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
                      color: const Color(0xFF1A1F71),
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
                      color: const Color(0xFF0D9488), // Cyan
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildBackItem('CPF', _fmtCpf(member.cpf)),
                  
                  if (member.cid != null && member.cid!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CID: ${member.cid}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1D4ED8),
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
                      color: const Color(0xFF0F172A),
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      color: const Color(0xFF1A1F71),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ConeCTEA Logo Text Colored
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      children: const [
                        TextSpan(text: 'Cone', style: TextStyle(color: Color(0xFF7C3AED))), // Purple
                        TextSpan(text: 'CTEA', style: TextStyle(color: Color(0xFF0D9488))), // Cyan
                      ],
                    ),
                  ),
                  Text(
                    'Família TEA Bauru',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1E293B),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#TODOSPELOAUTISMO',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A1F71),
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

  Widget _buildBackItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
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


