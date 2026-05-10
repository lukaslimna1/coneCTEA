import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<PremiumNavItem> items;

  const PremiumBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071326),
            Color(0xFF030B1A),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              return _buildNavItem(entry.key, entry.value);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, PremiumNavItem item) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 46,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(
            colors: [
              Color(0xFF5B21B6),
              Color(0xFF6D28D9),
              Color(0xFF4C1D95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.inactiveIcon,
              color: isSelected ? Colors.white : const Color(0xFFAAB6CC).withValues(alpha: 0.9),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PremiumNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  PremiumNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}
