import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/quick_access_card.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Card específico para solicitar a carteirinha digital ou atualizar dados.
class SolicitarCarteirinhaCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const SolicitarCarteirinhaCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return QuickAccessCard(
      width: width,
      icon: PhosphorIcons.filePlus(PhosphorIconsStyle.light),
      title: 'Solicitar',
      subtitle: 'Peça sua carteirinha.',
      ctaLabel: 'Solicitar',
      accentColor: DsCores.solicitacao.accent,
      onTap: onTap,
    );
  }
}
