import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';


/// Card oficial de filtro e contador reutilizável para painéis administrativos da DS V2.
///
/// Segue a composição: ícone em círculo colorido + número grande colorido + label +
/// barrinha inferior colorida + card dark glass.
class DsCardFiltroContador extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final DsCorVisual? token;
  final double width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final String? semanticsLabel;

  const DsCardFiltroContador({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.token,
    this.width = 120.0,
    this.height = 102.0,
    this.padding,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveToken = token ?? DsCores.conta;

    final effectiveBackground = isSelected
        ? effectiveToken.softBackground
        : DsCores.surface.withValues(alpha: 0.40);

    final effectiveBorder = isSelected
        ? effectiveToken.accent
        : Colors.white.withValues(alpha: 0.05);

    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 10);

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel ?? '$label: $count itens',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(DsRaios.card),
            border: Border.all(color: effectiveBorder, width: 1.5),
            boxShadow: isSelected
                ? DsSombras.glow(
                    effectiveToken.accent,
                    alpha: 0.08,
                    blurRadius: 16,
                  )
                : DsSombras.none,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha Superior: Ícone circular à esquerda + Número grande colorido
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: effectiveToken.accent.withValues(
                        alpha: isSelected ? 0.18 : 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: effectiveToken.accent, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count.toString(),
                    style: DsTipografia.sectionTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? effectiveToken.accent
                          : DsCores.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsEspacamentos.sm),
              // Nome do filtro abaixo
              Text(
                label,
                style: DsTipografia.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : DsCores.textSecondary,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Barrinha inferior colorida
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveToken.accent,
                      effectiveToken.accent.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
