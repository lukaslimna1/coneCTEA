import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RequestInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final bool enabled;

  const RequestInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DsInput(
      label: label,
      controller: controller,
      hint: hint,
      icon: icon,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      enabled: enabled,
    );
  }
}
