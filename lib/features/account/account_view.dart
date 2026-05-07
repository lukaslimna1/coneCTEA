import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';

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
          _buildMenuSection([
            _MenuItem(icon: Icons.person_outline_rounded, title: 'Dados Pessoais'),
            _MenuItem(icon: Icons.security_rounded, title: 'Segurança'),
            _MenuItem(icon: Icons.help_outline_rounded, title: 'Ajuda e Suporte'),
            _MenuItem(icon: Icons.info_outline_rounded, title: 'Sobre o Aplicativo'),
          ]),
          const SizedBox(height: 32),
          _buildLogoutButton(context, authService),
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

  Widget _buildMenuSection(List<_MenuItem> items) {
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
        children: items.map((item) => _buildMenuTile(item)).toList(),
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
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
      onTap: () {},
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
}

class _MenuItem {
  final IconData icon;
  final String title;

  _MenuItem({required this.icon, required this.title});
}
