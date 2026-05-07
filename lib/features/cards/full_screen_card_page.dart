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
  bool _showBack = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

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
    if (_showBack) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _showBack = !_showBack;
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
          // Subtle Grid Background
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
                const SizedBox(height: 16),
                _buildMemberSelector(),
                
                const Spacer(),
                
                // Animated Flipping Card
                Center(
                  child: Hero(
                    tag: 'card_${member.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          // The angle goes from 0 to pi.
                          final angle = _animation.value * pi;
                          
                          // We need to render the back if angle is > pi/2
                          bool isBackVisible = angle >= pi / 2;
                          
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isBackVisible
                                // When showing the back, we must flip it again so it's not mirrored
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
                
                const Spacer(),
                
                // Controls
                _buildControls(),
                const SizedBox(height: 32),
                
                Text(
                  'GIRE PARA VISIBILIDADE TOTAL',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
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
              height: 30,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 24),
            onPressed: () {
              // Share logic placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compartilhamento em breve')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelector() {
    if (widget.members.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isSelected = index == _selectedMemberIndex;
          
          final parts = member.name.split(' ');
          final initials = parts.length > 1 
              ? '${parts[0][0]}${parts[1][0]}' 
              : parts[0][0];

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() {
                  _selectedMemberIndex = index;
                  if (_showBack) {
                    _flipCard(); // reset to front when switching
                  }
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.statusGreen : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${initials.toUpperCase()} ${parts[0]}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _flipCard,
          icon: Icon(
            _showBack ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
            color: AppColors.primary,
          ),
          label: Text(
            _showBack ? 'Ver Frente' : 'Ver Verso',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicator('Frente', !_showBack),
            const SizedBox(width: 16),
            _buildIndicator('Verso', _showBack),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.statusGreen : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? '$label ativo' : '$label inativo',
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
      ..strokeWidth = 1.0;

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
