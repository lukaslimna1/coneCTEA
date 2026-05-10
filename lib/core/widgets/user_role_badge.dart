import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/models/app_user.dart';

/// Badge visual para exibir o nível de acesso (Role) do usuário.
/// Utiliza gradientes e ícones específicos para cada nível hierárquico.
class UserRoleBadge extends StatelessWidget {
  final UserRole role;
  final VoidCallback? onTap;

  const UserRoleBadge({super.key, required this.role, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color startColor;
    Color endColor;
    IconData icon;
    String label;
    Color textColor = Colors.white;
    Color borderColor = Colors.white.withValues(alpha: 0.3);

    // Mapeamento de estilos baseados na função do usuário
    switch (role) {
      case UserRole.adminDev:
        startColor = const Color(0xFF1E293B); // Slate 800
        endColor = const Color(0xFF0F172A);   // Slate 900
        icon = Icons.terminal_rounded;
        label = 'ADM DEV';
        borderColor = Colors.cyanAccent.withValues(alpha: 0.3);
        break;
      case UserRole.adminMaster:
        startColor = const Color(0xFFFFD700); // Gold
        endColor = const Color(0xFFB8860B);   // Dark Goldenrod
        icon = Icons.workspace_premium_rounded;
        label = 'ADM MASTER';
        textColor = const Color(0xFF451A03); // Deep Brown (Melhor contraste com dourado)
        borderColor = Colors.white.withValues(alpha: 0.5);
        break;
      case UserRole.admin:
        startColor = const Color(0xFF3B82F6); // Blue 500
        endColor = const Color(0xFF1D4ED8);   // Blue 700
        icon = Icons.verified_user_rounded;
        label = 'ADMINISTRADOR';
        break;
      default:
        // Caso não seja um administrador, o badge não é exibido
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
          borderRadius: BorderRadius.circular(100), // Estética Pill Premium
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: textColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
