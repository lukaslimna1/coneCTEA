import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../models/app_user.dart';

class AdminUserCard extends StatelessWidget {
  final AppUser user;
  final UserRole? currentUserRole;
  final Function(UserRole) onToggleRole;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.currentUserRole,
    required this.onToggleRole,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role.isAdmin;
    final initials = user.name.isNotEmpty 
        ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : '?';

    // Cores por cargo
    Color roleColor;
    switch (user.role) {
      case UserRole.admin: roleColor = AppColors.primary; break;
      case UserRole.adminMaster: roleColor = AppColors.alertOrange; break;
      case UserRole.adminDev: roleColor = Colors.purple; break;
      default: roleColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdmin ? roleColor.withValues(alpha: 0.3) : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  color: roleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkBlue,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (currentUserRole?.canManageRoles ?? false)
            PopupMenuButton<UserRole>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: onToggleRole,
              itemBuilder: (context) => [
                _buildMenuItem(UserRole.user, 'Usuário', Icons.person_outline_rounded, user.role),
                _buildMenuItem(UserRole.admin, 'Administrador', Icons.admin_panel_settings_outlined, user.role),
                if (currentUserRole == UserRole.adminDev) ...[
                  _buildMenuItem(UserRole.adminMaster, 'ADM Master', Icons.star_outline_rounded, user.role),
                  _buildMenuItem(UserRole.adminDev, 'ADM DEV', Icons.code_rounded, user.role),
                ],
              ],
            ),
        ],
      ),
    );
  }

  PopupMenuItem<UserRole> _buildMenuItem(UserRole value, String label, IconData icon, UserRole current) {
    final bool isSelected = value == current;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.darkBlue,
            )
          ),
        ],
      ),
    );
  }
}
