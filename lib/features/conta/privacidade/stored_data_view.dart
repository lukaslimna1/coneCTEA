import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de Dados Armazenados dentro de Privacidade e Dados.
///
/// Apresenta o design e a estrutura de quais informações podem estar
/// vinculadas à conta do usuário no ConeCTEA, em conformidade com as
/// diretrizes visuais e semânticas da LGPD.
class StoredDataView extends StatelessWidget {
  const StoredDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsBotaoVoltar(
                      onPressed: () => Navigator.pop(context),
                      token: DsCores.privacidade,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Dados armazenados',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veja quais tipos de informações podem estar vinculadas à sua conta no ConeCTEA.',
                      style: DsTipografia.pageSubtitle.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bloco Introdutório — Sobre esta área
                    _buildAboutSection(context),
                    const SizedBox(height: 32),

                    // Seção de cards informativos
                    Text(
                      'CATEGORIAS DE DADOS',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.privacidade.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1 — Dados da conta
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.user,
                      title: 'Dados da conta',
                      description:
                          'Informações usadas para identificar sua conta e permitir o acesso ao app.',
                      items: [
                        'Nome completo',
                        'E-mail de acesso',
                        'Telefone/celular informado',
                        'Data de nascimento',
                        'Cidade e estado',
                        'CPF usado para identificação cadastral',
                        'Senha protegida pelo sistema de autenticação',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Dados opcionais do cadastro
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.pencilSimple,
                      title: 'Dados opcionais do cadastro',
                      description:
                          'Informações complementares que podem ajudar na identificação, organização comunitária e compreensão do público atendido.',
                      items: [
                        'Nome social, quando informado',
                        'Gênero, quando informado',
                        'Raça/cor, quando informado',
                        'Indicação por instituição, comunidade, grupo, parceiro ou pessoa',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Dependentes e pessoas vinculadas
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.users,
                      title: 'Dependentes e pessoas vinculadas',
                      description:
                          'Informações relacionadas a dependentes, crianças, adolescentes, familiares ou pessoas vinculadas à sua conta.',
                      items: [
                        'Dados cadastrais do dependente',
                        'Informações de vínculo com o responsável',
                        'Dados do responsável pela conta',
                        'Contato de emergência, quando informado',
                        'Informações necessárias para solicitações e programas',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Carteirinhas comunitárias
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinhas comunitárias',
                      description:
                          'Informações usadas para solicitar, analisar, emitir, validar e acompanhar a carteirinha comunitária ConeCTEA.',
                      items: [
                        'Solicitações realizadas',
                        'Status da análise',
                        'Data de validade da carteirinha',
                        'TEA ID',
                        'Código QR de validação interna',
                        'Motivos de pendência, recusa ou suspensão, quando houver',
                        'Histórico administrativo necessário',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Documentos e laudos
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Documentos e laudos',
                      description:
                          'Documentos usados somente quando necessários para conferência administrativa da solicitação.',
                      items: [
                        'Documento com foto',
                        'Laudo médico ou documento equivalente',
                        'Comprovantes solicitados na análise',
                        'Arquivos renomeados tecnicamente pelo sistema',
                        'Documentos descartados conforme as regras de aprovação, reprovação, pendência ou suspensão',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 6 — Programas comunitários
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.calendarHeart,
                      title: 'Programas comunitários',
                      description:
                          'Informações usadas para inscrição, organização, seleção e encaminhamento inicial em ações da Família TEA Bauru.',
                      items: [
                        'Inscrições em chamamentos',
                        'Listas de interesse',
                        'Status de seleção ou aprovação',
                        'Dados necessários para contato',
                        'Agendamento inicial, quando houver',
                        'Programa relacionado, como Fada do Dente, Vidas ou outras ações futuras',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 7 — Dados compartilhados com parceiros (com nota de rodapé)
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.handshake,
                      title: 'Dados compartilhados com parceiros',
                      description:
                          'Quando necessário, alguns dados mínimos podem ser compartilhados com profissionais, clínicas ou parceiros participantes de programas comunitários.',
                      items: [
                        'Nome do participante',
                        'Nome do responsável, quando aplicável',
                        'Telefone de contato',
                        'Programa selecionado',
                        'Data e horário de agendamento',
                        'Informações mínimas necessárias para organização da ação',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Como regra, documento com foto, laudo, CPF completo, CID e dados sensíveis não fazem parte do compartilhamento mínimo com parceiros.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 8 — Notificações e comunicações
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.bell,
                      title: 'Notificações e comunicações',
                      description:
                          'Informações usadas para enviar avisos importantes sobre conta, solicitações, carteirinha e programas.',
                      items: [
                        'Notificações enviadas ao dispositivo',
                        'Avisos de pendência',
                        'Avisos de aprovação ou recusa',
                        'Lembretes de programas ou agendamentos',
                        'Mensagens de suporte e orientação',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 9 — Registros técnicos e segurança
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.shieldCheck,
                      title: 'Registros técnicos e segurança',
                      description:
                          'Registros mínimos podem existir para segurança, funcionamento, prevenção de falhas e suporte técnico.',
                      items: [
                        'Identificadores internos de usuário',
                        'Registros de sessão',
                        'Data e horário de ações relevantes',
                        'Identificadores de notificação',
                        'Registros técnicos mínimos de erro ou estabilidade',
                        'Informações básicas necessárias ao funcionamento do app',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 10 — Dados estatísticos
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.chartBar,
                      title: 'Dados estatísticos',
                      description:
                          'Alguns dados podem ser usados de forma agrupada para relatórios comunitários, sem identificar pessoas individualmente.',
                      items: [
                        'Quantidade geral de usuários cadastrados',
                        'Quantidade de carteirinhas solicitadas ou ativas',
                        'Cidades atendidas de forma geral',
                        'Faixas etárias agrupadas',
                        'Participação em programas comunitários',
                        'Indicadores de impacto social',
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Bloco final de orientação — Importante
                    _buildWarningCard(context),
                    const SizedBox(height: 32),

                    // Botão de ação do final da tela
                    DsBotao(
                      label: 'Solicitar informações',
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Solicitação visual em construção.',
                      ),
                      variante: DsBotaoVariante.acao,
                      token: DsCores.privacidade,
                      icon: PhosphorIconsRegular.envelope,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe um SnackBar mockado flutuante.
  void _showMockSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
        ),
        backgroundColor: DsCores.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Construtor do Bloco Introdutório "Sobre esta área".
  Widget _buildAboutSection(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.info,
                accentColor: DsCores.privacidade.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sobre esta área',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA pode armazenar dados necessários para cadastro, segurança da conta, solicitações, carteirinhas comunitárias, dependentes, programas comunitários e suporte. Nem todos os dados aparecem em todos os casos: isso depende das funcionalidades usadas por você.',
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
          ),
        ],
      ),
    );
  }

  /// Construtor de card de categoria de dados Dark Glass.
  Widget _buildDataCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> items,
    Widget? extraWidget,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: icon,
                accentColor: DsCores.privacidade.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Divisor sutil
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 16),
          // Itens visuais listados
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: DsCores.privacidade.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: DsTipografia.bodySmall.copyWith(
                          color: DsCores.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          ?extraWidget,
        ],
      ),
    );
  }

  /// Construtor de Card de Orientação Importante.
  Widget _buildWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DsCores.alerta.softBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DsRaios.lg),
        border: Border.all(color: DsCores.alerta.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.warning,
                accentColor: DsCores.alerta.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Importante',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA não vende dados pessoais. Documentos sensíveis, como documento com foto e laudo médico, são tratados com cuidado especial e seguem regras próprias de retenção e descarte.',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
