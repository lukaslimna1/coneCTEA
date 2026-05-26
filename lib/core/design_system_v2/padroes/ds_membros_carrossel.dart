import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Modelo de dados visual e puro para itens do carrossel de membros.
///
/// Não deve depender de nenhum modelo de feature (como Member, CardRequest, etc.).
class DsMembroCarrosselItem {
  final String id;
  final String name;
  final String initials;
  final String statusLabel;
  final Color statusColor;
  final String? paletteSeed;

  const DsMembroCarrosselItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.statusLabel,
    required this.statusColor,
    this.paletteSeed,
  });
}

/// Carrossel Horizontal Oficial de Seleção de Membros do Design System V2.
///
/// Apresenta os membros vinculados em formato de cartões Dark Glass horizontais,
/// com avatar do membro à esquerda e nome/status semântico à direita.
class DsMembrosCarrossel extends StatelessWidget {
  final List<DsMembroCarrosselItem> items;
  final String selectedId;
  final ValueChanged<String> onItemSelected;
  final String? sectionTitle;

  const DsMembrosCarrossel({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onItemSelected,
    this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != null && sectionTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsEspacamentos.edge,
            ),
            child: Text(
              sectionTitle!.toUpperCase(),
              style: DsTipografia.sectionLabel,
            ),
          ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: DsEspacamentos.edge),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = item.id == selectedId;

              return GestureDetector(
                onTap: () => onItemSelected(item.id),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  width: 175,
                  constraints: const BoxConstraints(minHeight: 64),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(DsRaios.md + 2), // 18.0
                    border: Border.all(
                      color: isSelected
                          ? DsCores.conta.accent.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: DsCores.conta.accent.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      DsAvatar(
                        initials: item.initials,
                        size: 34,
                        isInactive: !isSelected,
                        paletteSeed: item.paletteSeed,
                        showGlow: isSelected,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: DsTipografia.cardTitle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: item.statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.statusColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    item.statusLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: item.statusColor.withValues(
                                        alpha: 0.9,
                                      ),
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
