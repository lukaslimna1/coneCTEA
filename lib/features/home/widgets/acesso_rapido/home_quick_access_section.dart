import 'package:flutter/material.dart';
import 'package:conectea/features/home/widgets/comum/home_horizontal_section.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/ver_carteirinha_card.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/solicitar_carteirinha_card.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/mural_card.dart';

/// Seção de "Acesso Rápido" do dashboard.
/// Modulariza o antigo '_buildBlock1' da HomeView.
class HomeQuickAccessSection extends StatelessWidget {
  final VoidCallback onOpenDigitalCard;
  final VoidCallback onRequestCard;
  final VoidCallback onOpenMural;

  const HomeQuickAccessSection({
    super.key,
    required this.onOpenDigitalCard,
    required this.onRequestCard,
    required this.onOpenMural,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.72).clamp(280.0, 305.0);

    return HomeHorizontalSection(
      title: 'Acesso Rápido',
      height: 148,
      items: [
        VerCarteirinhaCard(
          width: cardWidth,
          onTap: onOpenDigitalCard,
        ),
        SolicitarCarteirinhaCard(
          width: cardWidth,
          onTap: onRequestCard,
        ),
        MuralCard(
          width: cardWidth,
          onTap: onOpenMural,
        ),
      ],
    );
  }
}
