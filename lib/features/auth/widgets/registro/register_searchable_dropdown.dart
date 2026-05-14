import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';

class RegisterSearchableDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String? hint;

  const RegisterSearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.hint,
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
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SearchAnchor(
          builder: (context, controller) {
            return InkWell(
              onTap: () => controller.openView(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF071B3A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? hint ?? 'Selecione',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: value == null ? AppColors.textSecondary.withValues(alpha: 0.3) : Colors.white,
                        ),
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.caretDown, color: AppColors.textSecondary, size: 16),
                  ],
                ),
              ),
            );
          },
          viewBackgroundColor: const Color(0xFF071B3A),
          viewSurfaceTintColor: const Color(0xFF071B3A),
          viewHintText: 'Digite para buscar...',
          viewLeading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          suggestionsBuilder: (context, controller) {
            final keyword = controller.text.toLowerCase();
            final filtered = items.where((item) => item.toLowerCase().contains(keyword)).toList();

            return filtered.map((item) => ListTile(
              title: Text(item, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white)),
              onTap: () {
                controller.closeView(item);
                onChanged(item);
              },
            ));
          },
        ),
      ],
    );
  }
}
