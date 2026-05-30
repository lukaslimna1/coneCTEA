import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RequestDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;
  final String? hint;
  final bool enabled;

  const RequestDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> stringItems = items
        .map((item) {
          final val = item.value;
          if (val is String) return val;
          final child = item.child;
          if (child is Text) return child.data ?? '';
          return val?.toString() ?? '';
        })
        .where((str) => str.isNotEmpty)
        .toList();

    final String? stringValue = value?.toString();

    return DsDropdown(
      label: label,
      value: stringValue,
      items: stringItems,
      onChanged: (val) {
        onChanged(val as T?);
      },
      hint: hint,
      icon: icon,
      enabled: enabled,
    );
  }
}
