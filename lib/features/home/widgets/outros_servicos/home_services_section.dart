import 'package:flutter/material.dart';
import 'package:conectea/features/home/widgets/outros_servicos/em_breve_service_card.dart';
import 'package:conectea/features/home/widgets/comum/home_horizontal_section.dart';

/// Seção de "Outros Serviços" do dashboard.
/// Modulariza o antigo '_buildBlock2' da HomeView.
class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.78).clamp(300.0, 340.0);

    return HomeHorizontalSection(
      title: 'Outros Serviços',
      height: 185,
      items: [
        EmBreveServiceCard(
          width: cardWidth,
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}
