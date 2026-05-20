import 'package:flutter/material.dart';

import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RegisterTermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget text;

  const RegisterTermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: DsCores.sucesso.accent,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: text),
      ],
    );
  }
}
