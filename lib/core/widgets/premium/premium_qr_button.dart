import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

/// Um botão de QR Code padronizado com visual Premium e estética Glassmorphism.
/// Utilizado para unificar o acesso ao Scanner em diversas telas do App.
class PremiumQrButton extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumQrButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/qr-scanner'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Fundo Dark Glass (Night Blue alinhado)
          color: const Color(0xA60F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Borda de vidro sutil
            color: const Color(0x3D94A3B8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          PhosphorIconsRegular.qrCode,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
