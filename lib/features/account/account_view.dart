import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import './security_view.dart';
import './edit_profile_view.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(user?.email ?? 'Usuário'),
          const SizedBox(height: 32),
          _buildMenuSection(context, [
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Dados Pessoais',
              onTap: (ctx) => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (context) => const EditProfileView()),
              ),
            ),
            _MenuItem(
              icon: Icons.security_rounded,
              title: 'Segurança',
              onTap: (ctx) => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (context) => const SecurityView()),
              ),
            ),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Ajuda e Suporte',
              onTap: (ctx) {},
            ),
            _MenuItem(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o Aplicativo',
              onTap: (ctx) {},
            ),
          ]),
          const SizedBox(height: 32),
          _buildLogoutButton(context, authService),
          const SizedBox(height: 32),
          _buildSocialSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String email) {
    // Get initial from email
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          email,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'Perfil do Titular',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) => _buildMenuTile(context, item)).toList(),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, _MenuItem item) {
    return ListTile(
      leading: Icon(item.icon, color: AppColors.textPrimary),
      title: Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: () => item.onTap?.call(context),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await authService.signOut();
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
        label: const Text(
          'Sair da Conta',
          style: TextStyle(
            color: AppColors.errorRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.errorRed, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        const Text(
          'Acompanhe nossa comunidade',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: Icons.camera_alt_rounded,
              label: 'Instagram',
              color: const Color(0xFFE4405F),
              onTap: () => launchUrlString(
                'https://www.instagram.com/familiateabauru/',
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Function(BuildContext)? onTap;

  _MenuItem({required this.icon, required this.title, this.onTap});
}
