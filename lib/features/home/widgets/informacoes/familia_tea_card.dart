import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/informacoes/info_action_card.dart';

/// Card específico para conhecer a Família TEA.
class FamiliaTeaCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const FamiliaTeaCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InfoActionCard(
      width: width,
      icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
      title: 'Família TEA',
      subtitle: 'Conheça a organização.',
      accentColor: const Color(0xFF22D3EE),
      onTap: onTap,
    );
  }
}
