import 'package:flutter/material.dart';
import 'package:conectea/features/home/widgets/novidades/em_breve_service_card.dart';
import 'package:conectea/features/home/widgets/comum/home_horizontal_section.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Seção de "Novidades" do dashboard.
/// Modulariza o antigo '_buildBlock2' da HomeView.
class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.78).clamp(300.0, 340.0);

    return HomeHorizontalSection(
      title: 'Novidades',
      height: 185,
      items: [
        EmBreveServiceCard(
          width: cardWidth,
          accentColor: DsCores.institucional.accent,
        ),
      ],
    );
  }
}
