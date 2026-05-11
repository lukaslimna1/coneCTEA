import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: items.any((item) => item.value == value) ? value : null,
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF0C2445),
          icon: const Icon(
            PhosphorIconsRegular.caretDown,
            color: AppColors.textSecondary,
            size: 16,
          ),
          style: GoogleFonts.inter(
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: enabled
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 22,
            ),
            filled: true,
            fillColor: enabled
                ? const Color(0xFF071B3A).withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
