import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/quick_access_card.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Card específico para o Suporte.
class SuporteCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const SuporteCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return QuickAccessCard(
      width: width,
      icon: PhosphorIcons.headset(PhosphorIconsStyle.light),
      title: 'Ajuda e Suporte',
      subtitle: 'Canais de atendimento.',
      ctaLabel: 'Acessar',
      accentColor: DsCores.suporte.accent,
      onTap: onTap,
    );
  }
}
