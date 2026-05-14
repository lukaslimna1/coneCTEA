import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';

/// Wrapper de fundo especializado para telas de autenticação.
/// Inclui o [AppBackground] e uma barra de segurança informativa no rodapé.
class PremiumAuthBackground extends StatelessWidget {
  final Widget child;

  const PremiumAuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      showGlows: true,
      child: child,
    );
  }
}
