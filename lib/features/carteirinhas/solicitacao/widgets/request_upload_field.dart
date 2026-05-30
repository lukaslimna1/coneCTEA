import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

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
    final String labelLower = label.toLowerCase();
    final DsCorVisual tokenVisual;
    if (labelLower.contains('laudo') ||
        labelLower.contains('médico') ||
        labelLower.contains('medico')) {
      tokenVisual = DsCores.privacidade;
    } else {
      tokenVisual = DsCores.dadosProtegidos;
    }

    final effectiveTextColor = isUploaded
        ? DsCores.textPrimary
        : (enabled
              ? DsCores.textPrimary.withValues(alpha: 0.8)
              : DsCores.textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DsTipografia.inputLabel.copyWith(
            color: enabled ? DsCores.textPrimary : DsCores.textMuted,
          ),
        ),
        const SizedBox(height: DsEspacamentos.sm),
        DsCard(
          accentColor: tokenVisual.accent,
          showGlow: isUploaded,
          borderWidth: isUploaded ? 1.5 : 1.0,
          borderColor: isUploaded
              ? tokenVisual.accent
              : (enabled
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.02)),
          padding: const EdgeInsets.symmetric(
            vertical: DsEspacamentos.md,
            horizontal: DsEspacamentos.md,
          ),
          onTap: (isUploading || !enabled) ? null : onTap,
          child: Row(
            children: [
              SizedBox(
                width: DsTamanhos.iconFrameSm,
                height: DsTamanhos.iconFrameSm,
                child: Center(
                  child: Icon(
                    isUploaded ? PhosphorIconsRegular.checkCircle : icon,
                    color: isUploaded
                        ? DsCores.sucesso.accent
                        : (enabled ? Colors.white : DsCores.iconMuted),
                    size: DsTamanhos.iconSm,
                  ),
                ),
              ),
              const SizedBox(width: DsEspacamentos.md),
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
                            style: DsTipografia.bodySmall.copyWith(
                              color: DsCores.textSecondary,
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
                        style: DsTipografia.bodySmall.copyWith(
                          color: effectiveTextColor,
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
                  color: tokenVisual.accent,
                  size: 20,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
