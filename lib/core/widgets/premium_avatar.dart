import 'package:flutter/material.dart';
import 'premium/conectea_avatar.dart';

/// Wrapper de compatibilidade para o novo ConecteaAvatar.
/// 
/// Redireciona todas as chamadas para o componente oficial padronizado
/// do Design System ConeCTEA.
class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? initials;
  final double size;
  final double? fontSize;
  final List<BoxShadow>? boxShadow;
  final double borderWidth;
  final String? paletteSeed;
  final Color? accentColor;
  final String? role;
  final bool isInactive;
  final bool showGlow;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.initials,
    this.size = 44,
    this.fontSize,
    this.boxShadow,
    this.borderWidth = 2,
    this.paletteSeed,
    this.accentColor,
    this.role,
    this.isInactive = false,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ConecteaAvatar(
      initials: initials ?? _getInitials(),
      size: size,
      accentColor: accentColor,
      imageUrl: imageUrl,
      role: role,
      paletteSeed: paletteSeed,
      isInactive: isInactive,
      showGlow: showGlow,
      borderWidth: borderWidth,
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty || name == 'Usuário') return '--';
    final trimmedName = name!.trim();
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
