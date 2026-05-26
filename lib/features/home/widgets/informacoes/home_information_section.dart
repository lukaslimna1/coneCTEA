import 'package:flutter/material.dart';
import 'package:conectea/features/home/widgets/comum/home_horizontal_section.dart';
import 'package:conectea/features/home/widgets/informacoes/sobre_app_card.dart';
import 'package:conectea/features/home/widgets/informacoes/familia_tea_card.dart';
import 'package:conectea/features/home/widgets/informacoes/projetos_acoes_card.dart';

/// Seção de "Informações" e suporte do dashboard.
/// Modulariza o antigo '_buildBlock3' da HomeView.
class HomeInformationSection extends StatelessWidget {
  final VoidCallback onSupportTap;
  final VoidCallback onAboutTap;
  final VoidCallback onSecurityTap;
  final VoidCallback onFamilyTeaTap;
  final VoidCallback onProjectsActionsTap;

  const HomeInformationSection({
    super.key,
    required this.onSupportTap,
    required this.onAboutTap,
    required this.onSecurityTap,
    required this.onFamilyTeaTap,
    required this.onProjectsActionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.75).clamp(280.0, 320.0);

    return HomeHorizontalSection(
      title: 'Informações',
      height: 80,
      titleSpacing: 10,
      items: [
        SobreAppCard(width: cardWidth, onTap: onAboutTap),
        FamiliaTeaCard(width: cardWidth, onTap: onFamilyTeaTap),
        ProjetosAcoesCard(width: cardWidth, onTap: onProjectsActionsTap),
      ],
    );
  }
}
