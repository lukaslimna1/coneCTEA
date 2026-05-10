import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';
import '../../core/widgets/premium/premium_card.dart';

class FamilyTeaView extends StatelessWidget {
  const FamilyTeaView({super.key});

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
          'Família TEA Bauru',
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
              icon: PhosphorIconsRegular.usersThree,
              title: 'Família TEA Bauru',
              subtitle: 'Rede de apoio, inclusão e acolhimento.',
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroSection(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                  const SizedBox(height: 24),
                  _buildWhatWeDoSection(),
                  const SizedBox(height: 24),
                  _buildMovementSection(),
                  const SizedBox(height: 24),
                  _buildToothFairySection(),
                  const SizedBox(height: 24),
                  _buildMissionSection(),
                  const SizedBox(height: 24),
                  _buildWhyItMattersSection(),
                  const SizedBox(height: 24),
                  _buildConecteaSection(),
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
      child: _buildRichText(
        'A Família TEA Bauru é uma rede de apoio criada para acolher, orientar e fortalecer famílias atípicas, pessoas autistas e a comunidade.\n\n'
        'Sua atuação nasce da escuta, da troca de experiências e da necessidade de construir caminhos mais humanos, acessíveis e inclusivos para quem vive a realidade do Transtorno do Espectro Autista e de outras deficiências.\n\n'
        'A Família TEA Bauru reúne famílias, voluntários, profissionais, parceiros e pessoas comprometidas com a inclusão, promovendo informação, acolhimento, conscientização e apoio prático no dia a dia.\n\n'
        'Mais do que uma iniciativa, a Família TEA Bauru representa uma rede viva de cuidado, união e pertencimento.'
      ),
    );
  }

  Widget _buildHistorySection() {
    return PremiumCard(
      title: 'Nossa história',
      child: _buildRichText(
        'A Família TEA Bauru surgiu a partir da necessidade de unir famílias, compartilhar informações e criar espaços de apoio para pessoas autistas, familiares e cuidadores.\n\n'
        'Com o tempo, essa rede foi crescendo e fortalecendo sua atuação por meio de rodas de conversa, eventos presenciais, lives, palestras, ações comunitárias e parcerias com pessoas e instituições comprometidas com a inclusão.\n\n'
        'A essência da Família TEA Bauru está na união entre famílias e na construção de uma comunidade mais acolhedora, informada e preparada para respeitar as diferenças.'
      ),
    );
  }

  Widget _buildWhatWeDoSection() {
    return PremiumCard(
      title: 'O que a Família TEA faz?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            'A Família TEA Bauru atua para apoiar famílias atípicas e promover inclusão por meio de informação, acolhimento, orientação e ações práticas.\n\n'
            'Entre suas frentes de atuação estão:'
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('Acolhimento e escuta de famílias;'),
          _buildBulletPoint('Compartilhamento de informações sobre autismo e inclusão;'),
          _buildBulletPoint('Rodas de conversa e encontros;'),
          _buildBulletPoint('Lives e palestras informativas;'),
          _buildBulletPoint('Eventos presenciais de conscientização;'),
          _buildBulletPoint('Apoio a projetos e ações sociais;'),
          _buildBulletPoint('Fortalecimento de redes entre famílias, profissionais e parceiros;'),
          _buildBulletPoint('Incentivo ao acesso a direitos, cuidado e inclusão.'),
        ],
      ),
    );
  }

  Widget _buildMovementSection() {
    return PremiumCard(
      title: 'Movimento Todos Pelo Autismo',
      child: _buildRichText(
        'O Movimento Todos Pelo Autismo nasceu como uma iniciativa ligada à atuação da Família TEA Bauru, ampliando o alcance das ações de conscientização, inclusão e mobilização social.\n\n'
        'O movimento reúne pessoas, famílias, voluntários e parceiros que acreditam na construção de espaços mais acessíveis, respeitosos e preparados para acolher pessoas autistas e pessoas com deficiência.\n\n'
        'Seu propósito é fortalecer a informação, combater barreiras e estimular uma sociedade mais consciente e inclusiva.'
      ),
    );
  }

  Widget _buildToothFairySection() {
    return PremiumCard(
      title: 'Projeto Fada do Dente',
      child: _buildRichText(
        'O Fada do Dente é um projeto voltado ao cuidado odontológico de crianças com deficiência, com atenção especial às crianças autistas.\n\n'
        'A iniciativa surge da necessidade de acolher crianças que enfrentam barreiras sensoriais, medo, dificuldade de adaptação ou falta de profissionais preparados para compreender suas necessidades.\n\n'
        'O projeto busca promover um atendimento mais humanizado, acessível e acolhedor, além de orientar famílias sobre cuidados de saúde bucal e construção de rotinas mais tranquilas.'
      ),
    );
  }

  Widget _buildMissionSection() {
    return PremiumCard(
      title: 'Nossa missão',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(
            'A missão da Família TEA Bauru é apoiar famílias, ampliar o acesso à informação, fortalecer a inclusão e criar uma rede de acolhimento para pessoas autistas, pessoas com deficiência e seus familiares.\n\n'
            'A atuação da Família TEA Bauru é guiada por valores como:'
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('Acolhimento;'),
          _buildBulletPoint('Respeito;'),
          _buildBulletPoint('Inclusão;'),
          _buildBulletPoint('Escuta;'),
          _buildBulletPoint('Empatia;'),
          _buildBulletPoint('Orientação;'),
          _buildBulletPoint('União;'),
          _buildBulletPoint('Fortalecimento comunitário.'),
        ],
      ),
    );
  }

  Widget _buildWhyItMattersSection() {
    return PremiumCard(
      title: 'Por que isso importa?',
      child: _buildRichText(
        'Muitas famílias atípicas enfrentam dúvidas, sobrecarga, falta de informação, dificuldades de acesso e ausência de uma rede de apoio próxima.\n\n'
        'A Família TEA Bauru atua para que essas famílias não caminhem sozinhas.\n\n'
        'Através da troca, da informação e da mobilização coletiva, a rede ajuda a transformar experiências individuais em força comunitária.'
      ),
    );
  }

  Widget _buildConecteaSection() {
    return PremiumCard(
      title: 'ConeCTEA e Família TEA',
      child: _buildRichText(
        'O ConeCTEA nasce como o aplicativo oficial da Família TEA Bauru.\n\n'
        'Ele foi criado para apoiar a organização digital da rede, facilitar o acesso a informações, acompanhar solicitações, centralizar comunicados e preparar o caminho para novos projetos e serviços dentro do app.\n\n'
        'A tecnologia entra como uma ponte entre a Família TEA Bauru e a comunidade acompanhada, ajudando a tornar processos mais simples, acessíveis e organizados.'
      ),
    );
  }

  Widget _buildSummarySection() {
    return PremiumCard(
      title: 'Em resumo',
      hasGradient: true,
      child: _buildRichText(
        'A Família TEA Bauru é uma rede de apoio que acolhe, orienta e fortalece famílias atípicas, pessoas autistas e comunidade.\n\n'
        'Sua atuação envolve informação, encontros, ações, projetos, conscientização e parcerias.\n\n'
        'O ConeCTEA é uma ferramenta digital criada para apoiar essa missão, aproximando a comunidade dos projetos, comunicados e serviços vinculados à Família TEA Bauru.'
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
