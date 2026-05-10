import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';
import '../../core/widgets/premium/premium_card.dart';

class AboutConecteaView extends StatelessWidget {
  const AboutConecteaView({super.key});

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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Sobre o ConeCTEA',
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
              icon: PhosphorIconsRegular.info,
              title: 'Sobre o ConeCTEA',
              subtitle: 'O aplicativo oficial da Família TEA Bauru.',
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroSection(),
                  const SizedBox(height: 24),
                  _buildImportantSection(),
                  const SizedBox(height: 24),
                  _buildPurposeSection(),
                  const SizedBox(height: 24),
                  _buildDigitalCardSection(),
                  const SizedBox(height: 24),
                  _buildFamilyTeaSection(),
                  const SizedBox(height: 24),
                  _buildSummarySection(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            'O ConeCTEA é o aplicativo oficial da Família TEA Bauru, criado para aproximar famílias, responsáveis, participantes e a associação em um ambiente digital mais organizado, acessível e seguro.\n\n'
            'A proposta do app é facilitar o acesso a informações, acompanhar solicitações, centralizar comunicados e apoiar os programas, projetos, benefícios, ações e atendimentos realizados pela Família TEA Bauru.\n\n'
            'A carteirinha digital disponível no ConeCTEA faz parte desse ecossistema. Ela funciona como uma identificação interna, voltada ao uso dentro dos projetos, programas e ações vinculados à Família TEA Bauru.\n\n'
            'Ela pode ajudar na organização dos participantes, na validação de vínculos com a associação e no acesso a iniciativas internas ou parcerias cadastradas dentro do projeto.'
          ),
        ],
      ),
    );
  }

  Widget _buildImportantSection() {
    return PremiumCard(
      backgroundColor: AppColors.errorRed.withValues(alpha: 0.05),
      borderOverride: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.warningCircle, color: AppColors.errorRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Importante',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRichText(
            'A carteirinha digital do ConeCTEA não substitui documentos oficiais, laudos médicos, documentos pessoais ou carteirinhas públicas emitidas por órgãos governamentais.\n\n'
            'Ela também não é uma CIPTEA.\n\n'
            'A CIPTEA é a Carteira de Identificação da Pessoa com Transtorno do Espectro Autista, emitida pelos órgãos públicos responsáveis, conforme as regras oficiais de cada localidade.\n\n'
            'O ConeCTEA não tem a finalidade de substituir esse documento.',
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeSection() {
    return PremiumCard(
      title: 'Para que serve o ConeCTEA?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            'O ConeCTEA foi criado para apoiar a Família TEA Bauru na organização e comunicação dos seus projetos.\n\n'
            'Dentro do app, a família ou participante poderá acompanhar informações importantes, solicitações, comunicados, dados da carteirinha interna e futuras funcionalidades ligadas aos programas da associação.'
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('Acompanhar solicitações;'),
          _buildBulletPoint('Acessar a carteirinha digital interna;'),
          _buildBulletPoint('Receber comunicados e orientações;'),
          _buildBulletPoint('Consultar informações sobre o app;'),
          _buildBulletPoint('Apoiar a organização dos projetos da Família TEA Bauru;'),
          _buildBulletPoint('Facilitar o contato com a associação;'),
          _buildBulletPoint('Futuramente, acessar novos programas e serviços integrados ao app.'),
        ],
      ),
    );
  }

  Widget _buildDigitalCardSection() {
    return PremiumCard(
      title: 'Sobre a carteirinha digital',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            'A carteirinha digital do ConeCTEA é uma identificação interna da Família TEA Bauru.\n\n'
            'Ela é voltada ao uso nos projetos, programas, ações, benefícios e parcerias vinculados à associação.\n\n'
            'Seu objetivo é facilitar a organização e a comunicação dentro do ecossistema da Família TEA Bauru, sem substituir documentos oficiais.'
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.shieldCheck, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A carteirinha do ConeCTEA não deve ser usada como documento público oficial e não substitui a CIPTEA.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTeaSection() {
    return PremiumCard(
      title: 'Sobre a Família TEA Bauru',
      child: _buildRichText(
        'A Família TEA Bauru é uma rede de apoio voltada ao acolhimento, inclusão, orientação e fortalecimento de famílias atípicas, pessoas autistas e comunidade.\n\n'
        'O ConeCTEA nasce como uma ferramenta digital para apoiar essa missão, trazendo mais organização, comunicação e acesso aos projetos desenvolvidos pela Família TEA Bauru.'
      ),
    );
  }

  Widget _buildSummarySection() {
    return PremiumCard(
      title: 'Em resumo',
      hasGradient: true,
      child: _buildRichText(
        'O ConeCTEA é uma ferramenta digital da Família TEA Bauru para apoiar a comunidade acompanhada pela associação.\n\n'
        'Ele ajuda a organizar informações, acompanhar solicitações, facilitar o acesso à carteirinha interna e preparar o caminho para novos programas e projetos dentro do app.\n\n'
        'A carteirinha digital é interna e vinculada à Família TEA Bauru.\n\n'
        'Ela não é uma CIPTEA e não substitui documentos oficiais.'
      ),
    );
  }

  Widget _buildRichText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
