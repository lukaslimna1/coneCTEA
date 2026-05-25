import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **DsBottomNavBar** — Componente de Barra de Navegação Inferior Oficial da DS V2.
///
/// Adota o formato clássico vertical compacto flutuante. Exibe o rótulo apenas
/// para abas inativas, e apenas o ícone centralizado verticalmente com bolha glass semântica
/// para a aba ativa. Otimizada para o padrão Night Blue / Dark Glass Premium.
class DsBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<DsBottomNavItem> items;

  const DsBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > 0) {
      return const SizedBox.shrink();
    }

    final double systemBottomInset = MediaQuery.paddingOf(context).bottom;
    final double bottomMargin = systemBottomInset > 0 ? systemBottomInset : 20;

    return Container(
      // Margens laterais de 8px para aproveitamento horizontal ideal em telas estreitas como 360dp
      margin: EdgeInsets.fromLTRB(8, 0, 8, bottomMargin),
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071326), Color(0xFF030B1A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            return Expanded(child: _buildNavItem(entry.key, entry.value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, DsBottomNavItem item) {
    final isSelected = currentIndex == index;
    final accentColor = item.token?.accent ?? const Color(0xFF60A5FA);

    // Transformação rápida de labels para nomes curtos oficiais
    String displayLabel = item.label;
    if (displayLabel == 'Solicitações') {
      displayLabel = 'Pedido';
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: isSelected
          ? Center(
              // 1. Aba ativa: apenas o ícone branco centralizado no espaço vertical total
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(item.activeIcon, color: Colors.white, size: 25),
                ),
              ),
            )
          : Column(
              // 2. Aba inativa: ícone + label compacto na vertical
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.inactiveIcon,
                  color: const Color(0xFFB8C7E6).withValues(alpha: 0.75),
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB8C7E6).withValues(alpha: 0.65),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
    );
  }
}

/// **DsBottomNavItem** — Item de navegação oficial da DsBottomNavBar.
class DsBottomNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final DsCorVisual? token;

  const DsBottomNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.token,
  });
}
