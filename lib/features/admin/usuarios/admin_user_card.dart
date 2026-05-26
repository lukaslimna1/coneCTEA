import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
          if (_shouldShowMenu())
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
              color: const Color(0xFA0F172A), // Night Blue (Dark Glass denso)
              surfaceTintColor: const Color(0xFA0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
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
                  _buildMenuAction('edit', 'Editar dados sensíveis', PhosphorIcons.lockSimple(PhosphorIconsStyle.bold)),
                
                if (currentUserRole?.canRunMaintenance ?? false)
                  const PopupMenuDivider(height: 1),
                
                _buildMenuItem(UserRole.user, 'Usuário', user.role),
                _buildMenuItem(UserRole.admin, 'Administrador', user.role),
                if (currentUserRole == UserRole.adminDev) ...[
                  _buildMenuItem(UserRole.adminMaster, 'ADM Master', user.role),
                  _buildMenuItem(UserRole.adminDev, 'ADM DEV', user.role),
                ],
              ],
            ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuAction(String value, String label, IconData icon) {
    const Color securityColor = Color(0xFF6366F1); // Índigo semântico de privacidade/segurança
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: securityColor),
          const SizedBox(width: 12),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: FontWeight.w700,
              color: securityColor,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(UserRole value, String label, UserRole current) {
    final bool isSelected = value == current;

    // Mapeamento de cor e ícone semântico idênticos ao ConecteaRoleBadge
    final Color roleColor;
    final IconData roleIcon;

    switch (value) {
      case UserRole.adminDev:
        roleColor = const Color(0xFFA78BFA); // Violeta Dev
        roleIcon = PhosphorIcons.codeSimple(PhosphorIconsStyle.bold);
        break;
      case UserRole.adminMaster:
        roleColor = const Color(0xFFFBBF24); // Dourado Master
        roleIcon = PhosphorIcons.crown(PhosphorIconsStyle.bold);
        break;
      case UserRole.admin:
        roleColor = const Color(0xFF34D399); // Esmeralda Admin
        roleIcon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold);
        break;
      case UserRole.user:
        roleColor = const Color(0xFF94A3B8); // Slate User
        roleIcon = PhosphorIcons.user(PhosphorIconsStyle.bold);
        break;
    }

    return PopupMenuItem(
      value: value.dbValue,
      child: Row(
        children: [
          Icon(
            roleIcon,
            size: 20,
            color: isSelected ? roleColor : roleColor.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? roleColor : AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              PhosphorIcons.check(PhosphorIconsStyle.bold),
              size: 16,
              color: roleColor,
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowMenu() {
    if (currentUserRole == null) return false;
    if (!currentUserRole!.canManageRoles) return false;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final isSelf = user.id == currentUserId;
    if (isSelf) return false;

    if (currentUserRole == UserRole.adminMaster) {
      return user.role == UserRole.user || user.role == UserRole.admin;
    }

    if (currentUserRole == UserRole.adminDev) {
      return true;
    }

    return false;
  }
}
