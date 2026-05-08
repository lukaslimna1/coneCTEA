import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPremium,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPremium,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacidade',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.darkBlue,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(),
            const SizedBox(height: 40),
            _buildSectionTitle('1. Sobre esta Política de Privacidade'),
            _buildParagraph(
              'Esta Política de Privacidade explica como o aplicativo ConeCTEA coleta, utiliza, armazena, protege e trata os dados pessoais dos usuários.\n\n'
              'O objetivo deste documento é garantir transparência sobre o uso das informações cadastradas no aplicativo, especialmente aquelas relacionadas à conta do usuário, solicitação de carteirinha, acompanhamento de status, comunicação com a instituição e geração de informações internas para melhoria do atendimento.\n\n'
              'Ao criar uma conta, utilizar o aplicativo ou solicitar uma carteirinha digital, o usuário declara estar ciente desta Política de Privacidade.'
            ),
            
            _buildSectionTitle('2. Sobre o ConeCTEA'),
            _buildParagraph(
              'O ConeCTEA é um aplicativo criado para facilitar a solicitação, acompanhamento, organização e visualização da carteirinha digital vinculada à instituição responsável.\n\n'
              'O aplicativo permite que usuários ou responsáveis possam:\n'
              '• criar uma conta;\n'
              '• acessar o app com e-mail e senha;\n'
              '• solicitar carteirinha digital;\n'
              '• acompanhar o status da solicitação;\n'
              '• visualizar a carteirinha, quando aprovada;\n'
              '• receber orientações e notificações;\n'
              '• consultar informações de segurança, privacidade e suporte;\n'
              '• manter contato com a instituição responsável.\n\n'
              'O ConeCTEA atua como uma ferramenta digital de apoio, organização e comunicação entre usuários, responsáveis e instituição.'
            ),

            _buildSectionTitle('3. Quem é responsável pelos dados'),
            _buildParagraph(
              'A instituição responsável pelo uso e administração do ConeCTEA é:\n'
              'Família TEA Bauru\n'
              'Cidade/Estado: Bauru — SP\n'
              'Contato oficial: Instagram — @familiateabauru\n'
              'Link oficial: https://www.instagram.com/familiateabauru\n\n'
              'A instituição é responsável por definir as finalidades de uso dos dados dentro do aplicativo, analisar solicitações, gerenciar carteirinhas, acompanhar cadastros e orientar os usuários sobre o uso da plataforma.'
            ),

            _buildSectionTitle('4. Quais dados podem ser coletados'),
            _buildParagraph(
              'O ConeCTEA poderá coletar e utilizar informações necessárias para cadastro, autenticação, solicitação, análise, emissão da carteirinha digital, suporte e melhoria do serviço.'
            ),
            _buildSubSection('4.1 Dados de identificação e cadastro'),
            _buildParagraph(
              'Podem ser coletados: nome completo; e-mail; telefone, quando informado; cidade; estado; data de nascimento; instituição indicada, quando informada; perfil do usuário, quando aplicável; informações necessárias para criação e manutenção da conta.'
            ),
            _buildSubSection('4.2 Dados de acesso e autenticação'),
            _buildParagraph(
              'Para permitir o acesso seguro ao aplicativo, poderão ser tratados: e-mail de login; senha criptografada ou protegida pelo sistema de autenticação; dados de sessão; data e horário de acessos; informações básicas do dispositivo; registros de segurança relacionados ao uso da conta.\n'
              'A senha do usuário não deve ser exibida ou acessada diretamente pela equipe administrativa do aplicativo.'
            ),
            _buildSubSection('4.3 Dados relacionados à carteirinha digital'),
            _buildParagraph(
              'Para solicitação, análise, emissão e validação da carteirinha digital, poderão ser utilizados: dados informados no cadastro; número ou código da carteirinha; status da solicitação; status da carteirinha; data de solicitação; data de aprovação, quando houver; data de emissão; data de validade; QR Code ou código de validação; histórico de movimentações da solicitação; observações administrativas necessárias para análise.'
            ),
            _buildSubSection('4.4 Dados complementares autodeclarados'),
            _buildParagraph(
              'O ConeCTEA poderá coletar algumas informações complementares para fins de organização, análise interna, melhoria do atendimento e compreensão do público atendido.\n'
              'Esses dados poderão incluir: cidade; idade ou faixa etária; gênero; cor/race; informações de indicação institucional, quando houver; dados relacionados ao status da solicitação ou da carteirinha.\n'
              'Sempre que possível, essas informações serão utilizadas em formato estatístico e agrupado, sem exposição direta da identidade dos usuários.'
            ),
            _buildSubSection('4.5 Dados de suporte e comunicação'),
            _buildParagraph(
              'Quando o usuário entrar em contato com a instituição ou utilizar canais de suporte, poderão ser tratados: nome; e-mail; telefone ou perfil de contato; mensagem enviada; tipo de solicitação; informações necessárias para atendimento; histórico de suporte, quando aplicável.\n'
              'Caso o contato seja feito por canal externo, como Instagram, WhatsApp, e-mail ou outro meio, o tratamento também poderá seguir as regras e políticas da própria plataforma utilizada.'
            ),
            _buildSubSection('4.6 Dados de notificações'),
            _buildParagraph(
              'Para envio de avisos e comunicações importantes, o aplicativo poderá utilizar: identificador do dispositivo; permissão de notificação; status de recebimento de notificações; preferências de comunicação; histórico básico de envio de avisos, quando aplicável.\n'
              'Essas informações ajudam o app a enviar alertas sobre solicitação, carteirinha, atualizações, segurança e comunicados institucionais.'
            ),

            _buildSectionTitle('5. Dados pessoais sensíveis'),
            _buildParagraph(
              'Algumas informações tratadas pelo ConeCTEA podem ser consideradas sensíveis, dependendo do contexto.\n'
              'Podem ser considerados dados sensíveis: informações sobre cor/raça; informações relacionadas à saúde, condição, diagnóstico ou atendimento, quando informadas; informações sobre crianças ou adolescentes; dados vinculados à identificação de pessoa com TEA ou condição relacionada, quando aplicável.\n'
              'Esses dados exigem cuidado maior e deverão ser tratados apenas quando forem necessários para a finalidade do aplicativo, para solicitação ou validação da carteirinha, para atendimento institucional ou para cumprimento de obrigações e procedimentos da instituição responsável.\n'
              'O ConeCTEA deve evitar a exposição desnecessária desses dados e limitar o acesso apenas a pessoas autorizadas.'
            ),

            _buildSectionTitle('6. Dados de crianças, adolescentes e responsáveis'),
            _buildParagraph(
              'O ConeCTEA poderá ser utilizado por responsáveis legais, familiares ou representantes autorizados para cadastro, solicitação e acompanhamento de carteirinha de crianças, adolescentes ou pessoas que necessitem de representação.\n'
              'Quando o cadastro envolver criança ou adolescente, o tratamento dos dados deverá observar o melhor interesse do titular e ser realizado com ciência ou autorização do responsável legal, conforme aplicável.\n'
              'O responsável declara que possui autorização para informar os dados necessários no aplicativo e acompanhar as solicitações vinculadas à pessoa representada.'
            ),

            _buildSectionTitle('7. O que o app não armazena diretamente'),
            _buildParagraph(
              'O ConeCTEA prioriza uma estrutura leve, segura e organizada. Por isso, o aplicativo não tem como objetivo armazenar diretamente arquivos pesados ou documentos sensíveis dentro do app, como:\n'
              '• fotos de documentos;\n'
              '• vídeos;\n'
              '• laudos em PDF;\n'
              '• imagens pesadas;\n'
              '• arquivos enviados pelo usuário;\n'
              '• documentos digitalizados extensos.\n\n'
              'Quando algum documento ou comprovação for necessário, a instituição poderá orientar o usuário a utilizar canais externos oficiais. O app poderá informar quais documentos são necessários, por qual motivo foram solicitados e qual canal deverá ser utilizado para envio.'
            ),

            _buildSectionTitle('8. Para que os dados são utilizados'),
            _buildParagraph(
              'Os dados tratados pelo ConeCTEA poderão ser utilizados para as seguintes finalidades:\n'
              '• criar e manter a conta do usuário;\n'
              '• permitir login e autenticação;\n'
              '• identificar o usuário dentro do aplicativo;\n'
              '• permitir solicitação de carteirinha digital;\n'
              '• analisar informações cadastradas;\n'
              '• atualizar o status da solicitação;\n'
              '• aprovar, reprovar, suspender ou renovar carteirinhas;\n'
              '• emitir e exibir carteirinha digital;\n'
              '• permitir validação da carteirinha;\n'
              '• enviar avisos e notificações;\n'
              '• oferecer suporte ao usuário;\n'
              '• melhorar a comunicação com a instituição;\n'
              '• organizar processos administrativos internos;\n'
              '• gerar estatísticas internas;\n'
              '• melhorar o atendimento e a experiência no aplicativo;\n'
              '• garantir segurança e prevenção de uso indevido;\n'
              '• cumprir obrigações legais, regulatórias, administrativas ou institucionais, quando aplicável.'
            ),

            _buildSectionTitle('9. Uso estatístico e dados agregados'),
            _buildParagraph(
              'O ConeCTEA poderá utilizar informações cadastradas de forma estatística, agrupada e sem exposição direta de nomes, e-mails, telefones ou outros elementos de identificação direta.\n'
              'Essas informações poderão ser utilizadas internamente para gestão, planejamento, melhoria do serviço, acompanhamento institucional e tomada de decisão.\n\n'
              'As estatísticas poderão incluir:\n'
              '• número total de pessoas cadastradas;\n'
              '• número de carteirinhas solicitadas;\n'
              '• número de carteirinhas aprovadas;\n'
              '• número de carteirinhas reprovadas;\n'
              '• número de solicitações pendentes;\n'
              '• quantidade de usuários por cidade;\n'
              '• quantidade de usuários por faixa etária;\n'
              '• quantidade de usuários por gênero;\n'
              '• quantidade de usuários por cor/raça;\n'
              '• quantidade de solicitações por status;\n'
              '• indicadores gerais de uso do aplicativo.\n\n'
              'Esses dados serão utilizados como números e indicadores, não como exposição individual de pessoas.\n'
              'Exemplo: Em vez de mostrar uma pessoa específica, o sistema poderá mostrar informações como: "120 pessoas cadastradas", "35 carteirinhas solicitadas".\n'
              'O objetivo desse uso é entender melhor o público atendido, melhorar processos, organizar demandas e apoiar decisões da instituição responsável.'
            ),

            _buildSectionTitle('10. Base legal para tratamento dos dados'),
            _buildParagraph(
              'O tratamento de dados pessoais no ConeCTEA poderá ocorrer com base nas hipóteses permitidas pela legislação aplicável, conforme a finalidade de uso.\n'
              'Entre as bases que podem ser utilizadas, estão: consentimento do titular ou responsável legal; execução de procedimentos relacionados à solicitação da carteirinha; cumprimento de obrigação legal ou regulatória; legítimo interesse da instituição; necessidade de atendimento e suporte.\n'
              'Nem todo uso de dados depende exclusivamente de consentimento. Alguns tratamentos podem ser necessários para funcionamento da conta, análise de solicitação ou segurança do sistema.'
            ),

            _buildSectionTitle('11. Quem pode acessar os dados'),
            _buildParagraph(
              'Os dados cadastrados no ConeCTEA poderão ser acessados apenas por pessoas autorizadas e conforme a necessidade de uso: equipe administrativa autorizada; responsáveis pela análise; suporte; equipe técnica autorizada.\n'
              'O acesso administrativo deve ser restrito e utilizado apenas para finalidades compatíveis com o funcionamento do ConeCTEA.'
            ),

            _buildSectionTitle('12. Compartilhamento de dados'),
            _buildParagraph(
              'O ConeCTEA não deve vender dados pessoais dos usuários. Os dados poderão ser compartilhados apenas quando necessário para funcionamento técnico, autenticação, armazenamento seguro, envio de notificações ou cumprimento de obrigações legais.'
            ),

            _buildSectionTitle('13. Serviços de terceiros'),
            _buildParagraph(
              'O ConeCTEA poderá utilizar serviços de terceiros para viabilizar funcionalidades do aplicativo (banco de dados, autenticação, hospedagem, notificações, etc.). O uso desses serviços não significa venda dos dados dos usuários.'
            ),

            _buildSectionTitle('14. Transferência e armazenamento fora do Brasil'),
            _buildParagraph(
              'Alguns serviços tecnológicos utilizados pelo ConeCTEA podem operar com infraestrutura localizada no Brasil ou em outros países. A instituição buscará utilizar fornecedores que adotem medidas adequadas de segurança.'
            ),

            _buildSectionTitle('15. Segurança das informações'),
            _buildParagraph(
              'O ConeCTEA deverá adotar medidas técnicas e administrativas para proteger os dados contra acesso não autorizado, perda, alteração ou uso indevido. Apesar dos esforços, nenhum sistema é totalmente livre de riscos, por isso o usuário também deve proteger seus dados de acesso.'
            ),

            _buildSectionTitle('16. Retenção dos dados'),
            _buildParagraph(
              'Os dados pessoais poderão ser mantidos enquanto forem necessários para funcionamento da conta, validade da carteirinha, suporte ou cumprimento de obrigações legais. Quando não mais necessários, poderão ser excluídos ou anonimizados.'
            ),

            _buildSectionTitle('17. Direitos do usuário sobre seus dados'),
            _buildParagraph(
              'O usuário poderá solicitar informações e exercer direitos (confirmação, acesso, correção, atualização, exclusão, etc.) pelos canais oficiais da instituição responsável.'
            ),

            _buildSectionTitle('18. Correção e atualização de dados'),
            _buildParagraph(
              'O usuário é responsável por manter seus dados corretos. Alterações podem ser solicitadas pelo app ou canais oficiais, podendo exigir análise administrativa quando vinculadas à segurança da conta.'
            ),

            _buildSectionTitle('19. Consentimentos'),
            _buildParagraph(
              'O uso do aplicativo implica na ciência dos Termos de Uso e desta Política de Privacidade. Consentimentos obrigatórios são necessários para funcionamento da conta, enquanto opcionais podem ser gerenciados pelo usuário.'
            ),

            _buildSectionTitle('20. Notificações'),
            _buildParagraph(
              'O ConeCTEA poderá enviar notificações sobre o status da solicitação, carteirinha, segurança e avisos institucionais. O usuário pode gerenciar permissões no próprio dispositivo.'
            ),

            _buildSectionTitle('21. Carteirinha digital e validação'),
            _buildParagraph(
              'A carteirinha digital contém apenas informações necessárias para identificação e validação via QR Code, evitando exposição excessiva de dados durante o processo.'
            ),

            _buildSectionTitle('22. Área administrativa'),
            _buildParagraph(
              'A área administrativa é restrita e utilizada para análise de solicitações, gestão de usuários e geração de estatísticas. O uso indevido pode gerar bloqueio de acesso.'
            ),

            _buildSectionTitle('23. Canais externos'),
            _buildParagraph(
              'O app pode orientar o uso de canais externos (Instagram, WhatsApp) para suporte. Nesses casos, aplicam-se também as políticas dessas plataformas.'
            ),

            _buildSectionTitle('24. Solicitação de exclusão de conta'),
            _buildParagraph(
              'O usuário pode solicitar a exclusão de sua conta, o que removerá o acesso à carteirinha e histórico. Alguns dados podem ser mantidos por obrigações legais ou segurança.'
            ),

            _buildSectionTitle('25. Alterações nesta Política'),
            _buildParagraph(
              'Esta Política pode ser atualizada a qualquer momento. O uso contínuo após a atualização indica ciência da nova versão.'
            ),

            _buildSectionTitle('26. Contato sobre privacidade'),
            _buildParagraph(
              'Família TEA Bauru\n'
              'Contato oficial: Instagram — @familiateabauru\n'
              'Link oficial: https://www.instagram.com/familiateabauru\n'
              'Cidade/Estado: Bauru — SP'
            ),

            const SizedBox(height: 48),
            _buildAcceptButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '🛡️ POLÍTICA DE PRIVACIDADE',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.darkBlue,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'ConeCTEA — Versão 1.0',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Instituição: Família TEA Bauru',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.darkBlue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSubSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.darkBlue.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary.withValues(alpha: 0.9),
        height: 1.6,
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          'ESTOU CIENTE',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
