import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../core/constants/colors.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import 'widgets/digital_card_widget.dart';

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
      backgroundColor: AppColors.darkBlue,
      body: Stack(
        children: [
          // Background Gradient & Grid
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFF003366),
                    AppColors.darkBlue,
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
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMemberSelector(),
                
                const Spacer(),
                
                // Card Container with Padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Hero(
                      tag: 'card_${member.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final angle = _animation.value * pi;
                            final showBack = angle >= pi / 2;
                            
                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              alignment: Alignment.center,
                              child: showBack
                                  ? Transform(
                                      transform: Matrix4.identity()..rotateY(pi),
                                      alignment: Alignment.center,
                                      child: DigitalCardWidget(
                                        card: card,
                                        member: member,
                                        showBack: true,
                                      ),
                                    )
                                  : DigitalCardWidget(
                                      card: card,
                                      member: member,
                                      showBack: false,
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                _buildControls(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
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
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Hero(
            tag: 'app_logo_mini',
            child: SvgPicture.asset(
              'assets/images/logo_horizontal.svg',
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 48), // Spacer for balance
        ],
      ),
    );
  }

  Widget _buildMemberSelector() {
    if (widget.members.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Text(
                member.name.split(' ')[0],
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _flipCard,
          icon: Icon(
            _isBackVisible ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
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
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'TOQUE PARA GIRAR E VER DETALHES',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
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
