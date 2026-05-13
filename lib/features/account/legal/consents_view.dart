import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';

class ConsentsView extends StatelessWidget {
  const ConsentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C1C),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF071326).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Transparência e Dados',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const PremiumHero(
              icon: PhosphorIconsRegular.shieldCheck,
              title: 'Gestão de Privacidade',
              subtitle:
                  'Entenda como seus dados são protegidos e utilizados no ecossistema ConeCTEA.',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTransparencyHeader(),

                  const SizedBox(height: 32),
                  _buildSectionHeader('DADOS NECESSÁRIOS PARA O APP'),
                  _buildSectionSupportText(
                    'Alguns dados são essenciais para que o ConeCTEA funcione e para que a Família TEA Bauru organize seus projetos e atendimentos.',
                  ),

                  _buildStaticConsentCard(
                    title: 'Cadastro e Identidade',
                    description:
                        'Dados pessoais informados no registro para identificação única e segurança da conta.',
                    icon: PhosphorIconsRegular.userCircle,
                  ),
                  _buildStaticConsentCard(
                    title: 'Emissão da Carteirinha',
                    description:
                        'Dados necessários para análise, emissão e liberação da Carteira de Identificação interna.',
                    icon: PhosphorIconsRegular.identificationCard,
                  ),
                  _buildStaticConsentCard(
                    title: 'Saúde e Deficiência',
                    description:
                        'Informações sensíveis utilizadas para validação de diagnósticos em programas, projetos e atendimentos.',
                    icon: PhosphorIconsRegular.heartbeat,
                  ),
                  _buildStaticConsentCard(
                    title: 'Notificações Operacionais',
                    description:
                        'Alertas essenciais sobre status de solicitações, segurança e avisos administrativos urgentes.',
                    icon: PhosphorIconsRegular.bellRinging,
                  ),
                  _buildStaticConsentCard(
                    title: 'Dependente Vinculado',
                    description:
                        'Dados de terceiros sob sua responsabilidade para gestão de benefícios e documentos digitais.',
                    icon: PhosphorIconsRegular.usersThree,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('PREFERÊNCIAS E ESTATÍSTICAS FUTURAS'),
                  _buildSectionSupportText(
                    'Dados estatísticos agrupados ajudam a Família TEA Bauru a entender o impacto social, buscar apoios e melhorar os atendimentos, sem identificar pessoas individualmente.',
                  ),

                  _buildFutureConsentCard(
                    title: 'Comunicações e Novidades',
                    description:
                        'Receber informações sobre eventos, palestras e atualizações da comunidade Família TEA Bauru.',
                    icon: PhosphorIconsRegular.megaphone,
                  ),
                  _buildFutureConsentCard(
                    title: 'Pesquisas de Impacto',
                    description:
                        'Participar de formulários de melhoria e métricas de satisfação dos serviços prestados.',
                    icon: PhosphorIconsRegular.clipboardText,
                  ),
                  _buildFutureConsentCard(
                    title: 'Dados Estatísticos Agrupados',
                    description:
                        'Uso de métricas gerais para relatórios institucionais e parcerias públicas/privadas.',
                    icon: PhosphorIconsRegular.chartBar,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('AUTORIZAÇÕES ESPECÍFICAS FUTURAS'),
                  _buildSectionSupportText(
                    'Algumas autorizações serão solicitadas separadamente, no momento da inscrição em eventos, consultas ou ações específicas.',
                  ),

                  _buildSpecificConsentCard(
                    title: 'Inscrição em Projetos',
                    description:
                        'Participação em triagens, atendimentos ou projetos sociais específicos da Família TEA Bauru.',
                    icon: PhosphorIconsRegular.handHeart,
                  ),
                  _buildSpecificConsentCard(
                    title: 'Uso de Imagem e Voz',
                    description:
                        'Autorização para fotos, vídeos ou depoimentos em divulgações institucionais de eventos.',
                    icon: PhosphorIconsRegular.camera,
                  ),
                  _buildSpecificConsentCard(
                    title: 'Parceiros Autorizados',
                    description:
                        'Compartilhamento de dados com clínicas ou organizações parceiras para benefícios diretos.',
                    icon: PhosphorIconsRegular.handshake,
                  ),

                  const SizedBox(height: 40),
                  _buildGovernanceFooter(),

                  const SizedBox(height: 32),
                  _buildDoneButton(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparencyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.info,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informação Importante',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A gestão detalhada de cada item será ativada em uma atualização futura. Por enquanto, os consentimentos principais são coletados no cadastro.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          Text(
            'O ConeCTEA é o aplicativo oficial da Família TEA Bauru. As autorizações se aplicam ao uso dos dados nos processos digitais e nas ações presenciais vinculadas à instituição.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionSupportText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 20, right: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildStaticConsentCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return _buildBaseCard(
      title: title,
      description: description,
      icon: icon,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.statusGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_rounded,
              color: AppColors.statusGreen,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'ATIVO',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.statusGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureConsentCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return _buildBaseCard(
      title: title,
      description: description,
      icon: icon,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'EM BREVE',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificConsentCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return _buildBaseCard(
      title: title,
      description: description,
      icon: icon,
      trailing: Icon(
        PhosphorIconsRegular.clockAfternoon,
        color: AppColors.textSecondary.withValues(alpha: 0.3),
        size: 20,
      ),
    );
  }

  Widget _buildBaseCard({
    required String title,
    required String description,
    required IconData icon,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernanceFooter() {
    return Column(
      children: [
        const Divider(color: Colors.white10),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.database,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'GOVERNANÇA E AUDITORIA',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Versões futuras da gestão de privacidade incluirão registro de data/hora do aceite, histórico de versões dos termos, controle de revogação imediata e trilha de auditoria digital para maior segurança de todos os membros.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0891B2).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'ENTENDI',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
