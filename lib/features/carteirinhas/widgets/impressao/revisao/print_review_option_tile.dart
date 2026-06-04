import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintReviewOptionTile**
/// Widget stateless local da funcionalidade de revisão de impressão.
/// Renderiza a casca visual repetitiva de uma opção selecionável com checkbox
/// e sua respectiva área expandida (child).
class PrintReviewOptionTile extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget? child;
  final DsCorVisual token;

  const PrintReviewOptionTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.child,
    this.token = DsCores.sucesso,
  });

  @override
  Widget build(BuildContext context) {
    final localChild = child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsCheckbox(
          value: value,
          onChanged: onChanged,
          label: Text(
            title,
            style: DsTipografia.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          description: description,
          token: token,
        ),
        ?localChild,
      ],
    );
  }
}
