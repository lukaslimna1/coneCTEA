import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math';

import '../../core/constants/colors.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import 'widgets/carteirinha_digital/digital_card_widget.dart';

class FullScreenCardPage extends StatefulWidget {
  final List<Member> members;
  final Map<String, DigitalCard> cardsByMemberId;
  final int initialMemberIndex;

  const FullScreenCardPage({
    super.key,
    required this.members,
    required this.cardsByMemberId,
    this.initialMemberIndex = 0,
  });

  @override
  State<FullScreenCardPage> createState() => _FullScreenCardPageState();
}

class _FullScreenCardPageState extends State<FullScreenCardPage> with SingleTickerProviderStateMixin {
  late int _selectedMemberIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isBackVisible = false;
  bool _showCpf = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberIndex = widget.initialMemberIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isBackVisible) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isBackVisible = !_isBackVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.members[_selectedMemberIndex];
    final card = widget.cardsByMemberId[member.id]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradiente de Fundo e Grade
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFF0E2A52),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),
          
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Row(
                          children: [
                            // Lado esquerdo: O Cartão (Ocupa mais espaço)
                            Expanded(
                              flex: 3,
                              child: _buildCardDisplay(member, card),
                            ),
                            // Lado direito: Controles e Seletor
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 24, bottom: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (widget.members.length > 1) ...[
                                        _buildMemberSelector(padding: EdgeInsets.zero),
                                        const SizedBox(height: 24),
                                      ],
                                      _buildControls(compact: true),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                // Layout Portrait (Original)
                return Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildMemberSelector(),

                    const Spacer(),

                    _buildCardDisplay(member, card),

                    const Spacer(),

                    _buildControls(),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDisplay(Member member, DigitalCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Hero(
          tag: 'card_${member.id}',
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final value = _animation.value;
                final isBack = value > 0.5;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(value * pi),
                  alignment: Alignment.center,
                  child: isBack
                      ? Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: DigitalCardWidget(
                            member: member,
                            card: card,
                            showBack: true,
                            enableParallax: false,
                            enableEntryAnimation: false,
                            showCpf: _showCpf,
                            onToggleCpf: () => setState(() => _showCpf = !_showCpf),
                          ),
                        )
                      : DigitalCardWidget(
                          member: member,
                          card: card,
                          showBack: false,
                          enableParallax: false,
                          enableEntryAnimation: false,
                          showCpf: _showCpf,
                          onToggleCpf: () => setState(() => _showCpf = !_showCpf),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Hero(
            tag: 'app_logo_mini',
            child: Image.asset(
              'assets/images/conectea_logo.png',
              height: 32,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 48), // Espaçador para equilíbrio visual
        ],
      ),
    );
  }

  Widget _buildMemberSelector({EdgeInsetsGeometry? padding}) {
    if (widget.members.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        itemCount: widget.members.length,
        itemBuilder: (context, index) {
          final member = widget.members[index];
          final isSelected = index == _selectedMemberIndex;
          
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() {
                  _selectedMemberIndex = index;
                  if (_isBackVisible) _flipCard();
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Text(
                member.name.split(' ')[0],
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls({bool compact = false}) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _flipCard,
          icon: Icon(
            _isBackVisible ? PhosphorIconsRegular.arrowsLeftRight : PhosphorIconsRegular.arrowsLeftRight,
            color: AppColors.primary,
          ),
          label: Text(
            _isBackVisible ? 'VER FRENTE' : 'VER VERSO',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 30 : 40,
              vertical: compact ? 16 : 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
        ),
        SizedBox(height: compact ? 12 : 24),
        Text(
          'USE O BOTÃO PARA GIRAR A CARTEIRINHA',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
