import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/conectea_avatar.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/account/privacy/privacy_view.dart';
import 'package:conectea/features/account/security/security_view.dart';
import 'package:conectea/features/account/profile/my_data_view.dart';
import 'package:conectea/features/account/institucional/institutional_view.dart';
import 'package:conectea/features/account/suporte/support_view.dart';

class AccountView extends StatelessWidget {
  final AppUser? user;

  const AccountView({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding =
        topSafeArea + headerVisualHeight + headerClearance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 120),
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 32),

              _buildSectionHeader(
                'Central do Usuário',
                'Gerencie conta, dados, segurança e suporte.',
              ),
              const SizedBox(height: 16),

              _buildGridMenu(context),

              const SizedBox(height: 32),
              _buildLogoutButton(context, authService),
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
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
              height: 1.3,
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
      ],
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildMenuCard(
          icon: PhosphorIconsRegular.identificationCard,
          title: 'Meus Dados',
          description: 'Perfil, dependentes e correções.',
          token: DsCores.conta,
          layout: DsCardHubLayout.horizontal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyDataView()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: PhosphorIconsRegular.shieldCheck,
          title: 'Segurança',
          description: 'Acesso e proteção da conta.',
          token: DsCores.seguranca,
          layout: DsCardHubLayout.horizontal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityView()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: PhosphorIconsRegular.database,
          title: 'Privacidade',
          description: 'LGPD, dados e consentimentos.',
          token: DsCores.privacidade,
          layout: DsCardHubLayout.horizontal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyView()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: PhosphorIconsRegular.headset,
          title: 'Ajuda e Suporte',
          description: 'Suporte, dúvidas e problemas.',
          token: DsCores.suporte,
          layout: DsCardHubLayout.horizontal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportView()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: PhosphorIconsRegular.buildings,
          title: 'Institucional',
          description: 'ConeCTEA, Família TEA e projetos.',
          token: DsCores.institucional,
          layout: DsCardHubLayout.horizontal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InstitutionalView()),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: PhosphorIconsRegular.appWindow,
          title: 'Aplicativo',
          description: 'Versão, build e ambiente.',
          token: DsCores.manutencao,
          layout: DsCardHubLayout.horizontal,
          onTap: () => _showVersionDialog(context),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required DsCorVisual token,
    required DsCardHubLayout layout,
    required VoidCallback onTap,
  }) {
    return DsCardHub(
      title: title,
      description: description,
      icon: icon,
      token: token,
      onTap: onTap,
      compact: true,
      layout: layout,
      showChevron: true,
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Informações do ConeCTEA',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Bloco inicial compacto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildVersionRow('Versão', '1.0.0'),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 16,
                      ),
                      _buildVersionRow('Build', '2026.05.13'),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 16,
                      ),
                      _buildVersionRow('Ambiente', 'Produção'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Tecnologias de apoio
                Text(
                  'Tecnologias de apoio',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTechBlock(
                  'Supabase',
                  'Autenticação, banco de dados e organização segura das informações do app.',
                ),
                _buildTechBlock(
                  'OneSignal',
                  'Envio de notificações importantes sobre conta, solicitações, carteirinha e comunicados.',
                ),
                _buildTechBlock(
                  'Google Apps Script / Google Drive',
                  'Apoio operacional para recebimento e organização temporária de documentos, conforme as regras de privacidade.',
                ),
                _buildTechBlock(
                  'Flutter',
                  'Tecnologia usada para construir a experiência mobile do ConeCTEA.',
                ),
                const SizedBox(height: 12),

                // 3. Transparência
                Text(
                  'Transparência',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DsCores.institucional.softBackground.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DsCores.institucional.border.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: Text(
                    'O ConeCTEA utiliza serviços de terceiros para manter o app funcionando com segurança, organização e comunicação. As marcas citadas pertencem aos seus respectivos titulares. A citação desses serviços não representa parceria oficial, patrocínio ou endosso comercial.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: DsBotao(
                label: 'Fechar',
                onPressed: () => Navigator.pop(context),
                variante: DsBotaoVariante.acao,
                token: DsCores.manutencao,
                icon: PhosphorIconsRegular.x,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTechBlock(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: DsCores.manutencao.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
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
        icon: const Icon(
          PhosphorIconsRegular.signOut,
          color: AppColors.errorRed,
          size: 20,
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
}
