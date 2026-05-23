import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/informacoes/info_action_card.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Card específico para a tela de Segurança e Privacidade.
class SegurancaCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const SegurancaCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InfoActionCard(
      width: width,
      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
      title: 'Segurança',
      subtitle: 'Dados e privacidade.',
      accentColor: DsCores.seguranca.accent,
      onTap: onTap,
    );
  }
}
