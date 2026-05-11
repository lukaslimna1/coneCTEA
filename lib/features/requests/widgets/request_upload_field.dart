import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';

class RequestUploadField extends StatelessWidget {
  final String label;
  final String? fileName;
  final bool isUploading;
  final bool isUploaded;
  final VoidCallback onTap;
  final IconData icon;
  final bool enabled;

  const RequestUploadField({
    super.key,
    required this.label,
    required this.fileName,
    required this.isUploading,
    required this.isUploaded,
    required this.onTap,
    required this.icon,
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
        GestureDetector(
          onTap: (isUploading || !enabled) ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (enabled
                        ? const Color(0xFF071B3A).withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUploaded
                    ? AppColors.primary
                    : (enabled
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.02)),
                width: isUploaded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUploaded ? PhosphorIconsRegular.checkCircle : icon,
                  color: isUploaded
                      ? AppColors.statusGreen
                      : (enabled
                            ? AppColors.primary
                            : AppColors.textSecondary.withValues(alpha: 0.5)),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isUploading
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Enviando...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isUploaded
                              ? fileName ?? 'Arquivo enviado'
                              : (enabled
                                    ? 'Toque para enviar arquivo'
                                    : 'Campo bloqueado'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isUploaded
                                ? Colors.white
                                : (enabled
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : AppColors.textSecondary),
                            fontWeight: isUploaded
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (!isUploading && enabled)
                  Icon(
                    isUploaded
                        ? PhosphorIconsRegular.arrowsClockwise
                        : PhosphorIconsRegular.uploadSimple,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
