import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
          'Privacidade',
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
              title: 'Política de Privacidade',
              subtitle: 'Entenda como o ConeCTEA trata seus dados e protege sua privacidade.',
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvisoBlock(),

                  _buildSectionBlock(
                    '1. Identificação e finalidade desta Política de Privacidade',
                    'Esta Política de Privacidade explica como o ConeCTEA poderá coletar, utilizar, armazenar, proteger, compartilhar, corrigir e excluir dados pessoais relacionados aos usuários do aplicativo, participantes cadastrados, dependentes, familiares, responsáveis, pessoas vinculadas à conta, voluntários, parceiros e demais pessoas que interajam com as funcionalidades disponíveis.\n\nO objetivo desta Política é informar, de forma clara e transparente, quais dados podem ser tratados pelo ConeCTEA, para quais finalidades esses dados podem ser utilizados, quem poderá acessá-los, em quais situações eles poderão ser compartilhados e quais canais podem ser utilizados para dúvidas, correções, solicitações ou exclusão de dados.\n\nO ConeCTEA é um aplicativo social, comunitário, organizacional e informativo vinculado à Família TEA Bauru, comunidade e rede de apoio formada por familiares, mães, responsáveis, voluntários, profissionais, parceiros e pessoas comprometidas com inclusão real, respeito e acolhimento.\n\nEsta Política de Privacidade deve ser lida em conjunto com os Termos de Uso do ConeCTEA, pois os dois documentos se complementam. Os Termos de Uso explicam as regras de utilização do aplicativo, enquanto esta Política explica como os dados pessoais podem ser tratados dentro do ConeCTEA.\n\nAo criar conta, acessar ou utilizar o ConeCTEA, o usuário declara estar ciente de que seus dados poderão ser tratados conforme esta Política de Privacidade, conforme os Termos de Uso aplicáveis e conforme as funcionalidades efetivamente disponíveis no aplicativo.\n\nCaso o usuário não concorde com esta Política de Privacidade, deverá interromper o uso do ConeCTEA e, se necessário, entrar em contato pelos canais oficiais da Família TEA Bauru para esclarecimentos.',
                    '1',
                  ),

                  _buildSectionBlock(
                    '2. Quem é a Família TEA Bauru e qual é o papel do ConeCTEA',
                    'A Família TEA Bauru é uma comunidade e rede de apoio formada por familiares, mães, responsáveis, voluntários, profissionais, parceiros e pessoas comprometidas com inclusão real, respeito e acolhimento de famílias relacionadas ao Transtorno do Espectro Autista (TEA) e outras necessidades da comunidade.\n\nA Família TEA Bauru atua como uma iniciativa comunitária, social, colaborativa e de apoio, com foco em aproximar pessoas, organizar ações, facilitar comunicação, apoiar famílias e fortalecer redes de acolhimento.\n\nA Família TEA Bauru não deve ser interpretada, apenas pelo uso do ConeCTEA ou pela existência desta Política, como empresa, órgão público, entidade governamental, serviço público, clínica, consultório, operadora de saúde, entidade médica ou entidade formal equivalente, salvo se houver formalização futura expressamente informada por seus canais oficiais.\n\nO ConeCTEA é o aplicativo criado para apoiar a organização digital de parte das ações da Família TEA Bauru, incluindo cadastro de usuários, solicitações, acompanhamento da carteirinha digital comunitária, notificações, suporte, programas comunitários, comunicação com participantes e outras funcionalidades relacionadas à comunidade.\n\nO ConeCTEA possui finalidade social, comunitária, organizacional, informativa e administrativa. O aplicativo não é órgão público, não representa entidade governamental, não presta serviço público, não emite documento oficial e não substitui documentos, cadastros, laudos, diagnósticos, atendimentos, serviços públicos ou políticas públicas municipais, estaduais ou federais.\n\nA carteirinha digital comunitária ConeCTEA, quando solicitada, exibida ou gerenciada pelo aplicativo, possui finalidade interna, comunitária e organizacional, vinculada às ações e regras da Família TEA Bauru. Ela não substitui CIPTEA, RG, CPF, CNH, laudo médico, diagnóstico, documento civil, documento oficial ou qualquer documento emitido pelo Poder Público.\n\nO ConeCTEA também não é aplicativo médico, odontológico, terapêutico ou clínico. O aplicativo não realiza diagnóstico, não emite laudo, não confirma condição clínica, não prescreve tratamento, não define conduta profissional e não substitui atendimento realizado por profissional habilitado.\n\nQuando o ConeCTEA apoiar programas comunitários, chamamentos, listas de interesse, comunicação de selecionados ou primeiro agendamento com profissionais e parceiros, sua função será de organização e comunicação comunitária, não de prestação direta de serviço médico, odontológico, terapêutico ou clínico.',
                    '2',
                  ),

                  _buildSectionBlock(
                    '3. Quais dados podem ser coletados pelo ConeCTEA',
                    'Para criação de conta e acesso ao aplicativo, o ConeCTEA poderá coletar dados como nome completo, CPF, telefone, data de nascimento, e-mail, estado, cidade e senha.\n\nA senha e a confirmação de senha são utilizadas para criação e acesso seguro à conta. A confirmação de senha serve para validar a digitação no momento do cadastro e não deve ser tratada como informação de perfil do usuário.\n\nO aplicativo também poderá coletar dados opcionais ou complementares no cadastro, como nome social, gênero, raça/cor e informação sobre indicação por alguma instituição, comunidade, grupo, parceiro ou pessoa, quando esses campos estiverem disponíveis.\n\nEsses dados opcionais poderão ser utilizados para melhor identificação do usuário, respeito ao nome social, organização comunitária, análise interna, melhoria das ações da Família TEA Bauru e compreensão geral do público atendido, sempre dentro da finalidade do ConeCTEA.\n\nPara solicitação da carteirinha digital comunitária ConeCTEA, o aplicativo poderá coletar dados do beneficiário, como nome completo, CPF, data de nascimento, estado, cidade e telefone.\n\nA solicitação de carteirinha também poderá incluir dados de contato para apoio ou segurança, como nome do contato de emergência, número do contato de emergência, nome do responsável e número do responsável, quando esses dados forem informados pelo usuário ou solicitados pela funcionalidade disponível.\n\nA solicitação de carteirinha poderá incluir ainda dados opcionais de saúde ou identificação complementar, como tipo sanguíneo e CID, quando esses campos forem disponibilizados e preenchidos pelo usuário.\n\nPara análise da solicitação da carteirinha comunitária, o ConeCTEA poderá solicitar documento com foto do beneficiário, em formatos como PNG, JPEG, JPG ou PDF, conforme permitido pelo aplicativo.\n\nO documento com foto poderá ser utilizado para conferência administrativa dos dados informados, especialmente para verificar se nome, CPF e demais informações básicas da solicitação correspondem ao documento apresentado.\n\nO ConeCTEA também poderá solicitar laudo médico ou documento equivalente, em formatos como PNG, JPEG, JPG ou PDF, conforme permitido pelo aplicativo, para apoiar a conferência documental administrativa da solicitação comunitária.\n\nO laudo médico poderá ser utilizado para verificar se as informações apresentadas são compatíveis com a finalidade da carteirinha digital comunitária, evitando uso indevido, solicitações incompatíveis ou tentativa de acesso indevido a ações, apoios ou programas destinados à comunidade TEA.\n\nO uso do laudo no ConeCTEA não significa que o aplicativo realiza diagnóstico, valida condição clínica por conta própria, substitui avaliação médica ou emite comprovação médica. A análise realizada pela Família TEA Bauru possui finalidade comunitária, documental, administrativa e organizacional.\n\nPara reduzir a exposição direta de dados pessoais no armazenamento técnico, os documentos enviados ao ConeCTEA poderão receber nomes técnicos internos gerados pelo sistema, em vez de manter nomes originais enviados pelo usuário.\n\nDocumentos com foto poderão ser renomeados com prefixos técnicos como DOC_MBR seguidos de sequência hexadecimal de 8 caracteres. Laudos médicos poderão ser renomeados com prefixos técnicos como LAUDO_MBR seguidos de sequência hexadecimal de 8 caracteres.\n\nEssa renomeação técnica tem a finalidade de evitar que nomes de arquivos exponham diretamente nome completo, CPF, documento, laudo, diagnóstico ou outras informações pessoais do usuário, beneficiário ou dependente.\n\nA renomeação técnica do arquivo não altera a natureza sensível do documento. Documentos com foto, laudos médicos, CID e informações relacionadas à condição da pessoa continuam sendo tratados como dados sensíveis ou de cuidado especial, devendo ser acessados apenas quando necessário para análise da solicitação, conferência documental, prevenção de uso indevido e organização comunitária.\n\nO aplicativo também poderá coletar dados relacionados à carteirinha digital comunitária, como informações da solicitação, status de análise, protocolo, dados exibidos na carteirinha, validade, histórico de solicitação, motivo de pendência, motivo de recusa, motivo de suspensão ou orientações administrativas, quando aplicável.\n\nO ConeCTEA também poderá gerar identificadores técnicos internos relacionados à carteirinha digital comunitária, incluindo o TEA ID, identificadores de validação e dados necessários para funcionamento do código QR (QR Code) da carteirinha dentro do aplicativo.\n\nO TEA ID é um identificador interno da carteirinha comunitária, utilizado para organização, consulta e validação dentro do sistema ConeCTEA. Ele poderá ser composto por um prefixo técnico, como TEA-ID, seguido de uma sequência hexadecimal de 8 caracteres gerada pelo sistema.\n\nO TEA ID não substitui documentos oficiais e não deve ser interpretado como número de documento público, registro governamental, identificação civil, número médico, laudo, diagnóstico ou validação emitida por autoridade pública.\n\nAtualmente, o código QR (QR Code) da carteirinha digital comunitária é utilizado apenas para validação dentro do próprio aplicativo ConeCTEA, por meio de funcionalidade interna de leitura disponível para usuários autorizados conforme as regras do app.\n\nAo escanear o código QR dentro do ConeCTEA, o aplicativo poderá exibir informações básicas de validação da carteirinha comunitária, como nome del beneficiário, TEA ID, situação da carteirinha e data de validade, conforme os dados disponíveis no sistema.\n\nO código QR não deve conter documento com foto, laudo médico, CPF completo, CID, tipo sanguíneo ou anexos sensíveis. Sua finalidade atual é apoiar a validação interna e comunitária da carteirinha, sem transformar a carteirinha em documento oficial.\n\nA validação pelo código QR depende do funcionamento do aplicativo, das permissões internas, da disponibilidade técnica do sistema e da situação atual da carteirinha no ConeCTEA.\n\nQuando houver cadastro de dependentes, familiares, crianças, adolescentes ou pessoas vinculadas à conta, o ConeCTEA poderá coletar dados necessários para identificação, vínculo, solicitação de carteirinha comunitária, participação em programas e comunicação com o usuário responsável pela conta.\n\nO ConeCTEA poderá coletar dados relacionados a programas comunitários, como inscrição em chamamentos, lista de interesse, seleção, aprovação, encaminhamento inicial, comunicação de vaga, agendamento da primeira consulta ou informações necessárias para participação em ações como Fada do Dente, Vidas ou outros programas futuros.\n\nQuando houver participação em programas com profissionais, clínicas ou parceiros, poderão ser tratados dados mínimos necessários para organização, contato, confirmação, agendamento e realização da primeira consulta ou ação vinculada ao programa.\n\nO ConeCTEA também poderá tratar dados de comunicação e suporte, como mensagens enviadas pelo usuário, solicitações de ajuda, dúvidas, pedidos de correção, solicitações de exclusão, registros de atendimento, notificações enviadas e respostas relacionadas ao uso do aplicativo.\n\nAlém disso, o aplicativo poderá tratar dados técnicos necessários ao funcionamento, segurança e melhoria do serviço, como identificadores internos de usuário, registros de sessão, status de autenticação, identificadores de notificação, informações básicas do dispositivo, data e horário de ações relevantes, registros de erro e dados técnicos mínimos para prevenção de falhas, segurança e suporte.',
                    '3',
                  ),

                  _buildSectionBlock(
                    '4. Dados de crianças, adolescentes, dependentes e pessoas vinculadas à conta',
                    'O ConeCTEA poderá tratar dados pessoais de crianças, adolescentes, dependentes, familiares ou pessoas vinculadas à conta do usuário quando essas informações forem necessárias para cadastro, solicitação da carteirinha digital comunitária, participação em programas comunitários, comunicação, suporte, análise administrativa ou organização das ações da Família TEA Bauru.\n\nO cadastro ou envio de dados de criança, adolescente, dependente ou outra pessoa vinculada deverá ser realizado por usuário que possua autorização, legitimidade, vínculo familiar, vínculo de cuidado, representação, tutela, curatela, responsabilidade legal ou outra condição adequada para fornecer essas informações dentro do aplicativo.\n\nAo informar dados de outra pessoa no ConeCTEA, o usuário declara que possui autorização ou vínculo adequado para realizar o cadastro, enviar documentos, solicitar carteirinha comunitária, participar de programas ou acompanhar solicitações em nome dessa pessoa.\n\nQuando a pessoa cadastrada, dependente ou vinculada à conta for criança ou adolescente, o cadastro, envio de dados, envio de documentos, solicitação de carteirinha comunitária, participação em programas e acompanhamento de solicitações deverão ser realizados por pai, mãe, responsável legal ou pessoa com autorização legítima para agir em nome da pessoa vinculada.\n\nQuando os dados envolverem crianças ou adolescentes, o tratamento deverá observar cuidado especial, finalidade legítima, necessidade, segurança, proteção da privacidade, dignidade e melhor interesse da criança ou adolescente.\n\nNo caso de crianças, o tratamento de dados pessoais deverá observar consentimento específico e em destaque de pelo menos um dos pais ou responsável legal, quando aplicável, conforme a Lei Geral de Proteção de Dados Pessoais — LGPD.\n\nOs dados de crianças, adolescentes e dependentes poderão incluir informações cadastrais, dados de contato do responsável pela conta, informações de vínculo, documentos, laudos, dados da solicitação da carteirinha comunitária, status de análise, participação em programas, notificações e informações necessárias para comunicação ou encaminhamento inicial em ações comunitárias.\n\nA Família TEA Bauru deverá utilizar esses dados apenas para finalidades compatíveis com o ConeCTEA, como organização comunitária, análise de solicitações, emissão e validação da carteirinha digital comunitária, participação em programas, comunicação com o usuário responsável pela conta, suporte, segurança e prevenção de uso indevido.\n\nO ConeCTEA não deve expor dados de crianças, adolescentes, dependentes ou pessoas vinculadas a outros usuários não autorizados. O acesso a essas informações deverá ser limitado ao próprio usuário responsável pela conta, à equipe autorizada da Família TEA Bauru e, quando necessário, a profissionais, clínicas ou parceiros envolvidos em programas comunitários específicos, sempre dentro da finalidade informada.\n\nQuando houver compartilhamento de dados de criança, adolescente ou dependente com profissional, clínica ou parceiro participante de programa comunitário, esse compartilhamento deverá ser limitado aos dados necessários para organização, contato, confirmação, agendamento inicial ou realização da ação vinculada ao programa.\n\nO usuário se compromete a não cadastrar dados de criança, adolescente, dependente ou terceiro sem autorização, sem vínculo adequado, de forma falsa, abusiva, discriminatória, fraudulenta ou incompatível com a finalidade do ConeCTEA.\n\nCaso a Família TEA Bauru identifique inconsistência, ausência de vínculo adequado, suspeita de uso indevido, conflito de informações, risco à privacidade ou violação desta Política, poderá solicitar confirmação, correção, complementação, suspensão de análise, bloqueio de solicitação, remoção de dados ou outras medidas necessárias para proteção da pessoa vinculada e da comunidade.\n\nA remoção de dependente, quando disponível no aplicativo, poderá apagar os dados vinculados a esse dependente do banco de dados operacional do ConeCTEA, conforme o fluxo técnico existente e os limites descritos nesta Política de Privacidade.\n\nA exclusão da conta do usuário responsável também poderá impactar dados de dependentes e pessoas vinculadas, podendo resultar na remoção desses dados do banco de dados operacional do ConeCTEA, conforme as regras técnicas do aplicativo e os limites aplicáveis.',
                    '4',
                  ),

                  _buildSectionBlock(
                    '5. Dados sensíveis, documentos e laudos',
                    'O ConeCTEA poderá tratar dados pessoais sensíveis ou informações que exigem cuidado especial quando forem necessários para cadastro, solicitação da carteirinha digital comunitária, análise administrativa, participação em programas comunitários, suporte, segurança ou organização das ações da Família TEA Bauru.\n\nPodem ser considerados dados sensíveis ou de cuidado especial, entre outros, laudos médicos, CID, tipo sanguíneo, documentos com foto, raça/cor quando informado, informações relacionadas à condição da pessoa, dados de crianças e adolescentes, dados de dependentes, informações de responsáveis, dados de contato de emergência, motivos de pendência, reprovação ou suspensão e informações relacionadas à participação em programas comunitários.\n\nO ConeCTEA poderá solicitar documento com foto para conferência administrativa dos dados informados na solicitação da carteirinha comunitária, especialmente para verificar se nome, CPF e demais informações básicas correspondem ao documento apresentado.\n\nO ConeCTEA poderá solicitar laudo médico ou documento equivalente para apoiar a conferência documental administrativa da solicitação comunitária e reduzir o risco de uso indevido da carteirinha digital comunitária ou de ações destinadas à comunidade TEA.\n\nO uso de laudo médico, CID ou documento equivalente no ConeCTEA não significa que o aplicativo realiza diagnóstico, confirma condição clínica por conta própria, substitui avaliação médica, emite comprovação médica ou valida oficialmente a condição da pessoa.\n\nA análise realizada pela Família TEA Bauru possui finalidade comunitária, documental, administrativa, organizacional e de prevenção de uso indevido, limitada ao contexto da carteirinha digital comunitária, solicitações internas, programas comunitários e ações da comunidade.\n\nDocumentos com foto, laudos médicos e anexos enviados pelo usuário deverão ser acessados apenas por pessoas autorizadas e somente quando necessário para análise da solicitação, conferência documental, correção de pendências, segurança, prevenção de fraude, revisão de situação ou organização comunitária.\n\nSempre que possível, o ConeCTEA deverá adotar práticas de minimização, retenção temporária, controle de acesso, renomeação técnica de arquivos e descarte de documentos sensíveis quando eles não forem mais necessários para a finalidade que justificou o envio.\n\nDocumentos enviados ao ConeCTEA poderão receber nomes técnicos internos gerados pelo sistema, como DOC_MBR seguido de sequência hexadecimal para documentos com foto, ou LAUDO_MBR seguido de sequência hexadecimal para laudos médicos, com o objetivo de evitar exposição direta de nome, CPF, diagnóstico ou outras informações pessoais no nome do arquivo.\n\nA renomeação técnica não altera a natureza sensível do documento. Mesmo com nome técnico, documentos com foto, laudos, CID e informações relacionadas à condição da pessoa continuam exigindo cuidado especial.\n\nA Família TEA Bauru não deverá utilizar documentos, laudos ou informações sensíveis para finalidade incompatível com o ConeCTEA, nem compartilhar esses dados sem necessidade, autorização, finalidade legítima ou previsão nesta Política de Privacidade.\n\nQuando dados sensíveis forem necessários para programas comunitários, chamamentos, listas de interesse ou primeiro encaminhamento com profissionais e parceiros, o tratamento deverá ser limitado ao mínimo necessário para organização, contato, confirmação, agendamento ou realização da ação vinculada ao programa.\n\nO usuário deve enviar apenas documentos verdadeiros, legíveis, pertinentes e relacionados à solicitação realizada. O envio de documento falso, adulterado, incompatível, ilegível, pertencente a terceiro sem autorização ou utilizado para finalidade indevida poderá resultar em recusa, suspensão, bloqueio, cancelamento da solicitação ou outras medidas necessárias para proteção da comunidade.\n\nO prazo de retenção, descarte e exclusão de documentos sensíveis será tratado em seção específica desta Política de Privacidade, considerando aprovação, pendências, reprovação, suspensão, revisão e exclusão de conta ou dependente.',
                    '5',
                  ),

                  _buildSectionBlock(
                    '6. Para que os dados são utilizados',
                    'Os dados tratados pelo ConeCTEA são utilizados para permitir o funcionamento do aplicativo, a organização comunitária da Família TEA Bauru, a análise de solicitações, a comunicação com usuários e a execução das funcionalidades disponíveis.\n\nOs dados de cadastro, como nome, CPF, telefone, data de nascimento, e-mail, estado, cidade e senha, poderão ser utilizados para criação de conta, autenticação, identificação do usuário, prevenção de cadastros duplicados, segurança de acesso, suporte e comunicação relacionada ao uso do aplicativo.\n\nO CPF poderá ser utilizado como dado de identificação cadastral, conferência administrativa, prevenção de duplicidade, organização de solicitações e segurança da conta. O CPF não deve ser utilizado como identificador público da carteirinha, nem exposto desnecessariamente em telas, notificações, código QR (QR Code) ou comunicações externas.\n\nO e-mail poderá ser utilizado para acesso à conta, autenticação, recuperação de acesso, comunicação relacionada à conta e suporte. A senha será utilizada exclusivamente para autenticação e segurança de acesso, conforme os mecanismos técnicos disponíveis no aplicativo.\n\nDados opcionais, como nome social, gênero, raça/cor e informação sobre indicação por instituição, comunidade, grupo, parceiro ou pessoa, poderão ser utilizados para respeito à identificação do usuário, compreensão do público atendido, melhoria das ações comunitárias, organização interna e análise geral da atuação da Família TEA Bauru.\n\nEsses dados opcionais não devem ser utilizados para discriminação, exclusão indevida, tratamento abusivo ou restrição injustificada de acesso ao aplicativo.\n\nOs dados informados na solicitação da carteirinha digital comunitária poderão ser utilizados para análise administrativa, conferência documental, emissão, exibição, validação interna, acompanhamento de status, renovação, suspensão, revisão ou reprovação da carteirinha, conforme as regras da Família TEA Bauru.\n\nDocumentos com foto poderão ser utilizados para conferir se os dados informados na solicitação, como nome, CPF, data de nascimento e demais informações básicas, correspondem ao documento apresentado.\n\nLaudos médicos ou documentos equivalentes poderão ser utilizados para conferência documental administrativa da solicitação comunitária, com a finalidade de verificar compatibilidade com a proposta da carteirinha digital comunitária e reduzir risco de uso indevido por pessoas que não se enquadrem na finalidade das ações comunitárias da Família TEA Bauru.\n\nO uso de laudo médico, CID ou documento equivalente não significa que o ConeCTEA realiza diagnóstico, valida condição clínica por conta própria, substitui avaliação médica ou emite comprovação médica. A análise possui finalidade comunitária, documental, administrativa, organizacional e de prevenção de uso indevido.\n\nDados como tipo sanguíneo, CID, contato de emergência e dados de responsável poderão ser utilizados, quando informados, para identificação complementar, apoio à organização comunitária, segurança do beneficiário, contato em situações necessárias e melhoria do atendimento comunitário dentro das funcionalidades disponíveis.\n\nOs dados de dependentes, crianças, adolescentes, familiares ou pessoas vinculadas à conta poderão ser utilizados para cadastro, solicitação de carteirinha comunitária, análise administrativa, comunicação com o usuário responsável, participação em programas comunitários e organização das ações da Família TEA Bauru.\n\nOs dados relacionados ao TEA ID, identificadores técnicos internos, identificadores de validação e código QR poderão ser utilizados para organização, consulta e validação comunitária da carteirinha dentro do próprio aplicativo ConeCTEA.\n\nAtualmente, a validação por código QR é utilizada apenas dentro do aplicativo, por usuários autorizados conforme as regras do app, podendo exibir informações básicas como nome do beneficiário, TEA ID, situação da carteirinha e data de validade.\n\nO código QR e o TEA ID não têm finalidade de documento oficial, identificação civil, validação médica ou registro governamental. Eles são usados apenas como recursos técnicos e comunitários para validação interna da carteirinha no ConeCTEA.\n\nDados relacionados a programas comunitários, como inscrições, chamamentos, listas de interesse, seleção, aprovação, encaminhamento inicial, comunicação de vaga e agendamento da primeira consulta, poderão ser utilizados para organizar ações como Fada do Dente, Vidas ou outros programas futuros da Família TEA Bauru.\n\nQuando houver participação em programa comunitário com profissionais, clínicas ou parceiros, os dados mínimos necessários poderão ser utilizados para contato, confirmação, organização, agendamento inicial e realização da ação vinculada ao programa, conforme as regras específicas da iniciativa.\n\nDados de comunicação e suporte poderão ser utilizados para responder dúvidas, registrar solicitações, orientar o usuário, acompanhar pedidos de correção, analisar solicitações de exclusão, prestar suporte técnico ou administrativo e melhorar a comunicação entre a Família TEA Bauru e os usuários do ConeCTEA.\n\nDados técnicos, como identificadores internos de usuário, registros de sessão, status de autenticação, identificadores de notificação, informações básicas do dispositivo, data e horário de ações relevantes, registros de erro e dados mínimos de funcionamento, poderão ser utilizados para segurança, prevenção de falhas, suporte, manutenção, melhoria do aplicativo e proteção contra uso indevido.\n\nAs notificações poderão ser utilizadas para informar atualizações de solicitação, pendências, aprovações, recusas, agendamentos iniciais, avisos de programas, comunicações importantes, suporte, segurança e outras informações relacionadas ao uso do ConeCTEA.\n\nSempre que possível, notificações deverão evitar exposição de dados sensíveis. Informações detalhadas sobre documentos, laudos, CPF, CID, motivos sensíveis, dados de dependentes ou comunicações administrativas delicadas devem ser consultadas preferencialmente dentro do ambiente autenticado do aplicativo.\n\nOs dados também poderão ser utilizados de forma estatística, agregada e generalizada para elaboração de relatórios internos, indicadores comunitários, planejamento de ações, busca de apoio, apresentação de impacto social, aproximação com parceiros, empresas, profissionais, projetos e possíveis apoiadores da Família TEA Bauru.\n\nEsses relatórios poderão conter informações gerais, como quantidade de usuários cadastrados, quantidade de carteirinhas solicitadas, aprovadas ou ativas, faixas etárias predominantes, cidades atendidas, distribuição geral por estado, participação em programas comunitários e outros indicadores amplos relacionados ao alcance das ações da Família TEA Bauru.\n\nA utilização estatística deverá evitar a identificação individual de usuários, beneficiários, dependentes, crianças, adolescentes ou participantes cadastrados. Sempre que possível, os dados deverão ser apresentados de forma agrupada, resumida ou generalizada, sem exposição de nome, CPF, telefone, e-mail, documento, laudo, CID, TEA ID, código QR, endereço individual, contato de emergência ou qualquer informação que permita identificar diretamente uma pessoa.\n\nA Família TEA Bauru não deverá divulgar relatórios estatísticos de forma que permita concluir, de maneira direta ou indireta, quem é determinada pessoa cadastrada, especialmente em grupos pequenos, cidades com poucos cadastros, programas com poucos participantes ou situações em que a combinação de dados possa facilitar identificação individual.\n\nExemplos de uso estatístico permitido incluem informar que o ConeCTEA possui determinado número total de usuários cadastrados, determinada quantidade de carteirinhas comunitárias ativas, cidades atendidas de forma geral, faixas etárias agrupadas ou número total de participantes em um programa comunitário.\n\nO uso de dados estatísticos e agregados tem finalidade de fortalecer a atuação comunitária, melhorar o planejamento das ações, demonstrar impacto social, buscar apoio institucional ou privado e ampliar parcerias em benefício da comunidade, sem exposição indevida de dados pessoais ou sensíveis.\n\nOs dados tratados pelo ConeCTEA não devem ser utilizados para finalidade incompatível com o aplicativo, nem para venda de dados pessoais, discriminação, exposição indevida, publicidade abusiva ou uso estranho à finalidade comunitária, organizacional, administrativa, informativa e de segurança da Família TEA Bauru.\n\nA Família TEA Bauru deverá buscar utilizar apenas os dados necessários para cada finalidade, respeitando o princípio de minimização, a proteção de dados pessoais e o cuidado especial com documentos, laudos, crianças, adolescentes, dependentes e informações sensíveis.',
                    '6',
                  ),

                  _buildSectionBlock(
                    '7. Carteirinha digital comunitária ConeCTEA',
                    'A carteirinha digital comunitária ConeCTEA é uma funcionalidade do aplicativo criada para apoiar a organização interna, comunitária e administrativa das ações da Família TEA Bauru.\n\nA carteirinha poderá reunir dados necessários para identificação comunitária do beneficiário dentro do ConeCTEA, como nome, TEA ID, status da carteirinha, data de validade e outras informações permitidas conforme as funcionalidades disponíveis no aplicativo.\n\nA carteirinha digital comunitária ConeCTEA possui finalidade interna, comunitária, organizacional e informativa. Ela não é documento oficial, não possui natureza de documento civil, não é emitida por órgão público e não substitui CIPTEA, RG, CPF, CNH, laudo médico, diagnóstico, documento oficial, documento civil, serviço público ou política pública.\n\nA aprovação da carteirinha no ConeCTEA não significa validação médica, diagnóstico, comprovação oficial de condição clínica ou reconhecimento emitido por autoridade pública. A análise realizada pela Família TEA Bauru possui finalidade comunitária, documental, administrativa e organizacional.\n\nA carteirinha poderá possuir um identificador técnico interno chamado TEA ID, utilizado para organização, consulta e validação comunitária dentro do sistema ConeCTEA.\n\nO TEA ID poderá ser exibido na carteirinha e utilizado em recursos internos do aplicativo, como consulta, controle administrativo e validação por código QR, quando disponível.\n\nO TEA ID não substitui CPF, RG, CIPTEA, número de documento público, registro governamental, documento médico, laudo ou qualquer identificação oficial.\n\nA carteirinha também poderá conter código QR (QR Code) ou outro recurso técnico de validação. Atualmente, a validação por código QR ocorre apenas dentro do próprio aplicativo ConeCTEA, por funcionalidade interna de leitura disponível a usuários autorizados conforme as regras do app.\n\nAo escanear o código QR dentro do ConeCTEA, o aplicativo poderá exibir informações básicas de validação, como nome do beneficiário, TEA ID, situação da carteirinha e data de validade, conforme os dados disponíveis no sistema.\n\nO código QR da carteirinha não deve conter documento com foto, laudo médico, CPF completo, CID, tipo sanguíneo, contato de emergência, anexos sensíveis ou informações além do necessário para validação comunitária.\n\nA validação por código QR depende do funcionamento do aplicativo, das permissões internas, da disponibilidade técnica do sistema, do status da carteirinha e da data de validade registrada no ConeCTEA.\n\nA carteirinha poderá ter status como ativa, em análise, aguardando aprovação, aguardando documentação, em revisão, vencida, suspensa, reprovada, em renovação ou outros estados definidos pela organização do ConeCTEA, conforme a evolução das funcionalidades.\n\nOs dados exibidos na carteirinha devem ser limitados ao necessário para sua finalidade comunitária, evitando exposição indevida de documentos, laudos, diagnóstico, CPF completo ou informações sensíveis desnecessárias.\n\nA carteirinha digital comunitária não garante, por si só, atendimento prioritário, benefício público, consulta, vaga em programa, desconto, gratuidade, reconhecimento oficial ou aceitação obrigatória por terceiros.\n\nA aceitação da carteirinha por parceiros, eventos, profissionais, estabelecimentos ou terceiros poderá depender de regras próprias, disponibilidade, critérios específicos e condições de cada ação comunitária.\n\nFuncionalidades futuras relacionadas à carteirinha, como validação sem conexão com a internet, registro de presença em eventos, confirmação de participação em programas, uso com parceiros, descontos ou emblemas de perfil, somente deverão ser consideradas parte desta Política quando forem efetivamente implementadas, disponibilizadas aos usuários e refletidas em atualização específica dos Termos de Uso e da Política de Privacidade.',
                    '7',
                  ),

                  _buildSectionBlock(
                    '8. Programas comunitários, Fada do Dente, Vidas e parceiros',
                    'A Família TEA Bauru poderá organizar, apoiar, divulgar ou intermediar programas comunitários, ações sociais, chamamentos, listas de interesse, inscrições, comunicação de selecionados e encaminhamentos iniciais por meio do ConeCTEA.\n\nEsses programas poderão incluir, entre outros, iniciativas como Fada do Dente, Vidas ou outros projetos futuros voltados ao apoio comunitário de famílias, pessoas autistas, pessoas neurodivergentes, crianças, adolescentes, dependentes e participantes cadastrados.\n\nO ConeCTEA poderá ser utilizado para inscrição em programas, formação de listas, controle de interessados, comunicação de aprovação ou seleção, envio de informações necessárias a parceiros participantes e, quando aplicável, agendamento da primeira consulta, primeiro atendimento, primeira avaliação, encontro inicial ou ação vinculada ao programa.\n\nA participação em programas comunitários poderá depender de disponibilidade de vagas, ordem de inscrição, critérios específicos da ação, capacidade de atendimento dos parceiros, análise da Família TEA Bauru, confirmação de dados e cumprimento das regras de cada programa.\n\nA inscrição em um programa pelo ConeCTEA não garante seleção, vaga, consulta, atendimento, custeio, continuidade de tratamento, retorno, acompanhamento permanente ou participação em futuras edições.\n\nQuando um programa envolver profissional parceiro, clínica, consultório, dentista, médico, terapeuta, psicólogo ou outro prestador habilitado, o ConeCTEA poderá atuar como ferramenta de organização, comunicação e primeiro encaminhamento, inclusive para auxiliar no agendamento inicial, quando essa funcionalidade estiver disponível.\n\nO atendimento realizado por profissional, clínica, consultório ou parceiro será de responsabilidade técnica, ética, legal e profissional do próprio prestador do serviço, conforme sua área de atuação, registro profissional, regras internas e legislação aplicável.\n\nA Família TEA Bauru poderá apoiar, custear, viabilizar ou organizar comunitariamente a primeira consulta, primeiro atendimento ou encaminhamento inicial em determinados programas. Essa atuação não transforma a Família TEA Bauru ou o ConeCTEA em clínica, consultório, plano de saúde, operadora de saúde, serviço médico, serviço odontológico, serviço terapêutico ou prestador direto de atendimento.\n\nApós a primeira consulta, primeiro atendimento, encaminhamento inicial ou ação comunitária prevista no programa, eventual continuidade de atendimento, retorno, tratamento, acompanhamento, pagamento, responsabilidade profissional ou nova consulta deverá ser tratada diretamente entre o participante, seus responsáveis quando aplicável, e o profissional, clínica ou parceiro responsável.\n\nQuando necessário para viabilizar o programa, os dados mínimos necessários do participante selecionado poderão ser compartilhados com o profissional, clínica ou parceiro participante, exclusivamente para fins de contato, organização, confirmação, agendamento e realização da ação vinculada ao programa.\n\nOs dados compartilhados com parceiros poderão incluir, conforme a necessidade da ação, informações como nome do participante, nome do responsável quando aplicável, telefone de contato, programa selecionado, data e horário de agendamento, observações necessárias para organização do atendimento inicial e demais dados estritamente necessários para execução da ação.\n\nO compartilhamento de dados com parceiros não deverá incluir documento com foto, laudo médico, CPF completo, CID, tipo sanguíneo ou informações sensíveis além do necessário, salvo quando houver necessidade específica, finalidade compatível, autorização adequada ou exigência relacionada à própria ação.\n\nProfissionais, clínicas, consultórios ou parceiros que receberem dados para execução de programa comunitário deverão utilizar essas informações apenas para a finalidade vinculada à ação, como contato, confirmação, agendamento, atendimento inicial ou organização do programa.\n\nO ConeCTEA poderá enviar notificações ou comunicações internas para informar inscrição realizada, seleção, aprovação, pendência, data de agendamento, alteração de horário, orientação do programa ou outras informações relevantes.\n\nAs notificações relacionadas a programas comunitários deverão evitar exposição de dados sensíveis, documentos, laudos, CID, CPF completo, motivo sensível ou informações excessivas sobre crianças, adolescentes, dependentes ou participantes.\n\nA Família TEA Bauru poderá alterar regras, critérios, prazos, quantidade de vagas, parceiros participantes, forma de inscrição, forma de seleção ou disponibilidade de programas conforme sua capacidade operacional, disponibilidade de parceiros, recursos existentes e necessidade da comunidade.\n\nO usuário reconhece que programas comunitários podem possuir regras próprias, limites de vagas, critérios de participação e condições específicas, que poderão ser comunicadas dentro del aplicativo ou pelos canais oficiais da Família TEA Bauru.',
                    '8',
                  ),

                  _buildSectionBlock(
                    '9. Compartilhamento de dados com parceiros',
                    'O ConeCTEA poderá compartilhar determinados dados pessoais com profissionais, clínicas, consultórios, parceiros, voluntários, apoiadores operacionais ou pessoas autorizadas quando esse compartilhamento for necessário para execução de programas comunitários, ações sociais, chamamentos, encaminhamentos iniciais, agendamentos, suporte, comunicação ou organização das atividades da Família TEA Bauru.\n\nO compartilhamento de dados deverá ocorrer apenas quando houver finalidade compatível com o ConeCTEA, necessidade real para a ação, vínculo com funcionalidade utilizada pelo usuário ou participação em programa comunitário.\n\nEm programas como Fada do Dente, Vidas ou iniciativas semelhantes, os dados mínimos necessários do participante selecionado poderão ser compartilhados com profissional, clínica, consultório ou parceiro participante para viabilizar contato, confirmação, agendamento inicial ou realização da ação vinculada ao programa.\n\nOs dados compartilhados poderão incluir, conforme a necessidade da ação, informações como nome do participante, nome do responsável quando aplicável, telefone de contato, programa selecionado, data e horário de agendamento, status da inscrição, confirmação de participação e observações estritamente necessárias para organização do atendimento inicial.\n\nO compartilhamento com parceiros não deverá incluir documento com foto, laudo médico, CPF completo, CID, tipo sanguíneo, TEA ID ou informações sensíveis além do necessário, salvo quando houver necessidade específica, finalidade compatível, autorização adequada, exigência relacionada à própria ação ou preenchimento de campos específicos pelo usuário.\n\nA Família TEA Bauru não vende dados pessoais de usuários, beneficiários, dependentes, crianças, adolescentes ou participantes cadastrados. Os dados são tratados como confidenciais e utilizados exclusivamente para os fins descritos nesta Política.\n\nProfissionais, clínicas, consultórios, parceiros ou pessoas autorizadas que receberem dados por meio do ConeCTEA deverão utilizar essas informações apenas para a finalidade vinculada à ação, como contato, confirmação, agendamento, atendimento inicial, organização comunitária ou execução do programa, comprometendo-se a respeitar o sigilo das informações e a proteção de dados.\n\nA Família TEA Bauru poderá suspender o compartilhamento de dados ou a parceria com terceiros quando houver indício de descumprimento das finalidades da ação, violação de privacidade, uso indevido de dados ou descumprimento das regras aplicáveis, sem prejuízo de outras medidas cabíveis.\n\nEm caso de dúvidas sobre o compartilhamento de dados com parceiros, o usuário poderá entrar em contato pelos canais oficiais da Família TEA Bauru indicados nesta Política.',
                    '9',
                  ),

                  _buildSectionBlock(
                    '10. Serviços técnicos utilizados pelo aplicativo',
                    'Para funcionar corretamente, o ConeCTEA poderá utilizar serviços técnicos, plataformas, ferramentas, integrações e infraestrutura de terceiros, necessários para cadastro, autenticação, banco de dados, armazenamento temporário, notificações, comunicação, suporte, segurança, análise administrativa e operação das funcionalidades do aplicativo.\n\nO ConeCTEA poderá utilizar serviços de banco de dados e autenticação, como Supabase ou tecnologia equivalente, para permitir criação de conta, acesso à conta, controle de sessão, armazenamento de dados cadastrais, solicitações, status da carteirinha, dados de dependentes, registros operacionais e demais informações necessárias ao funcionamento do aplicativo.\n\nO Supabase atua como infraestrutura técnica essencial para o aplicativo, e o tratamento de dados realizado nessa infraestrutura segue as diretrizes técnicas necessárias para o funcionamento seguro do ConeCTEA, conforme os limites de sua própria plataforma e segurança.\n\nO ConeCTEA poderá utilizar serviços de notificação, como OneSignal ou tecnologia equivalente, para envio de avisos, atualizações, comunicações internas, lembretes, notificações de solicitação, pendências, aprovações, recusas, programas comunitários, segurança e suporte.\n\nO ConeCTEA poderá utilizar Google Apps Script, Google Drive ou ferramentas equivalentes como apoio técnico e operacional para recebimento, organização temporária, análise, tratamento ou descarte de documentos e anexos vinculados a solicitações da carteirinha comunitária, programas comunitários ou suporte.\n\nEssas ferramentas atuam como recursos de suporte administrativo e conferência documental, e o uso de arquivos e links nessas plataformas deve ser restrito a pessoas autorizadas da Família TEA Bauru para as finalidades de análise documental descritas nesta Política.\n\nO ConeCTEA deverá evitar registrar em logs ou relatórios técnicos dados sensíveis desnecessários, como CPF completo, senha, credenciais de acesso, código QR bruto, laudo médico, documento com foto, CID, conteúdo integral de anexos, URLs completas de documentos, identificadores externos sensíveis ou payloads administrativos completos.\n\nLogs e relatórios técnicos devem ser gerados com finalidade operacional, depuração de erros, segurança e suporte, priorizando dados genéricos e técnicos em vez de informações pessoais sensíveis.\n\nA Família TEA Bauru não controla integralmente a infraestrutura, disponibilidade, políticas, atualizações, falhas, interrupções ou mudanças realizadas pelos serviços técnicos de terceiros utilizados no funcionamento do aplicativo. No entanto, a Família TEA Bauru buscará adotar práticas de configuração segura e conformidade técnica para proteção dos dados operados.',
                    '10',
                  ),

                  _buildSectionBlock(
                    '11. Notificações e comunicações',
                    'O ConeCTEA poderá enviar notificações, avisos, alertas, mensagens internas ou comunicações relacionadas ao uso do aplicativo, solicitações, carteirinha digital comunitária, programas comunitários, suporte, segurança, privacidade e ações da Família TEA Bauru.\n\nAs notificações poderão ser utilizadas para informar o usuário sobre atualizações de solicitação, pendências, aprovação, reprovação, suspensão, vencimento, renovação, necessidade de correção de dados, participação em programas comunitários, chamamentos, seleção, agendamento inicial, alterações de horário, avisos importantes ou outras comunicações relacionadas ao funcionamento do aplicativo.\n\nSempre que possível, notificações deverão evitar exposição de dados pessoais ou sensíveis. Informações como CPF completo, documento com foto, laudo médico, CID, diagnóstico, tipo sanguíneo, código QR, TEA ID associado a dados excessivos, motivo sensível de reprovação ou motivo sensível de suspensão não devem ser exibidas diretamente em notificações.\n\nAs notificações push e comunicações externas deverão atuar como alertas genéricos, orientando o usuário a acessar a conta autenticada no aplicativo ou entrar em contato pelos canais oficiais para consultar o detalhamento de informações delicadas.\n\nO usuário poderá gerenciar permissões de notificação nas configurações do dispositivo ou, quando disponível, nas configurações do próprio aplicativo. A desativação de notificações poderá prejudicar o acompanhamento tempestivo de solicitações, prazos e convocações dos programas comunitários.\n\nA ausência de recebimento de notificação, por falha de internet, configuração de dispositivo, suspensão de permissões pelo usuário, instabilidade de servidores ou erro técnico, não elimina a responsabilidade do usuário de acompanhar suas solicitações, carteirinha, programas e comunicações dentro do aplicativo ou pelos canais oficiais da Família TEA Bauru.',
                    '11',
                  ),

                  _buildSectionBlock(
                    '12. Armazenamento e segurança dos dados',
                    'Os dados tratados pelo ConeCTEA poderão ser armazenados em sistemas, bancos de dados, serviços de autenticação, ferramentas de notificação, serviços de apoio documental e demais infraestruturas técnicas necessárias ao funcionamento do aplicativo.\n\nO ConeCTEA poderá utilizar serviços como Supabase, Google Apps Script, Google Drive, OneSignal ou tecnologias equivalentes para cadastro, autenticação, armazenamento, organização de solicitações, apoio documental, envio de notificações, suporte, segurança e operação das funcionalidades disponíveis, de acordo com as regras de cada serviço.\n\nAs medidas de segurança poderão incluir controle de acesso, restrição de permissões, autenticação de usuários, organização por perfis autorizados, renomeação técnica de arquivos, limitação de exposição de dados em telas e notificações, redução de dados em logs, descarte de documentos sensíveis quando não forem mais necessários e outras práticas compatíveis com a infraestrutura disponível.\n\nO acesso aos dados deverá ser limitado às pessoas autorizadas, conforme a finalidade da informação e a necessidade de atuação, como equipe responsável pela organização da Família TEA Bauru, administradores autorizados, suporte, responsáveis por análise de solicitações e, quando aplicável, profissionais, clínicas ou parceiros envolvidos em programas comunitários específicos, sempre em respeito ao sigilo das informações.\n\nO usuário é responsável por manter a segurança de seus dados de acesso ao ConeCTEA, não devendo compartilhar senha, código de autenticação, acesso à conta ou credenciais com terceiros. A Família TEA Bauru não se responsabiliza por acessos não autorizados causados por descuido, facilitação, compartilhamento ou falha de segurança nos dispositivos do próprio usuário.\n\nNenhum sistema digital é totalmente imune a falhas, indisponibilidades, incidentes de segurança, acessos indevidos por terceiros mal-intencionados, problemas de rede ou falhas técnicas em infraestruturas integradas. A Família TEA Bauru deverá buscar adotar práticas razoáveis de segurança digital e configuração para proteção dos dados, mas o usuário declara estar ciente de que não existe segurança absoluta em ambiente digital.',
                    '12',
                  ),

                  _buildSectionBlock(
                    '13. Prazos de análise, retenção e descarte de documentos sensíveis',
                    'O ConeCTEA trata documentos com foto, laudos médicos e informações complementares como dados sensíveis ou de cuidado especial, mantendo esses dados apenas pelo tempo necessário para análise da solicitação, conferência documental, correção de pendências, revisão, segurança, prevenção de uso indevido e organização comunitária da Família TEA Bauru.\n\nQuando uma solicitação de carteirinha digital comunitária for enviada sem pendências aparentes, o prazo estimado de análise será de até 5 dias úteis, conforme a capacidade operacional da equipe responsável.\n\nCaso a solicitação apresente pendências, inconsistências, documento incorreto, laudo incompatível, dados divergentes ou necessidade de correção, a Família TEA Bauru poderá devolver a solicitação ao usuário para ajuste, complementação ou reenvio de informações. O prazo para correção de pendências poderá ser de 7, 15 ou 30 dias, conforme definido pela equipe responsável e informado ao usuário.\n\nQuando a carteirinha digital comunitária for aprovada pela equipe, o sistema dispara automaticamente o processo de exclusão dos documentos sensíveis utilizados para conferência, incluindo documento com foto e laudo médico. Após a aprovação e o descarte dos documentos sensíveis, a Família TEA Bauru deverá manter apenas os dados necessários para funcionamento da carteirinha comunitária, validação interna, histórico mínimo, segurança, organização administrativa e cumprimento das finalidades descritas nesta Política.\n\nCaso o prazo de suspensão (30 dias) termine sem correção, manifestação ou solicitação de revisão válida, o sistema deverá encerrar o fluxo e disparar automaticamente o processo de exclusão dos dados e documentos vinculados àquela solicitação ou carteirinha.\n\nEm caso de reprovação da solicitação, os dados sensíveis e documentos vinculados ao pedido reprovado deverão ser removidos do banco de dados operacional e do armazenamento utilizado pelo ConeCTEA, mantendo-se apenas o registro mínimo necessário do resultado da análise.',
                    '13',
                  ),

                  _buildSectionBlock(
                    '14. Exclusão de conta e remoção de dependentes',
                    'O ConeCTEA disponibiliza fluxo técnico para que o usuário realize a exclusão de sua conta diretamente pelo aplicativo, conforme a funcionalidade disponível. Por se tratar de uma ação sensível e potencialmente irreversível, a exclusão exige confirmação expressa do usuário, que poderá incluir etapas adicionais de segurança para confirmar sua identidade.\n\nAo confirmar a exclusão da conta, o usuário declara estar ciente de que seu acesso ao ConeCTEA será encerrado, sua sessão será deslogada e os dados vinculados à sua conta no banco de dados operacional do aplicativo serão apagados de forma permanente, observados os limites técnicos e operacionais.\n\nA exclusão de conta remove do banco de dados operacional do ConeCTEA dados cadastrais, informações de perfil, solicitações enviadas, histórico mínimo operacional, carteirinhas digitais comunitárias ativas ou em análise, dependentes associados, dados de contato e informações de consentimento vinculadas.\n\nA exclusão de conta ou remoção de dependente não desfaz automaticamente comunicações externas já realizadas pelo usuário, e-mails ou mensagens enviadas aos canais oficiais, relatórios estatísticos já consolidados de forma generalizada, registros necessários para auditoria mínima de segurança, prevenção de fraudes, cumprimento de obrigações legais, defesa de direitos em processos ou dados que tenham sido legitimamente compartilhados com profissionais, clínicas ou parceiros antes do pedido de exclusão.',
                    '14',
                  ),

                  _buildSectionBlock(
                    '15. Correção e atualização de dados',
                    'O usuário poderá realizar a correção e atualização de seus dados cadastrais e, quando aplicável, dos dados de dependentes vinculados à sua conta diretamente pelo ConeCTEA, conforme as funcionalidades disponíveis no aplicativo, o tipo de dado envolvido e as regras de segurança aplicáveis.\n\nDados simples de cadastro, contato ou perfil poderão ser corrigidos ou atualizados pelo próprio usuário dentro do aplicativo, conforme os recursos disponíveis no ConeCTEA.\n\nAlguns dados protegidos ou sensíveis, como CPF, e-mail de acesso, documentos, laudos, CID, dados vinculados à carteirinha comunitária, informações de solicitação, status, responsáveis e dados que impactem análise administrativa, poderão exigir fluxo específico dentro do aplicativo, conferência, justificativa, nova análise ou validação pela equipe autorizada da Família TEA Bauru.',
                    '15',
                  ),

                  _buildSectionBlock(
                    '16. Direitos do usuário sobre seus dados',
                    'Em conformidade com a Lei Geral de Proteção de Dados Pessoais (LGPD — Lei nº 13.709/2018), o usuário poderá solicitar informações, orientações, correções, atualizações, exclusão ou esclarecimentos relacionados aos seus dados pessoais tratados pelo ConeCTEA.\n\nO usuário poderá:\n• Confirmar o tratamento dos seus dados pessoais;\n• Acessar os dados mantidos pelo ConeCTEA;\n• Corrigir dados incompletos, inexatos ou desatualizados;\n• Solicitar a exclusão de dados tratados com base em consentimento;\n• Revogar o consentimento a qualquer momento, sem prejuízo de tratamentos anteriores;\n• Obter informações sobre compartilhamento com terceiros;\n• Solicitar portabilidade, quando aplicável.\n\nA revogação de consentimento ou a recusa em fornecer determinados dados poderá limitar ou impedir o uso de funcionalidades que dependam dessas informações.\n\nSolicitações relacionadas a dados de crianças, adolescentes, dependentes ou pessoas vinculadas à conta poderão exigir confirmação de legitimidade, vínculo, autorização ou responsabilidade adequada do usuário solicitante.\n\nPara exercer seus direitos, o usuário poderá utilizar os recursos disponíveis no próprio aplicativo ou entrar em contato pelos canais oficiais:\nE-mail: familiateabauru@gmail.com\nWhatsApp: +55 14 99101-2961',
                    '16',
                  ),

                  _buildSectionBlock(
                    '17. Alterações desta Política de Privacidade',
                    'A Família TEA Bauru poderá atualizar, revisar, complementar ou alterar esta Política de Privacidade sempre que necessário para refletir mudanças no ConeCTEA, novas funcionalidades, ajustes de segurança, alterações em fluxos de dados, programas comunitários, serviços técnicos utilizados, exigências legais, exigências de plataformas de publicação ou necessidades operacionais da comunidade.\n\nSempre que houver alteração relevante, a Família TEA Bauru poderá comunicar os usuários por meio do próprio aplicativo, notificações, e-mail, WhatsApp, Instagram, grupo comunitário ou outros canais oficiais, quando possível e adequado.\n\nO uso contínuo do ConeCTEA após a disponibilização de nova versão desta Política poderá ser interpretado como ciência das condições atualizadas, salvo quando a legislação aplicável, a natureza da mudança ou a funcionalidade envolvida exigir consentimento específico, novo aceite ou confirmação adicional do usuário.\n\nCaso o usuário não concorde com alguma alteração desta Política, poderá interromper o uso do ConeCTEA, solicitar esclarecimentos pelos canais oficiais ou, quando aplicável, utilizar os recursos disponíveis no aplicativo para exclusão de conta, remoção de dependentes ou ajuste de consentimentos.',
                    '17',
                  ),

                  _buildSectionBlock(
                    '18. Contato sobre privacidade e proteção de dados',
                    'Em caso de dúvidas, solicitações, orientações, correções, exclusão de conta, remoção de dependentes, informações sobre dados pessoais, documentos, laudos, programas comunitários, compartilhamento de dados ou qualquer assunto relacionado à privacidade no ConeCTEA, o usuário poderá entrar em contato pelos canais oficiais da Família TEA Bauru:\n\nE-mail principal: familiateabauru@gmail.com\nWhatsApp oficial: +55 14 99101-2961 — Renata Ferreguti\nGrupo comunitário: https://chat.whatsapp.com/Hhl4SmcahMZ3DX8GEkpQ6s?mode=ac_t\nInstagram: https://www.instagram.com/familiateabauru/\nE-mail secundário: conecteabauru@gmail.com\nSite oficial: em breve\n\nPara fins de atendimento a solicitações relacionadas à LGPD, privacidade e proteção de dados pessoais no contexto do ConeCTEA, Renata Ferreguti, representante/presidente da Família TEA Bauru, atuará como canal direto de comunicação entre o usuário, o aplicativo ConeCTEA e a comunidade Família TEA Bauru.\n\nPara assuntos sensíveis, como dados pessoais, documentos, laudos, CPF, e-mail, dependentes, crianças, adolescentes, exclusão de conta, remoção de dependente, correção de dados ou privacidade, recomenda-se utilizar preferencialmente o e-mail principal ou o WhatsApp oficial.\n\nEsta Política de Privacidade deve ser interpretada em conjunto com os Termos de Uso do ConeCTEA, com as informações exibidas dentro do aplicativo e com os avisos específicos apresentados em cada funcionalidade.',
                    '18',
                  ),

                  const SizedBox(height: 12),
                  _buildVersionCard('1.0', '21/05/2026'),
                  const SizedBox(height: 32),

                  _buildAwareButton(context),
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
            'Esta Política de Privacidade explica como o ConeCTEA poderá coletar, utilizar, armazenar, proteger, compartilhar, corrigir e excluir dados pessoais relacionados aos usuários, participantes cadastrados, dependentes, responsáveis, familiares e demais pessoas vinculadas ao uso do aplicativo.\n\nO ConeCTEA é um aplicativo social, comunitário, organizacional e informativo vinculado à Família TEA Bauru, comunidade e rede de apoio formada por familiares, mães, responsáveis, voluntários, profissionais, parceiros e pessoas comprometidas com inclusão real, respeito e acolhimento.\n\nA Família TEA Bauru não deve ser interpretada, apenas pelo uso do ConeCTEA ou pela existência desta Política, como empresa, órgão público, entidade governamental, serviço público, clínica, consultório, operadora de saúde, entidade médica ou entidade formal equivalente, salvo se houver formalização futura expressamente informada por seus canais oficiais.\n\nO ConeCTEA poderá tratar dados pessoais para permitir cadastro, acesso à conta, solicitação e acompanhamento da carteirinha digital comunitária, participação em programas comunitários, comunicação com usuários, notificações, suporte, organização administrativa, segurança e funcionamento do aplicativo.\n\nA carteirinha digital comunitária ConeCTEA possui finalidade interna, comunitária e organizacional. Ela não é documento oficial e não substitui CIPTEA, RG, CPF, CNH, laudo médico, diagnóstico, documento civil, documento oficial ou qualquer documento emitido pelo Poder Público.\n\nO ConeCTEA não é aplicativo médico, não realiza diagnóstico, não realiza avaliação clínica, não prescreve tratamento, não define conduta médica, odontológica, terapêutica ou profissional e não substitui atendimento realizado por profissional habilitado.\n\nAo criar conta, acessar ou utilizar o ConeCTEA, o usuário declara estar ciente de que seus dados poderão ser tratados conforme esta Política de Privacidade e conforme os Termos de Uso aplicáveis.',
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

  Widget _buildAwareButton(BuildContext context) {
    return SizedBox(
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
            'ESTOU CIENTE',
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
