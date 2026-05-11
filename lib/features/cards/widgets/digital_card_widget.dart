import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/core/widgets/premium_avatar.dart';
import 'package:conectea/core/constants/colors.dart';

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
      aspectRatio: 1.58, // Proporção padrão de cartão de crédito
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
                  width: 450, // Largura Premium
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
    
    // Animação de Entrada
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

    // Sensor Parallax - usando giroscópio ou acelerômetro
    if (widget.enabled) {
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        setState(() {
          // Limita os ângulos para evitar extremos e inverte para uma sensação natural
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
        // Usa inclinação do mouse apenas se sensores não estiverem ativos ou em desktop/web
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          final localPosition = event.localPosition;
          
          // Calcula a posição relativa (-1.0 a 1.0)
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
                    ..setEntry(3, 2, 0.001) // perspectiva
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
    
    final status = card?.status ?? 'pending';
    final isActive = status == 'active';
    final isExpired = card != null && card!.validUntil.isBefore(DateTime.now());

    final bool hasValidBloodType = member.bloodType.isNotEmpty && 
        !member.bloodType.toLowerCase().contains('não sei') && 
        !member.bloodType.toLowerCase().contains('prefiro');

    return _CardBackground(
      isFront: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo do Cabeçalho e Pílulas Superiores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 215, // Logo horizontal ~45% a 60% da largura da carteirinha
                    maxHeight: 36, // Logo horizontal pequena/média
                  ),
                  child: Image.asset(
                    'assets/images/conectea_logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'ConeCTEA',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                
                // Pills side by side
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Validity Pill — Estilo Glassmorphism Refinado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2445).withValues(alpha: 0.9), // Mais escuro para melhor contraste
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsBold.calendar, 
                            color: isExpired ? AppColors.errorRed : const Color(0xFFA78BFA), // Roxo mais brilhante
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            validStr,
                            style: GoogleFonts.inter(
                              color: isExpired ? AppColors.errorRed : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Pill — Dinâmico e Vibrante
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.statusGreen : AppColors.alertOrange).withValues(alpha: 0.95), // Altamente visível
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? AppColors.statusGreen : AppColors.alertOrange).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.clockCounterClockwise, 
                            color: Colors.white, // Alto contraste no fundo
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'ATIVA' : (
                              status == 'waiting_approval' || status == 'pending' ? 'PENDENTE' :
                              status == 'reviewing_data' ? 'PENDENTE' :
                              status == 'waiting_docs' ? 'DOCS PEND.' :
                              status == 'suspended' ? 'SUSPENSA' :
                              status == 'rejected' ? 'REPROVADA' : 'INATIVA'
                            ),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
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
            
            // Título
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

            // Linha de Dados do Membro
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PremiumAvatar(
                  initials: member.initials,
                  size: 90,
                  borderWidth: 3,
                ),
                const SizedBox(width: 24),
                // Informação Principal
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

            // Linha do Token no Rodapé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Pílula do Token
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.hash, color: Color(0xFF4299E1), size: 8),
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
    final qrData = validationToken;
    // Removed unused validStr variable

    return _CardBackground(
      isFront: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Conteúdo Esquerdo (Dados)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INFORMAÇÕES ADICIONAIS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF4299E1), // Azul Claro
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
                      color: const Color(0xFF2C5282), // Azul Médio
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
                            showCpf ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                            size: 18,
                            color: const Color(0xFF00D8D0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (member.cid.isNotEmpty)
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
                    'Documento de identificação digital para uso exclusivo nos programas da Família TEA Bauru.\nNão substitui a CIPTEA oficial (Lei 13.977/20) ou outros documentos de identidade legais.\nA autenticidade pode ser verificada via QR Code.',
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
              ?trailing,
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


