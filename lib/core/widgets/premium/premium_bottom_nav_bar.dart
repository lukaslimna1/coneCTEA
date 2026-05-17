import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barra de navegação inferior flutuante com estética Premium.
/// Suporta animações suaves de transição entre itens e indicadores visuais.
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
    final double systemBottomInset = MediaQuery.paddingOf(context).bottom;
    // Aumentamos a margem de segurança inferior para 20 para garantir simetria com as laterais
    // e evitar que a sombra seja "comida" pela barra de navegação do sistema no A55.
    final double bottomMargin = systemBottomInset > 0 ? systemBottomInset : 20;

    return Container(
      // Margens laterais ajustadas para 20 para alinhar com o padding padrão da HomeView.
      margin: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071326),
            Color(0xFF030B1A),
          ],
        ),
        borderRadius: BorderRadius.circular(36),
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
      // REMOVIDO: SafeArea interno. A margem externa já respeita o sistema.
      // O SafeArea aqui causava "double padding" em alguns aparelhos Android,
      // comprimindo o conteúdo e gerando o erro de aparecer apenas uma "faixa roxa".
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final isSelected = currentIndex == entry.key;
            return Expanded(
              flex: isSelected ? 3 : 1, // Item selecionado ganha significativamente mais espaço
              child: _buildNavItem(entry.key, entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, PremiumNavItem item) {
    final isSelected = currentIndex == index;
    
    // Transformação de labels para nomes curtos oficiais (Frente 23B-5)
    String displayLabel = item.label;
    if (displayLabel == 'Carteirinha' || displayLabel == 'Carteirinhas') {
      displayLabel = 'Cartão';
    } else if (displayLabel == 'Solicitações') {
      displayLabel = 'Pedido';
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 48,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 8,
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: ClipRect(
          child: isSelected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.activeIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5, // Reduzido levemente de 13 para 12.5 para garantir encaixe
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                )
              : Icon(
                  item.inactiveIcon,
                  color: const Color(0xFFAAB6CC).withValues(alpha: 0.9),
                  size: 24,
                ),
        ),
      ),
    );
  }
}

/// Definição de um item da barra de navegação Premium.
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
