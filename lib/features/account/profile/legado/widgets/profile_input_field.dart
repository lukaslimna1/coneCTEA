import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/features/account/profile/legado/widgets/profile_locked_field.dart';

class ProfileInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const ProfileInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return ProfileLockedField(
        label: label,
        value: controller.text.isEmpty ? '—' : controller.text,
        icon: icon,
      );
    }

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.cardBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            return null;
          },
    );
  }
}
