import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

/// Widget de Avatar Premium com bordas iluminadas e suporte a imagens ou iniciais.
/// Utiliza o design system "Night Blue" para os fallbacks e sombras.
class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? initials;
  final double size;
  final double? fontSize;
  final List<BoxShadow>? boxShadow;
  final double borderWidth;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.initials,
    this.size = 44,
    this.fontSize,
    this.boxShadow,
    this.borderWidth = 2,
  });

  /// Gera as iniciais baseadas no nome fornecido ou retorna '?' como fallback.
  String _getInitials() {
    if (initials != null) return initials!;
    if (name == null || name!.isEmpty) return '?';
    
    final names = name!.trim().split(' ');
    if (names.length >= 2) {
      return (names[0][0] + names[names.length - 1][0]).toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF0C2445),
          ],
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: size * 0.27,
            offset: Offset(0, size * 0.09),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                 imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  /// Constrói o widget visual das iniciais quando a imagem não está disponível.
  Widget _buildInitials() {
    return Center(
      child: Text(
        _getInitials(),
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: fontSize ?? (size * 0.36),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
