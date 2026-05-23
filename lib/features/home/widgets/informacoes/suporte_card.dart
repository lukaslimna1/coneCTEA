import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/informacoes/info_action_card.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Card específico para o Suporte via WhatsApp.
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
    return InfoActionCard(
      width: width,
      icon: PhosphorIcons.headset(PhosphorIconsStyle.fill),
      title: 'Suporte',
      subtitle: 'Fale conosco pelo WhatsApp.',
      accentColor: DsCores.suporte.accent,
      onTap: onTap,
    );
  }
}
