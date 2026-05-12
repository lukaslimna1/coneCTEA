import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/account/security/security_view.dart';
import 'package:conectea/features/account/profile/edit_profile_view.dart';
import 'package:conectea/features/account/institutional/about_conectea_view.dart';

class AccountView extends StatelessWidget {
  final AppUser? user;
  final String initials;

  const AccountView({super.key, this.user, this.initials = 'U'});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 100),
              _buildProfileHeader(user),
              const SizedBox(height: 32),
              _buildMenuSection(context, [
                _MenuItem(
                  icon: PhosphorIconsRegular.user,
                  title: 'Dados Pessoais',
                  onTap: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileView(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: PhosphorIconsRegular.shieldCheck,
                  title: 'Segurança',
                  onTap: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => const SecurityView(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: PhosphorIconsRegular.question,
                  title: 'Ajuda e Suporte',
                  onTap: (ctx) {},
                ),
                _MenuItem(
                  icon: PhosphorIconsRegular.info,
                  title: 'Sobre o ConeCTEA',
                  onTap: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => const AboutConecteaView(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              _buildLogoutButton(context, authService),
              const SizedBox(height: 32),
              _buildSocialSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser? user) {
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (user?.email ?? 'Usuário');

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                Color(0xFF0C2445), // Azul mais escuro
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.cardTitle,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Perfil do Titular',
          style: TextStyle(
            color: AppColors.cardSubtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, List<_MenuItem> items) {
    return PremiumCard(
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              _buildMenuTile(context, item),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderLight.withValues(alpha: 0.5),
                  indent: 56,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, _MenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: AppColors.cardTitle, size: 22),
      ),
      title: Text(
        item.title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppColors.cardTitle,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        PhosphorIconsRegular.caretRight,
        color: AppColors.cardMutedText,
        size: 20,
      ),
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
        icon: const Icon(
          PhosphorIconsRegular.signOut,
          color: AppColors.errorRed,
        ),
        label: Text(
          'Sair da Conta',
          style: GoogleFonts.inter(
            color: AppColors.errorRed,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.errorRed.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Text(
          'Acompanhe nossa comunidade',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.cardMutedText,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              icon: PhosphorIconsRegular.instagramLogo,
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
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
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
