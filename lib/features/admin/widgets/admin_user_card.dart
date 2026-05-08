import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../models/app_user.dart';

class AdminUserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onToggleRole;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onToggleRole,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role == UserRole.admin;
    final initials = user.name.isNotEmpty 
        ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdmin ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight),
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
              color: isAdmin ? AppColors.primary.withValues(alpha: 0.1) : AppColors.purpleLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADMIN',
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
          PopupMenuButton<UserRole>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (newRole) {
              // We check if it's different in the calling method, 
              // but here we just pass the action.
              onToggleRole();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: UserRole.user,
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20, color: !isAdmin ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('Mudar para Usuário', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: UserRole.admin,
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 20, color: isAdmin ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('Mudar para Admin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
