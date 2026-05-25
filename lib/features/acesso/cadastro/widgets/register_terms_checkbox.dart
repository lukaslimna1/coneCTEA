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
    return DsCheckbox(
      value: value,
      onChanged: onChanged,
      label: text,
      token: DsCores.sucesso,
    );
  }
}
