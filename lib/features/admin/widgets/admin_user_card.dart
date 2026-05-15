import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/conectea_avatar.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/models/app_user.dart';

class AdminUserCard extends StatelessWidget {
  final AppUser user;
  final UserRole? currentUserRole;
  final Function(UserRole) onToggleRole;
  final VoidCallback? onEditProfile;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.currentUserRole,
    required this.onToggleRole,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.initials;

    return PremiumCard(
      hasGradient: true,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ConecteaAvatar(
            initials: initials,
            size: 50,
            role: user.role.name,
            paletteSeed: user.id,
            showGlow: true,
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
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'edit') {
                  onEditProfile?.call();
                } else {
                  // Converte string de volta para UserRole
                  final role = UserRole.values.firstWhere((e) => e.dbValue == value);
                  onToggleRole(role);
                }
              },
              itemBuilder: (context) => [
                if (currentUserRole?.canRunMaintenance ?? false)
                  _buildMenuAction('edit', 'Editar Cadastro', Icons.edit_note_rounded),
                
                const PopupMenuDivider(),
                
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

  PopupMenuItem<String> _buildMenuAction(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(UserRole value, String label, IconData icon, UserRole current) {
    final bool isSelected = value == current;
    return PopupMenuItem(
      value: value.dbValue,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            )
          ),
        ],
      ),
    );
  }
}
