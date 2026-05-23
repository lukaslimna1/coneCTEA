import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/home/widgets/informacoes/info_action_card.dart';

/// Card específico para conhecer Projetos e Ações.
class ProjetosAcoesCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const ProjetosAcoesCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InfoActionCard(
      width: width,
      icon: PhosphorIcons.star(PhosphorIconsStyle.fill), // Icone coerente
      title: 'Projetos e Ações',
      subtitle: 'Conheça as iniciativas.',
      accentColor: DsCores.institucional.accent,
      onTap: onTap,
    );
  }
}
