import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/conectea_avatar.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/account/legal/consents_view.dart';
import 'package:conectea/features/account/security/security_view.dart';
import 'package:conectea/features/account/profile/edit_profile_view.dart';
import 'package:conectea/features/account/institutional/about_conectea_view.dart';
import 'package:conectea/features/account/support/help_support_view.dart';

class AccountView extends StatelessWidget {
  final AppUser? user;

  const AccountView({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              _buildProfileHeader(user),
              const SizedBox(height: 40),
              
              _buildSectionHeader('CENTRAL DO USUÁRIO', 'Gerencie sua conta, privacidade e suporte.'),
              const SizedBox(height: 16),
              
              _buildGridMenu(context),
              
              const SizedBox(height: 32),
              _buildLogoutButton(context, authService),
              
              const SizedBox(height: 32),
              _buildSocialSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(AppUser? user) {
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (user?.email ?? 'Usuário');
        
    return Column(
      children: [
        ConecteaAvatar(
          initials: user?.initials ?? '??',
          size: 100,
          role: user?.role.name,
          paletteSeed: user?.id,
          showGlow: true,
        ),
        const SizedBox(height: 20),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            'Perfil do Titular',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.95,
      children: [
        _buildMenuCard(
          context,
          icon: PhosphorIconsRegular.userCircle,
          title: 'Meus Dados',
          description: 'Editar perfil e informações.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileView())),
        ),
        _buildMenuCard(
          context,
          icon: PhosphorIconsRegular.shieldCheck,
          title: 'Segurança',
          description: 'Senha e proteção de conta.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityView())),
        ),
        _buildMenuCard(
          context,
          icon: PhosphorIconsRegular.database,
          title: 'Privacidade',
          description: 'Dados e LGPD.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ConsentsView())),
        ),
        _buildMenuCard(
          context,
          icon: PhosphorIconsRegular.headset,
          title: 'Ajuda',
          description: 'Suporte e dúvidas.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportView())),
        ),

        _buildMenuCard(
          context,
          icon: PhosphorIconsRegular.buildings,
          title: 'Institucional',
          description: 'Sobre o ConeCTEA.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutConecteaView())),
        ),
        _buildMenuCard(
          context,
          icon: PhosphorIconsRegular.appWindow,
          title: 'Aplicativo',
          description: 'Versão e ajustes.',
          onTap: () => _showVersionDialog(context),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Informações do App', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionItem('Versão', '1.0.0'),
            _buildVersionItem('Build', '2026.05.13'),
            _buildVersionItem('Ambiente', 'Produção'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await authService.signOut();
        },
        icon: const Icon(PhosphorIconsRegular.signOut, color: AppColors.errorRed, size: 20),
        label: Text(
          'Sair da Conta',
          style: GoogleFonts.inter(
            color: AppColors.errorRed,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Text(
          'Comunidade Família TEA Bauru',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => launchUrlString(
            'https://www.instagram.com/familiateabauru/',
            mode: LaunchMode.externalApplication,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE4405F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4405F).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.instagramLogo, color: Color(0xFFE4405F), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Seguir no Instagram',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE4405F),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
