import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/quick_access_card.dart';

/// Card específico para visualizar a carteirinha digital.
class VerCarteirinhaCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const VerCarteirinhaCard({
    super.key,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return QuickAccessCard(
      width: width,
      icon: PhosphorIcons.identificationCard(PhosphorIconsStyle.light),
      title: 'Ver carteirinha',
      subtitle: 'Acesse sua carteirinha digital.',
      ctaLabel: 'Abrir',
      accentColor: const Color(0xFF8B5CF6),
      onTap: onTap,
    );
  }
}
