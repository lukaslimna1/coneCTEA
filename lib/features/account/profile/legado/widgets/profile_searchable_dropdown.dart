import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

class ProfileSearchableDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool isLoading;

  const ProfileSearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<String> state) {
        return SearchAnchor(
          builder: (context, controller) {
            return InkWell(
              onTap: enabled && !isLoading ? () => controller.openView() : null,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorText: state.errorText,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? (isLoading ? 'Carregando...' : hint ?? 'Selecione'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          },
          viewBackgroundColor: AppColors.cardBackground,
          viewSurfaceTintColor: AppColors.cardBackground,
          viewHintText: 'Digite para buscar...',
          suggestionsBuilder: (context, controller) {
            final keyword = controller.text.toLowerCase();
            final filtered = items.where((item) => item.toLowerCase().contains(keyword)).toList();

            return filtered.map((item) => ListTile(
              title: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                controller.closeView(item);
                onChanged(item);
                state.didChange(item);
              },
            ));
          },
        );
      },
    );
  }
}
