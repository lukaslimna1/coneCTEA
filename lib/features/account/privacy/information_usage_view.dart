import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de Uso das Informações dentro de Privacidade e Dados.
///
/// Apresenta de forma simples e intuitiva as finalidades para as quais os dados
/// coletados podem ser tratados dentro do ecossistema do ConeCTEA.
class InformationUsageView extends StatelessWidget {
  const InformationUsageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          children: [
            const MyDataLoggedHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsBotaoVoltar(
                      onPressed: () => Navigator.pop(context),
                      token: DsCores.privacidade,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Uso das informações',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entenda, de forma simples, para que as informações podem ser usadas no ConeCTEA.',
                      style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Bloco Introdutório — Sobre esta área
                    _buildAboutSection(context),
                    const SizedBox(height: 32),

                    // Seção de cards informativos
                    Text(
                      'COMO USAMOS SEUS DADOS',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.privacidade.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1 — Funcionamento da conta
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.userCircle,
                      title: 'Funcionamento da conta',
                      description: 'Usamos algumas informações para criar, proteger e manter sua conta no app.',
                      items: [
                        'Cadastro no ConeCTEA',
                        'Acesso à conta',
                        'Identificação do usuário',
                        'Recuperação de acesso',
                        'Prevenção de cadastros duplicados',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Segurança e proteção
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.shieldCheck,
                      title: 'Segurança e proteção',
                      description: 'Alguns dados ajudam a proteger sua conta, evitar uso indevido e manter o app mais seguro.',
                      items: [
                        'Proteção de acesso',
                        'Prevenção de fraude',
                        'Verificações administrativas',
                        'Registros mínimos de segurança',
                        'Controle de uso indevido',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Carteirinha comunitária
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinha comunitária',
                      description: 'As informações podem ser usadas para solicitar, analisar, emitir, validar e acompanhar a carteirinha comunitária.',
                      items: [
                        'Solicitação da carteirinha',
                        'Análise administrativa',
                        'Status da solicitação',
                        'Validade da carteirinha',
                        'TEA ID e código QR interno',
                        'Renovação, suspensão ou reprovação, quando houver',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Dependentes e responsáveis
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.users,
                      title: 'Dependentes e responsáveis',
                      description: 'Dados de dependentes podem ser usados para organizar vínculos, solicitações e comunicações com o responsável pela conta.',
                      items: [
                        'Vínculo com responsável',
                        'Dados cadastrais do dependente',
                        'Solicitações vinculadas',
                        'Correções solicitadas',
                        'Comunicação com o responsável',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Documentos e análise administrativa
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Documentos e análise administrativa',
                      description: 'Documentos podem ser usados somente quando necessários para conferência administrativa da solicitação.',
                      items: [
                        'Conferência de dados informados',
                        'Análise da solicitação',
                        'Correção de pendências',
                        'Prevenção de uso indevido',
                        'Descarte conforme regras de privacidade',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 6 — Programas comunitários
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.calendarHeart,
                      title: 'Programas comunitários',
                      description: 'As informações podem apoiar inscrições, seleção, comunicação e primeiro encaminhamento em programas da Família TEA Bauru.',
                      items: [
                        'Inscrição em chamamentos',
                        'Lista de interesse',
                        'Comunicação de seleção',
                        'Agendamento inicial, quando houver',
                        'Programas como Fada do Dente, Vidas ou futuras ações',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 7 — Comunicação e suporte
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.chatCircleText,
                      title: 'Comunicação e suporte',
                      description: 'Algumas informações ajudam a enviar avisos importantes e oferecer suporte ao usuário.',
                      items: [
                        'Notificações do app',
                        'Avisos de pendência',
                        'Orientações sobre solicitações',
                        'Mensagens de suporte',
                        'Comunicados importantes da Família TEA Bauru',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 8 — Compartilhamento mínimo com parceiros
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.handshake,
                      title: 'Compartilhamento mínimo com parceiros',
                      description: 'Quando necessário para um programa comunitário, dados mínimos podem ser compartilhados com profissionais, clínicas ou parceiros participantes.',
                      items: [
                        'Nome do participante',
                        'Nome do responsável, quando aplicável',
                        'Telefone de contato',
                        'Programa selecionado',
                        'Data e horário de agendamento',
                        'Informações mínimas para organizar a ação',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'O ConeCTEA não vende dados pessoais. O compartilhamento com parceiros deve ocorrer apenas quando necessário para organizar ações comunitárias.',
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

                    // Card 9 — Relatórios comunitários
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.chartBar,
                      title: 'Relatórios comunitários',
                      description: 'Algumas informações podem ser usadas de forma agrupada para melhorar ações e buscar apoio para a comunidade.',
                      items: [
                        'Quantidade geral de usuários',
                        'Quantidade de carteirinhas solicitadas ou ativas',
                        'Cidades atendidas de forma geral',
                        'Faixas etárias agrupadas',
                        'Participação em programas',
                        'Indicadores de impacto social',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'As informações são usadas de forma agrupada, sem identificar pessoas individualmente.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bloco final de orientação — Importante
                    _buildWarningCard(context),
                    const SizedBox(height: 32),

                    // Ação visual no final
                    DsBotao(
                      label: 'Entendi',
                      onPressed: () => _showMockSnackBar(context, 'Informação visual em construção.'),
                      variante: DsBotaoVariante.acao,
                      token: DsCores.privacidade,
                      icon: PhosphorIconsRegular.check,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                  style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'As informações cadastradas no ConeCTEA são usadas para manter o app funcionando, organizar solicitações, proteger dados, apoiar a carteirinha comunitária, enviar comunicações importantes e viabilizar programas da Família TEA Bauru.',
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
          ),
        ],
      ),
    );
  }

  /// Construtor de card de categoria de uso de dados Dark Glass.
  Widget _buildUsageCategoryCard(
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
                  style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
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
                  style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA não vende dados pessoais. Informações sensíveis devem ser usadas apenas quando necessárias, com finalidade definida e cuidado especial. A carteirinha comunitária não é documento oficial e o app não realiza diagnóstico.',
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
