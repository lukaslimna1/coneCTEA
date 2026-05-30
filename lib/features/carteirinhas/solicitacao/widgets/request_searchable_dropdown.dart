import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RequestSearchableDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final Function(String) onChanged;
  final bool enabled;
  final String? hint;

  const RequestSearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DsSearchableDropdown(
      label: label,
      value: value,
      items: items,
      icon: icon,
      onChanged: (val) {
        if (val != null) {
          onChanged(val);
        }
      },
      enabled: enabled,
      hint: hint,
    );
  }
}
