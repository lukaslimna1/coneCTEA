import 'package:flutter/material.dart';
import 'package:conectea/features/home/widgets/comum/home_horizontal_section.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/solicitar_carteirinha_card.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/suporte_card.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/seguranca_card.dart';
import 'package:conectea/features/conta/seguranca/security_view.dart';
import 'package:conectea/features/conta/suporte/support_view.dart';

/// Seção de "Acesso Rápido" do dashboard.
/// Modulariza o antigo '_buildBlock1' da HomeView.
class HomeQuickAccessSection extends StatelessWidget {
  final VoidCallback onRequestCard;
  final VoidCallback onSupportTap;

  const HomeQuickAccessSection({
    super.key,
    required this.onRequestCard,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.72).clamp(280.0, 305.0);

    return HomeHorizontalSection(
      title: 'Acesso Rápido',
      height: 148,
      items: [
        SolicitarCarteirinhaCard(width: cardWidth, onTap: onRequestCard),
        SegurancaCard(
          width: cardWidth,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityView()),
          ),
        ),
        SuporteCard(
          width: cardWidth,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportView()),
          ),
        ),
      ],
    );
  }
}
