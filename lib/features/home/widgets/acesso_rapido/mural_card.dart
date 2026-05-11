import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/quick_access_card.dart';

/// Card específico para acessar o mural do usuário.
class MuralCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const MuralCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return QuickAccessCard(
      width: width,
      icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.light),
      title: 'Meu mural',
      subtitle: 'Acompanhe avisos e comunicados.',
      ctaLabel: 'Acessar',
      accentColor: const Color(0xFF60A5FA),
      onTap: onTap,
    );
  }
}
