import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C1C),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          'Termos de Uso',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PremiumHero(
              icon: PhosphorIconsRegular.fileText,
              title: 'Termos de Uso',
              subtitle: 'Conheça as regras de utilização do ConeCTEA, aplicativo comunitário da Família TEA Bauru.',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvisoBlock(),
                  _buildSectionBlock(
                    '1. Identificação do ConeCTEA e da comunidade responsável',
                    'O ConeCTEA é um aplicativo social, comunitário, organizacional e informativo vinculado à Família TEA Bauru, comunidade e rede de apoio formada por familiares, mães, responsáveis, voluntários, profissionais, parceiros e pessoas comprometidas com inclusão real, respeito e acolhimento.\n\nA Família TEA Bauru atua como uma rede comunitária de apoio voltada, principalmente, a famílias relacionadas ao Transtorno do Espectro Autista (TEA), pessoas neurodivergentes, familiares, responsáveis, participantes cadastrados, voluntários, parceiros e equipe de organização.\n\nCanais oficiais:\nE-mail principal: familiateabauru@gmail.com\nWhatsApp oficial: +55 14 99101-2961 — Renata Ferreguti\nInstagram: https://www.instagram.com/familiateabauru/\nE-mail secundário: conecteabauru@gmail.com\nSite oficial: em breve\n\nA Família TEA Bauru não deve ser interpretada como empresa, órgão público, entidade governamental, serviço público, clínica, consultório, operadora de saúde ou entidade médica equivalente.\n\nA utilização do ConeCTEA não gera, por si só, direito automático a benefício público, atendimento prioritário, reconhecimento oficial, validação médica, vaga em programa comunitário, consulta com profissional parceiro ou aceitação obrigatória por terceiros.',
                    '1',
                  ),
                  _buildSectionBlock(
                    '2. Aceitação dos Termos de Uso',
                    'Ao criar uma conta, acessar, navegar ou utilizar qualquer funcionalidade do ConeCTEA, o usuário declara que leu, compreendeu e concorda com estes Termos de Uso, bem como com a Política de Privacidade aplicável ao aplicativo.\n\nA aceitação destes Termos é condição necessária para o uso do ConeCTEA. Caso o usuário não concorde com qualquer disposição aqui prevista, deverá interromper o uso do aplicativo e, se necessário, entrar em contato pelos canais oficiais da Família TEA Bauru para esclarecimentos.\n\nQuando o usuário utilizar o ConeCTEA em nome de outra pessoa, dependente, criança, adolescente, familiar ou pessoa sob seus cuidados, declara possuir autorização, legitimidade ou vínculo adequado para fornecer informações e realizar solicitações dentro do aplicativo, responsabilizando-se pela veracidade dos dados informados.\n\nA continuidade de uso do ConeCTEA após a disponibilização destes Termos ou de suas futuras atualizações poderá ser interpretada como ciência e concordância com as condições aplicáveis, sem prejuízo do direito do usuário de deixar de utilizar o aplicativo ou solicitar esclarecimentos pelos canais oficiais.',
                    '2',
                  ),
                  _buildSectionBlock(
                    '3. Finalidade do aplicativo',
                    'O ConeCTEA tem como finalidade apoiar a organização, comunicação e gestão comunitária das ações desenvolvidas pela Família TEA Bauru, funcionando como uma ferramenta digital de apoio à comunidade, aos participantes cadastrados, familiares, responsáveis, voluntários, parceiros e equipe de organização.\n\nO aplicativo poderá ser utilizado para funcionalidades como cadastro de usuários, acesso à conta, solicitação e acompanhamento da carteirinha digital comunitária ConeCTEA, comunicação de avisos, notificações, suporte, consulta de informações, participação em programas comunitários, acompanhamento de solicitações e outras funcionalidades relacionadas às ações da Família TEA Bauru.\n\nO ConeCTEA também poderá apoiar programas comunitários, chamamentos, listas de interesse, inscrições, comunicação de selecionados e, quando aplicável, o primeiro encaminhamento ou agendamento com profissionais, clínicas ou parceiros participantes de ações organizadas pela Família TEA Bauru. Nessas situações, o aplicativo atua como ferramenta de organização, comunicação e encaminhamento comunitário inicial, não como prestador direto de serviço médico, odontológico, terapêutico, clínico ou assistencial.\n\nO ConeCTEA não tem a finalidade de substituir atendimentos presenciais, canais oficiais da comunidade, avaliação profissional, documentos oficiais, serviços públicos, cadastros governamentais, políticas públicas, laudos, diagnósticos ou qualquer procedimento realizado por autoridade pública, profissional habilitado ou serviço especializado.',
                    '3',
                  ),
                  _buildSectionBlock(
                    '4. Natureza comunitária da carteirinha digital ConeCTEA',
                    'A carteirinha digital comunitária ConeCTEA é uma funcionalidade interna do aplicativo, criada para apoiar a identificação, organização e participação de pessoas cadastradas nas ações comunitárias da Família TEA Bauru.\n\nA carteirinha possui finalidade comunitária, organizacional, informativa e interna, sendo vinculada às regras, critérios, validações e procedimentos definidos pela Família TEA Bauru para suas próprias ações, programas, comunicações e iniciativas.\n\nA carteirinha digital comunitária ConeCTEA não é documento oficial, não possui natureza de documento civil, não é emitida por órgão público, não representa documento governamental e não substitui documentos oficiais ou serviços públicos.\n\nA carteirinha digital comunitária ConeCTEA não substitui, em nenhuma hipótese, CIPTEA, RG, CPF, CNH, certidão, laudo médico, relatório profissional, diagnóstico, documento escolar, documento assistencial, documento de saúde, documento civil ou qualquer documento emitido pelo Poder Público.\n\nA emissão, visualização ou aprovação da carteirinha dentro do ConeCTEA não gera, por si só, direito automático a atendimento prioritário, benefício público, vaga em programa, consulta com profissional parceiro, gratuidade, desconto, reconhecimento oficial, validação médica, atendimento público ou aceitação obrigatória por terceiros.\n\nQualquer uso da carteirinha fora de sua finalidade comunitária, incluindo tentativa de utilização como documento oficial, comprovante médico, prova de diagnóstico, documento governamental, identidade civil ou meio de obtenção indevida de vantagem, poderá ser considerado uso inadequado do aplicativo e sujeito às medidas previstas nestes Termos.',
                    '4',
                  ),
                  _buildSectionBlock(
                    '5. Ausência de caráter médico, odontológico, terapêutico ou clínico',
                    'O ConeCTEA não é aplicativo médico, odontológico, terapêutico, psicológico, clínico, hospitalar, assistencial de saúde ou equivalente.\n\nO aplicativo não realiza diagnóstico, não emite laudo, não confirma condição clínica, não valida deficiência, não prescreve tratamento, não indica conduta profissional, não substitui consulta, avaliação, acompanhamento ou atendimento realizado por profissional habilitado.\n\nAs informações disponibilizadas no ConeCTEA possuem finalidade comunitária, organizacional, informativa e administrativa, não devendo ser interpretadas como orientação médica, odontológica, psicológica, terapêutica, clínica ou profissional.\n\nA Família TEA Bauru poderá organizar, apoiar ou divulgar programas comunitários, ações, chamamentos, listas de interesse, inscrições, comunicação de selecionados e, quando aplicável, o primeiro encaminhamento ou agendamento com profissionais, clínicas ou parceiros participantes. Nesses casos, o ConeCTEA atua apenas como ferramenta de apoio à organização comunitária, comunicação com participantes e encaminhamento inicial, não sendo responsável pela prestação direta do atendimento médico, odontológico, terapêutico, psicológico ou clínico.\n\nO atendimento eventualmente realizado por médico, dentista, psicólogo, terapeuta, clínica, consultório ou qualquer outro profissional parceiro será de responsabilidade técnica, ética e profissional do próprio prestador do serviço.\n\nA participação em programa comunitário, chamamento, lista de interesse ou ação apoiada pela Família TEA Bauru não garante continuidade de tratamento, novas consultas, acompanhamento permanente, atendimento ilimitado, cobertura de custos futuros ou vínculo obrigatório entre o participante e o profissional parceiro.',
                    '5',
                  ),
                  _buildSectionBlock(
                    '6. Cadastro, conta e responsabilidade do usuário',
                    'Para utilizar determinadas funcionalidades do ConeCTEA, o usuário poderá precisar criar uma conta, informar dados pessoais, cadastrar informações necessárias e manter acesso por meio de credenciais de acesso, senha ou outro método de autenticação disponibilizado pelo aplicativo.\n\nO usuário declara que todas as informações fornecidas no ConeCTEA devem ser verdadeiras, completas, atualizadas e compatíveis com a finalidade comunitária, organizacional e administrativa do aplicativo.\n\nO usuário é responsável pela veracidade dos dados informados, incluindo dados próprios e, quando aplicável, dados de dependentes, familiares, crianças, adolescentes ou pessoas sob seus cuidados, representação, responsabilidade ou vínculo comunitário.\n\nO cadastro de informações falsas, incompletas, desatualizadas, incorretas, fraudulentas ou pertencentes a terceiros sem autorização poderá impedir a análise de solicitações, gerar recusa de cadastro, suspensão de funcionalidades, bloqueio de conta, cancelamento de solicitação ou outras medidas necessárias para proteção da comunidade.\n\nO usuário também é responsável por manter a segurança de seus dados de acesso, não devendo compartilhar senha, código, acesso à conta ou qualquer meio de autenticação com terceiros não autorizados.\n\nA criação de conta no ConeCTEA não garante aprovação automática de carteirinha digital comunitária, participação em programas comunitários, vaga em chamamentos, acesso a consultas, benefícios, atendimentos, serviços, descontos, prioridades ou qualquer outro resultado dependente de análise, disponibilidade ou critérios definidos pela Família TEA Bauru.',
                    '6',
                  ),
                  _buildSectionBlock(
                    '7. Dependentes, responsáveis e pessoas vinculadas à conta',
                    'O ConeCTEA poderá permitir o cadastro ou vinculação de informações relacionadas a dependentes, crianças, adolescentes, familiares, pessoas sob cuidado, representação ou acompanhamento do usuário, conforme as funcionalidades disponibilizadas no aplicativo.\n\nAo cadastrar, informar ou vincular dados de outra pessoa no ConeCTEA, o usuário declara possuir autorização, legitimidade, vínculo familiar, vínculo de cuidado, representação, tutela, curatela, responsabilidade legal ou outra condição adequada para fornecer tais informações e realizar solicitações em nome da pessoa vinculada.\n\nQuando a pessoa cadastrada, dependente ou vinculada à conta for criança ou adolescente, o usuário declara ser pai, mãe, responsável legal ou possuir autorização legítima para realizar o cadastro, fornecer dados, enviar documentos, solicitar carteirinha comunitária, acompanhar solicitações e autorizar o tratamento das informações no ConeCTEA.\n\nO tratamento de dados pessoais de crianças e adolescentes deverá observar o melhor interesse da criança ou adolescente, nos termos do art. 14 da Lei Geral de Proteção de Dados Pessoais — LGPD. Quando aplicável, o tratamento de dados de criança deverá ocorrer mediante consentimento específico e em destaque de pelo menos um dos pais ou responsável legal.\n\nO usuário reconhece que dados de dependentes, crianças, adolescentes e pessoas vinculadas podem envolver informações pessoais ou sensíveis e devem ser tratados com cuidado, respeito e responsabilidade.',
                    '7',
                  ),
                  _buildSectionBlock(
                    '8. Solicitação, análise, aprovação, recusa e suspensão',
                    'O ConeCTEA poderá permitir que usuários realizem solicitações relacionadas à carteirinha digital comunitária, programas comunitários, ações da Família TEA Bauru, chamamentos, listas de interesse ou outras funcionalidades disponibilizadas no aplicativo.\n\nToda solicitação realizada no ConeCTEA poderá passar por análise comunitária, administrativa ou organizacional da Família TEA Bauru, conforme a natureza da solicitação, os dados informados, os documentos apresentados quando aplicável, os critérios internos e a disponibilidade da equipe responsável.\n\nO envio de uma solicitação não garante aprovação automática, emissão de carteirinha, participação em programa, atendimento, vaga, consulta, encaminhamento, gratuidade, desconto ou qualquer outro resultado.\n\nA Família TEA Bauru poderá aprovar, recusar, suspender, devolver para correção, solicitar documentação complementar, solicitar revisão de dados ou encerrar uma solicitação quando houver necessidade de conferência, inconsistência, ausência de informação, indício de uso indevido, falta de disponibilidade, descumprimento de regras do programa ou violação destes Termos.\n\nO usuário reconhece que a aprovação de uma solicitação no ConeCTEA possui efeito limitado à finalidade comunitária, organizacional e interna da Família TEA Bauru, não gerando reconhecimento oficial, documento público, validação médica, direito adquirido, benefício público ou obrigação de aceitação por terceiros.',
                    '8',
                  ),
                  _buildSectionBlock(
                    '9. Documentos, laudos e informações complementares',
                    'O ConeCTEA poderá solicitar ou permitir o envio de documentos, comprovantes, laudos, informações complementares ou dados adicionais quando forem necessários para análise de solicitações, carteirinha digital comunitária, programas comunitários, chamamentos ou ações específicas da Família TEA Bauru.\n\nDocumentos, laudos e informações complementares, quando solicitados, serão utilizados apenas para as finalidades relacionadas à análise comunitária, administrativa, organizacional, conferência documental, prevenção de uso indevido ou encaminhamento inicial vinculado à funcionalidade ou programa correspondente.\n\nO envio de laudo, documento ou informação relacionada à condição da pessoa não transforma o ConeCTEA em aplicativo médico, serviço de saúde, clínica, consultório, entidade profissional, órgão público ou sistema oficial de validação de diagnóstico.\n\nA Família TEA Bauru não realiza diagnóstico, não valida condição clínica por conta própria, não emite laudo, não substitui avaliação profissional e não utiliza o aplicativo para definir conduta médica, odontológica, terapêutica, psicológica ou clínica.\n\nO usuário declara que os documentos, laudos ou informações enviados devem ser verdadeiros, legíveis, pertinentes, atualizados quando necessário e fornecidos com autorização adequada, especialmente quando envolverem crianças, adolescentes, dependentes ou terceiros.\n\nO envio de documentos falsos, adulterados, ilegíveis, incompatíveis, desatualizados, pertencentes a terceiros sem autorização ou utilizados para finalidade indevida poderá resultar em recusa, suspensão, bloqueio, cancelamento de solicitação ou outras medidas necessárias para proteção da comunidade.\n\nOs prazos de análise, correção de pendências, suspensão, reprovação, retenção temporária e descarte de documentos sensíveis seguirão as regras descritas na Política de Privacidade do ConeCTEA.',
                    '9',
                  ),
                  _buildSectionBlock(
                    '10. Programas comunitários, parceiros e primeiro agendamento',
                    'A Família TEA Bauru poderá organizar, apoiar, divulgar ou intermediar programas comunitários, ações sociais, chamamentos, listas de interesse, inscrições, comunicação de selecionados e encaminhamentos iniciais por meio do ConeCTEA.\n\nEsses programas poderão incluir, entre outros, iniciativas como Fada do Dente, Vidas ou outras ações futuras voltadas ao apoio comunitário de famílias, pessoas autistas, pessoas neurodivergentes, dependentes e participantes cadastrados.\n\nA inscrição em um programa pelo ConeCTEA não garante seleção, vaga, consulta, atendimento, custeio, continuidade de tratamento, retorno, acompanhamento permanente ou participação em futuras edições.\n\nQuando um programa envolver profissional parceiro, clínica, consultório, dentista, médico, terapeuta, psicólogo ou outro prestador habilitado, o ConeCTEA poderá atuar como ferramenta de organização, comunicação e primeiro encaminhamento, inclusive para auxiliar no agendamento inicial, quando essa funcionalidade estiver disponível.\n\nO atendimento realizado por profissional, clínica, consultório ou parceiro será de responsabilidade técnica, ética, legal e profissional do próprio prestador do serviço.\n\nApós a primeira consulta, encaminhamento inicial ou ação comunitária prevista no programa, eventual continuidade de atendimento, retorno, tratamento, acompanhamento, pagamento, responsabilidade profissional ou nova consulta deverá ser tratada diretamente entre o participante, seus responsáveis quando aplicável, e o profissional, clínica ou parceiro responsável.',
                    '10',
                  ),
                  _buildSectionBlock(
                    '11. Uso permitido do aplicativo',
                    'O usuário poderá utilizar o ConeCTEA para finalidades lícitas, legítimas e compatíveis com a natureza social, comunitária, organizacional e informativa do aplicativo.\n\nO uso permitido inclui, conforme as funcionalidades disponíveis: criar conta, acessar informações próprias, cadastrar dados necessários, solicitar carteirinha digital comunitária, acompanhar status de solicitações, receber comunicações, consultar avisos, participar de programas comunitários, entrar em listas de interesse, solicitar suporte e utilizar recursos disponibilizados pela Família TEA Bauru.\n\nO usuário se compromete a utilizar o ConeCTEA com boa-fé, respeito, responsabilidade, veracidade das informações, cuidado com dados pessoais e observância destes Termos de Uso e da Política de Privacidade.\n\nO aplicativo deve ser utilizado apenas dentro de sua finalidade comunitária e organizacional, sem tentativa de obter vantagem indevida, acessar informações de terceiros, burlar regras, fraudar solicitações ou utilizar a carteirinha digital comunitária como documento oficial.',
                    '11',
                  ),
                  _buildSectionBlock(
                    '12. Uso proibido do aplicativo',
                    'É proibido utilizar o ConeCTEA para qualquer finalidade ilegal, fraudulenta, abusiva, ofensiva, discriminatória, invasiva, contrária à boa-fé ou incompatível com estes Termos de Uso.\n\nÉ proibido fornecer dados falsos, adulterados, incompletos de forma intencional, enganosos ou pertencentes a terceiros sem autorização.\n\nÉ proibido utilizar documentos falsos, laudos adulterados, informações manipuladas, imagens indevidas ou qualquer material com o objetivo de obter aprovação, participação em programa, carteirinha comunitária, vaga, encaminhamento, consulta ou benefício indevido.\n\nÉ proibido acessar, tentar acessar, utilizar ou compartilhar conta de terceiro sem autorização.\n\nÉ proibido tentar invadir, testar vulnerabilidades, manipular, copiar, alterar, fraudar, interromper ou prejudicar o funcionamento do ConeCTEA, seus dados, sistemas, servidores, integrações, notificações, código QR (QR Code), carteirinhas ou funcionalidades.\n\nÉ proibido copiar, adulterar, reproduzir, vender, transferir, emprestar ou utilizar indevidamente a carteirinha digital comunitária, código QR (QR Code), prints, dados de usuários, informações de dependentes, documentos, laudos, listas de programas ou comunicações internas.\n\nÉ proibido utilizar a carteirinha digital comunitária ConeCTEA como documento oficial, prova médica, laudo, diagnóstico, identidade civil, documento governamental ou meio de obtenção indevida de vantagem perante terceiros.\n\nÉ proibido expor, divulgar, publicar, compartilhar ou utilizar dados pessoais, dados de dependentes, dados de crianças ou adolescentes, documentos, laudos, informações sensíveis ou comunicações internas obtidas por meio do ConeCTEA sem autorização adequada.\n\nÉ proibido utilizar o aplicativo para praticar assédio, discriminação, ameaça, ofensa, golpe, fraude, exploração, constrangimento ou qualquer conduta prejudicial a usuários, famílias, profissionais, parceiros, voluntários ou membros da Família TEA Bauru.\n\nA violação deste item poderá resultar em recusa de solicitação, suspensão de funcionalidades, bloqueio de conta, cancelamento de carteirinha comunitária, exclusão de participação em programas ou outras medidas necessárias para proteção da comunidade.',
                    '12',
                  ),
                  _buildSectionBlock(
                    '13. Código QR, validação e exibição da carteirinha',
                    'A carteirinha digital comunitária ConeCTEA poderá conter recurso visual, código QR (QR Code), TEA ID ou outro mecanismo técnico de apoio à consulta, identificação comunitária ou validação interna, conforme as funcionalidades disponíveis no aplicativo.\n\nO código QR, quando existente, possui finalidade limitada à organização comunitária, consulta interna, validação informativa e confirmação de dados permitidos dentro do contexto da Família TEA Bauru.\n\nAtualmente, a validação do código QR da carteirinha ocorre apenas dentro do próprio aplicativo ConeCTEA, por meio de funcionalidade interna de leitura disponível a usuários autorizados conforme as regras do app.\n\nAo escanear o código QR dentro do ConeCTEA, o aplicativo poderá exibir informações básicas de validação da carteirinha comunitária, como nome do beneficiário, TEA ID, situação da carteirinha e data de validade, conforme os dados disponíveis no sistema.\n\nO código QR não deve conter documento com foto, laudo médico, CPF completo, CID, tipo sanguíneo, contato de emergência, anexos sensíveis ou informações além do necessário para validação comunitária.\n\nO código QR e o TEA ID não transformam a carteirinha digital comunitária em documento oficial, identidade civil, CIPTEA, RG, CPF, CNH, laudo, diagnóstico, documento médico, documento público ou documento emitido por autoridade governamental.\n\nA leitura ou apresentação do código QR não garante aceitação obrigatória por terceiros, estabelecimentos, eventos, parceiros, profissionais, serviços públicos ou privados.\n\nFuncionalidades futuras relacionadas ao código QR, como validação sem conexão com a internet, registro de presença em eventos, confirmação de participação em programas comunitários, uso com parceiros, descontos ou emblemas de perfil, somente deverão ser consideradas parte destes Termos quando forem efetivamente implementadas, disponibilizadas aos usuários e refletidas em atualização específica dos Termos de Uso e da Política de Privacidade.',
                    '13',
                  ),
                  _buildSectionBlock(
                    '14. Notificações e comunicações',
                    'O ConeCTEA poderá enviar notificações, avisos, mensagens internas, alertas, comunicados ou atualizações relacionadas à conta, solicitações, carteirinha digital comunitária, programas, chamamentos, suporte, segurança, privacidade, atualizações do aplicativo e ações da Família TEA Bauru.\n\nAs notificações têm finalidade informativa, organizacional e comunitária, podendo auxiliar o usuário a acompanhar solicitações, pendências, aprovações, recusas, agendamentos iniciais, orientações e comunicações importantes.\n\nPor segurança e privacidade, detalhes sensíveis, documentos, laudos, diagnósticos, CPF, informações íntimas, dados completos de dependentes, justificativas detalhadas ou conteúdos administrativos sensíveis devem ser consultados preferencialmente dentro do ambiente autenticado do aplicativo, quando disponível.\n\nO ConeCTEA poderá enviar notificações genéricas informando que há atualização, pendência, mensagem ou informação disponível, sem expor conteúdo sensível desnecessariamente.\n\nO usuário poderá gerenciar permissões de notificação nas configurações do dispositivo ou do aplicativo, conforme as funcionalidades disponíveis.\n\nA ausência de recebimento de notificação, por falha de internet, configuração do aparelho, bloqueio do sistema, erro técnico, indisponibilidade temporária ou qualquer outro motivo, não elimina a responsabilidade do usuário de acompanhar suas solicitações e informações dentro do aplicativo ou pelos canais oficiais, quando necessário.',
                    '14',
                  ),
                  _buildSectionBlock(
                    '15. Suporte e canais oficiais',
                    'A Família TEA Bauru disponibiliza canais oficiais para contato, suporte, dúvidas, solicitações, comunicação comunitária e assuntos relacionados ao ConeCTEA.\n\nOs canais oficiais indicados nestes Termos são:\nE-mail principal: familiateabauru@gmail.com\nWhatsApp oficial: +55 14 99101-2961 — Renata Ferreguti\nGrupo comunitário: https://chat.whatsapp.com/Hhl4SmcahMZ3DX8GEkpQ6s?mode=ac_t\nInstagram: https://www.instagram.com/familiateabauru/\nE-mail secundário: conecteabauru@gmail.com\nSite oficial: em breve\n\nO grupo comunitário de WhatsApp e o Instagram poderão ser utilizados para comunicação geral, divulgação de ações, aproximação com a comunidade, orientações públicas e avisos comunitários.\n\nPara assuntos sensíveis, suporte relacionado à conta, dados pessoais, privacidade, correção de informações, exclusão de conta, solicitações administrativas, documentos, dependentes, programas comunitários ou dúvidas específicas sobre o aplicativo, recomenda-se utilizar os canais principais de contato.\n\nSolicitações enviadas por canais não oficiais, perfis não reconhecidos, mensagens privadas de terceiros ou contatos não indicados nestes Termos poderão não ser consideradas válidas para fins de suporte, correção, exclusão, privacidade ou manifestação formal.',
                    '15',
                  ),
                  _buildSectionBlock(
                    '16. Correção e atualização de dados',
                    'O usuário poderá realizar ou solicitar a correção e atualização de dados diretamente pelo ConeCTEA, conforme as funcionalidades disponíveis no aplicativo, o tipo de dado envolvido e as regras de segurança aplicáveis.\n\nO aplicativo poderá permitir a atualização de dados de conta, perfil, contato, informações cadastrais e dados de dependentes, sempre que essa alteração estiver disponível no fluxo correspondente e não representar risco à segurança da conta, à integridade da carteirinha digital comunitária, à análise de solicitações ou à proteção de dados de terceiros.\n\nAlguns dados protegidos ou sensíveis, como CPF, e-mail de acesso, documentos, laudos, CID, dados vinculados à carteirinha comunitária, informações de solicitação, status, responsáveis e dados que impactem análise administrativa, poderão exigir fluxo específico dentro do aplicativo, conferência, justificativa, nova análise ou validação pela equipe autorizada da Família TEA Bauru.\n\nO usuário é responsável por manter seus dados atualizados e por informar erros, inconsistências ou mudanças relevantes que possam impactar sua conta, suas solicitações, sua carteirinha comunitária, seus dependentes ou sua participação em programas.\n\nA solicitação de correção ou atualização não garante alteração automática em todos os casos. A correção poderá ser aplicada diretamente, aprovada, recusada, devolvida para complementação ou encaminhada para nova análise, conforme a natureza do dado, a segurança do fluxo e a coerência das informações apresentadas.\n\nEm caso de dúvida sobre correção ou atualização de dados, o usuário poderá entrar em contato pelos canais oficiais da Família TEA Bauru indicados nestes Termos.',
                    '16',
                  ),
                  _buildSectionBlock(
                    '17. Exclusão de conta, remoção de dependentes e encerramento de uso',
                    'O ConeCTEA disponibiliza funcionalidade para que o usuário realize a exclusão de sua conta diretamente pelo aplicativo, conforme o fluxo técnico disponível.\n\nPor se tratar de uma ação sensível e potencialmente irreversível, a exclusão de conta exige confirmação expressa do usuário, podendo incluir leitura de aviso, preenchimento de frase de confirmação, ativação de botão específico ou outra etapa de segurança definida pelo aplicativo.\n\nAo confirmar a exclusão da conta, o usuário reconhece que seu acesso ao ConeCTEA será encerrado, sua sessão será deslogada e os dados vinculados à sua conta serão removidos do banco de dados operacional do aplicativo, conforme o fluxo técnico de exclusão disponível.\n\nA exclusão da conta remove dados cadastrais, dados de perfil, solicitações, carteirinhas comunitárias vinculadas, dependentes associados, registros internos vinculados à conta e demais informações mantidas no banco de dados operacional do ConeCTEA, observados os limites técnicos, legais e operacionais aplicáveis.\n\nA exclusão de conta ou remoção de dependente não desfaz automaticamente comunicações já realizadas, mensagens enviadas por e-mail, WhatsApp ou outros canais externos, registros necessários para cumprimento de obrigação legal, segurança, prevenção de fraude, defesa de direitos, auditoria mínima, suporte já prestado ou informações eventualmente encaminhadas a profissionais, clínicas, parceiros ou canais externos antes da exclusão, quando aplicável.\n\nApós a exclusão da conta, caso o usuário deseje voltar a utilizar o ConeCTEA, será necessário realizar novo cadastro, aceitar os Termos de Uso e a Política de Privacidade vigentes, preencher novamente as informações necessárias e realizar novas solicitações, sem garantia de recuperação de dados excluídos anteriormente.',
                    '17',
                  ),
                  _buildSectionBlock(
                    '18. Suspensão, bloqueio ou encerramento de acesso',
                    'A Família TEA Bauru poderá suspender, bloquear, limitar ou encerrar o acesso de usuário, conta, solicitação, carteirinha digital comunitária ou participação em programa quando houver descumprimento destes Termos de Uso, violação da Política de Privacidade, uso indevido, suspeita de fraude, inconsistência grave, risco à segurança, proteção de dados, conflito de informações ou necessidade de proteção da comunidade.\n\nA suspensão ou bloqueio poderá ocorrer, entre outras hipóteses, quando houver fornecimento de dados falsos, uso de documentos adulterados, tentativa de acessar dados de terceiros, uso indevido de código QR (QR Code), compartilhamento indevido de carteirinha, fraude em programas comunitários, conduta abusiva, violação de direitos de terceiros ou tentativa de prejudicar o funcionamento do aplicativo.\n\nA Família TEA Bauru poderá, quando adequado e possível, informar ao usuário o motivo geral da suspensão, bloqueio ou limitação, preservando informações sensíveis, segurança do sistema, privacidade de terceiros e procedimentos internos.\n\nA suspensão, bloqueio ou encerramento de acesso não gera direito automático a indenização, vaga, consulta, atendimento, manutenção de benefício comunitário, aprovação de solicitação ou reativação de conta.\n\nO usuário poderá buscar esclarecimentos pelos canais oficiais, especialmente quando entender que houve erro, informação desatualizada, inconsistência cadastral ou necessidade de revisão.',
                    '18',
                  ),
                  _buildSectionBlock(
                    '19. Limitações de responsabilidade',
                    'O ConeCTEA é disponibilizado como ferramenta digital de apoio comunitário, organizacional, informativo e administrativo da Família TEA Bauru.\n\nA Família TEA Bauru não se responsabiliza por uso indevido do aplicativo, fornecimento de dados falsos pelo usuário, compartilhamento de senha, acesso não autorizado causado por descuido do usuário, divulgação indevida de carteirinha, código QR (QR Code), prints, documentos ou informações pessoais realizada pelo próprio usuário ou por terceiros sem autorização.\n\nA Família TEA Bauru não garante aceitação obrigatória da carteirinha digital comunitária por órgãos públicos, estabelecimentos privados, eventos, profissionais, serviços, parceiros, instituições, escolas, clínicas, consultórios ou terceiros.\n\nA utilização da carteirinha digital comunitária fora de sua finalidade interna, comunitária e organizacional será de responsabilidade do usuário que a utilizar indevidamente.\n\nA Família TEA Bauru não se responsabiliza por decisões clínicas, diagnósticos, tratamentos, prescrições, retornos, condutas profissionais, continuidade de atendimento ou resultados de consultas realizadas por médicos, dentistas, terapeutas, psicólogos, clínicas, consultórios ou parceiros externos.\n\nA Família TEA Bauru não garante funcionamento contínuo, ininterrupto, livre de falhas, livre de indisponibilidades, livre de erros ou compatível com todos os dispositivos, versões de sistema, redes de internet ou condições técnicas do usuário.\n\nNenhuma disposição destes Termos limita direitos que não possam ser limitados pela legislação aplicável.',
                    '19',
                  ),
                  _buildSectionBlock(
                    '20. Disponibilidade, manutenção e atualizações',
                    'O ConeCTEA poderá passar por atualizações, melhorias, correções, manutenção, alterações de funcionalidades, ajustes de segurança, mudanças visuais, reorganização de fluxos ou indisponibilidades temporárias.\n\nA Família TEA Bauru poderá alterar, suspender, remover, substituir ou atualizar funcionalidades do aplicativo sempre que entender necessário para melhorar a experiência, corrigir problemas, preservar a segurança, adequar o aplicativo à legislação, atender exigências de plataformas, proteger dados ou reorganizar ações comunitárias.\n\nO aplicativo poderá ficar temporariamente indisponível por motivo de manutenção, instabilidade técnica, falha de internet, falha de serviços terceiros, atualização de servidores, ajustes de segurança, limitação de dispositivos, erro operacional ou outras causas internas ou externas.\n\nA Família TEA Bauru poderá comunicar manutenções, indisponibilidades relevantes ou mudanças importantes por meio do próprio aplicativo, notificações, e-mail, WhatsApp, Instagram, grupo comunitário ou outros canais oficiais, quando possível.\n\nO usuário reconhece que funcionalidades ainda poderão evoluir, ser reorganizadas ou receber ajustes conforme a necessidade da Família TEA Bauru, a experiência dos usuários, critérios de segurança, conformidade legal e capacidade operacional.',
                    '20',
                  ),
                  _buildSectionBlock(
                    '21. Propriedade intelectual, marca e conteúdo',
                    'O nome ConeCTEA, sua identidade visual, telas, textos, organização visual, elementos gráficos, componentes, marca, logotipos, materiais, fluxos, conteúdos comunitários, conteúdos informativos, comunicações oficiais e demais elementos do aplicativo pertencem ou são utilizados pela Família TEA Bauru e por seus responsáveis, criadores, parceiros ou colaboradores autorizados, conforme o caso.\n\nO usuário não recebe qualquer direito de propriedade, licença comercial, autorização de exploração, cópia, revenda, reprodução, distribuição, modificação, engenharia reversa ou uso indevido da marca, identidade visual, conteúdo, sistema ou elementos do ConeCTEA.\n\nÉ proibido copiar, reproduzir, divulgar, vender, adaptar, modificar, distribuir, explorar comercialmente ou utilizar indevidamente qualquer elemento do ConeCTEA sem autorização prévia e expressa da Família TEA Bauru ou de quem detenha os direitos aplicáveis.\n\nO usuário também não poderá utilizar o nome ConeCTEA, Família TEA Bauru, carteirinha comunitária, logotipos, telas, materiais, conteúdos ou comunicações oficiais para criar aparência de autorização, representação, parceria, vínculo oficial ou benefício indevido.\n\nO conteúdo disponibilizado no aplicativo possui finalidade informativa, comunitária e organizacional, devendo ser utilizado apenas nos limites previstos por estes Termos.',
                    '21',
                  ),
                  _buildSectionBlock(
                    '22. Serviços de terceiros e integrações técnicas',
                    'O funcionamento do ConeCTEA poderá depender de serviços, ferramentas, plataformas, sistemas ou integrações técnicas de terceiros, utilizados para viabilizar funcionalidades como autenticação, banco de dados, armazenamento, notificações, comunicação, suporte, apoio documental, segurança, infraestrutura e operação do aplicativo.\n\nEsses serviços poderão incluir, conforme a arquitetura técnica adotada, plataformas de banco de dados, autenticação, envio de notificações, armazenamento externo, serviços de nuvem, ferramentas de apoio documental, sistemas de comunicação e outras integrações necessárias ao funcionamento do ConeCTEA.\n\nO uso desses serviços deverá ocorrer de acordo com a finalidade do aplicativo, a Política de Privacidade, as regras de segurança aplicáveis e as condições técnicas necessárias à operação.\n\nA Família TEA Bauru não controla integralmente o funcionamento, disponibilidade, políticas, infraestrutura, instabilidades, falhas ou alterações realizadas por serviços de terceiros utilizados no aplicativo.\n\nO usuário reconhece que o uso do ConeCTEA pode envolver tratamento de dados por terceiros necessários à operação técnica ou comunitária do aplicativo, sempre conforme a finalidade declarada e os limites aplicáveis.',
                    '22',
                  ),
                  _buildSectionBlock(
                    '23. Privacidade e proteção de dados',
                    'O uso do ConeCTEA poderá envolver tratamento de dados pessoais e, em alguns casos, dados pessoais sensíveis, especialmente quando houver cadastro, acesso à conta, solicitações, dependentes, crianças, adolescentes, documentos, laudos, participação em programas comunitários, notificações, suporte ou encaminhamento inicial a parceiros.\n\nA forma como os dados são coletados, utilizados, armazenados, compartilhados, protegidos, corrigidos ou excluídos será detalhada na Política de Privacidade do ConeCTEA, que complementa estes Termos de Uso.\n\nAo utilizar o ConeCTEA, o usuário declara estar ciente de que seus dados poderão ser tratados para finalidades como cadastro, autenticação, análise de solicitações, emissão e visualização de carteirinha comunitária, participação em programas, comunicação, notificações, suporte, segurança, prevenção de fraude, organização comunitária e cumprimento de obrigações aplicáveis.\n\nA Família TEA Bauru deverá tratar dados pessoais de forma compatível com a finalidade do ConeCTEA, buscando limitar o acesso ao necessário, evitar exposição indevida e orientar o usuário sobre canais de suporte, correção ou exclusão de dados quando aplicável.\n\nEm caso de dúvida sobre privacidade ou proteção de dados, o usuário poderá entrar em contato pelos canais oficiais da Família TEA Bauru indicados nestes Termos.',
                    '23',
                  ),
                  _buildSectionBlock(
                    '24. Alterações destes Termos de Uso',
                    'A Família TEA Bauru poderá atualizar, revisar, complementar ou alterar estes Termos de Uso a qualquer momento, especialmente para refletir mudanças no ConeCTEA, novas funcionalidades, programas comunitários, exigências legais, exigências de plataformas, melhorias de segurança, ajustes de privacidade, reorganização operacional ou necessidades da comunidade.\n\nA versão atualizada dos Termos poderá ser disponibilizada dentro do aplicativo, em documento oficial, canal digital, site, link informado ou outro meio adequado.\n\nSempre que houver alteração relevante, a Família TEA Bauru poderá comunicar os usuários por meio do próprio aplicativo, notificações, e-mail, WhatsApp, Instagram, grupo comunitário ou outros canais oficiais, quando possível e adequado.\n\nO uso contínuo do ConeCTEA após a disponibilização de nova versão dos Termos poderá ser interpretado como ciência e concordância com as condições atualizadas, salvo quando a legislação ou a natureza da alteração exigir consentimento específico ou nova confirmação.\n\nCaso o usuário não concorde com nova versão dos Termos, deverá interromper o uso do aplicativo e poderá buscar orientação pelos canais oficiais da Família TEA Bauru.\n\nA data de última atualização e a versão dos Termos deverão ser indicadas no início do documento, sempre que possível, para facilitar controle, transparência e consulta pelos usuários.',
                    '24',
                  ),
                  _buildSectionBlock(
                    '25. Lei aplicável, solução de dúvidas e contato oficial',
                    'Estes Termos de Uso são regidos pela legislação brasileira aplicável, incluindo normas relacionadas a direitos civis, proteção de dados pessoais, uso de aplicações digitais, defesa de direitos dos usuários e demais regras pertinentes ao funcionamento do ConeCTEA.\n\nEventuais dúvidas, solicitações, reclamações, pedidos de esclarecimento, correção de dados, suporte, privacidade, exclusão de conta ou assuntos relacionados ao uso do aplicativo deverão ser encaminhados preferencialmente pelos canais oficiais da Família TEA Bauru:\n\nFamília TEA Bauru — Bauru/SP\nE-mail principal: familiateabauru@gmail.com\nWhatsApp oficial: +55 14 99101-2961 — Renata Ferreguti\nGrupo comunitário: https://chat.whatsapp.com/Hhl4SmcahMZ3DX8GEkpQ6s?mode=ac_t\nInstagram: https://www.instagram.com/familiateabauru/\nE-mail secundário: conecteabauru@gmail.com\nSite oficial: em breve\n\nA Família TEA Bauru buscará tratar dúvidas e solicitações de forma compatível com sua capacidade operacional, natureza comunitária, disponibilidade da equipe, proteção de dados, segurança dos participantes e regras aplicáveis.\n\nAntes de qualquer medida externa, recomenda-se que o usuário busque contato pelos canais oficiais para esclarecimento, orientação ou tentativa de solução amigável.\n\nNada nestes Termos deve ser interpretado como renúncia de direitos que não possam ser renunciados pela legislação brasileira aplicável.',
                    '25',
                  ),

                  const SizedBox(height: 12),
                  _buildVersionCard('1.0', '21/05/2026'),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'CONCORDO COM OS TERMOS',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvisoBlock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.info, color: Color(0xFF22D3EE), size: 20),
              const SizedBox(width: 10),
              Text(
                'Aviso importante',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Estes Termos de Uso regulam o acesso e a utilização do aplicativo ConeCTEA, desenvolvido para apoiar ações sociais, comunitárias, organizacionais e informativas da Família TEA Bauru.\n\nA Família TEA Bauru é uma comunidade e rede de apoio, não sendo empresa, órgão público, entidade governamental, serviço público, clínica, consultório, operadora de saúde ou entidade médica equivalente.\n\nO ConeCTEA possui finalidade comunitária, organizacional, informativa e administrativa. O aplicativo não é órgão público, não representa entidade governamental, não presta serviço público, não emite documento oficial e não substitui documentos, cadastros, laudos, diagnósticos, atendimentos, serviços públicos ou políticas públicas.\n\nA carteirinha digital comunitária ConeCTEA possui finalidade interna, comunitária e organizacional. Ela não substitui CIPTEA, RG, CPF, CNH, laudo médico, diagnóstico, documento civil ou qualquer documento emitido pelo Poder Público.\n\nO ConeCTEA não é aplicativo médico, não realiza diagnóstico, não realiza avaliação clínica, não prescreve tratamento, não define conduta médica, odontológica, terapêutica ou profissional, não substitui atendimento de profissional habilitado e não deve ser utilizado como ferramenta de comprovação médica.\n\nAo criar conta, acessar ou utilizar o ConeCTEA, o usuário declara que leu, compreendeu e concorda com estes Termos de Uso e com a Política de Privacidade aplicável.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFFB8C7E6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBlock(String title, String content, String number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumberBadge(number),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFFB8C7E6),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberBadge(String number) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.2),
            const Color(0xFF22D3EE).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          number,
          style: GoogleFonts.outfit(
            fontSize: number.length > 2 ? 12 : 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF22D3EE),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard(String version, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.info, color: Color(0xFF7C3AED), size: 16),
              const SizedBox(width: 10),
              Text(
                'Versão $version',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            'Atualizado em $date',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
