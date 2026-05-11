import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/informacoes/info_action_card.dart';

/// Card específico para a tela Sobre o App.
class SobreAppCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const SobreAppCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InfoActionCard(
      width: width,
      icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
      title: 'Sobre o app',
      subtitle: 'Entenda o ConeCTEA.',
      accentColor: const Color(0xFFF59E0B),
      onTap: onTap,
    );
  }
}
