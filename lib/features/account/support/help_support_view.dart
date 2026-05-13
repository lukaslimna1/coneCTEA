import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/constants/colors.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  static const String _instagramUrl = 'https://www.instagram.com/familiateabauru';

  Future<void> _launchInstagram() async {
    await launchUrlString(
      _instagramUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
              _buildHeader(),
              const SizedBox(height: 32),
              
              _buildInternalSupportInfo(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('ATENDIMENTO'),
              _buildSupportCard(
                icon: PhosphorIconsRegular.headset,
                title: 'Falar com suporte oficial',
                description: 'Dúvidas gerais sobre sua conta, cadastro ou carteirinha.',
                onTap: _launchInstagram,
                tag: 'Canal atual',
              ),
              const SizedBox(height: 16),
              
              _buildSupportCard(
                icon: PhosphorIconsRegular.identificationCard,
                title: 'Solicitar orientação sobre dados sensíveis',
                description: 'Procedimentos para alteração de CPF, e-mail ou dados bloqueados.',
                onTap: _launchInstagram,
                tag: 'Canal atual',
              ),
              const SizedBox(height: 16),

              _buildSupportCard(
                icon: PhosphorIconsRegular.creditCard,
                title: 'Problemas com carteirinha ou cadastro',
                description: 'Reportar dados incorretos ou erro na emissão do documento digital.',
                onTap: _launchInstagram,
                tag: 'Canal atual',
              ),
              const SizedBox(height: 16),

              _buildSupportCard(
                icon: PhosphorIconsRegular.warningCircle,
                title: 'Informar problema no aplicativo',
                description: 'Relatar erros, falhas visuais ou comportamentos inesperados.',
                onTap: _launchInstagram,
                tag: 'Canal atual',
              ),
              const SizedBox(height: 40),

              _buildSectionTitle('DÚVIDAS FREQUENTES'),
              _buildFaqItem(
                'A carteirinha substitui a CIPTEA oficial?',
                'Não. A carteirinha do ConeCTEA é de uso interno nos projetos e parcerias da Família TEA Bauru e não substitui a CIPTEA oficial.',
              ),
              _buildFaqItem(
                'Como altero meu CPF ou e-mail?',
                'Por segurança, a alteração de CPF deve ser tratada diretamente com o suporte. Fluxos seguros para alteração de e-mail estão previstos para futuras atualizações do app.',
              ),
              _buildFaqItem(
                'Esqueci minha senha. O que faço?',
                'Use a opção "Esqueci minha senha" na tela de login para receber um e-mail de recuperação oficial.',
              ),
              _buildFaqItem(
                'Meus dados estão incorretos. O que faço?',
                'Edite os dados básicos em "Meus Dados" ou procure o suporte oficial para correção de dados sensíveis ou bloqueados.',
              ),

              const SizedBox(height: 40),
              _buildFooter(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternalSupportInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.info, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'O suporte interno pelo aplicativo será ativado futuramente. Por enquanto, use os canais oficiais da Família TEA Bauru para solicitar ajuda.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajuda e Suporte',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Encontre canais de atendimento, tire dúvidas e solicite orientações quando precisar.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    String? tag,
  }) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            PhosphorIconsRegular.caretRight,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            size: 20,
          ),
        ],
      ),
    );
  }


  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondary.withValues(alpha: 0.5),
            title: Text(
              question,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  answer,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'Atendimento oficial: Família TEA Bauru',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _launchInstagram,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE4405F), Color(0xFFD62976)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE4405F).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsRegular.instagramLogo, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Seguir no Instagram',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
