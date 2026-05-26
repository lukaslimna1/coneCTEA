import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/conta/perfil/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de Consentimentos com Switches operacionais.
///
/// Apresenta o design e a estrutura de chaves de ativar/desativar para consentimentos
/// essenciais (bloqueados e ativos por padrão) e opcionais (interativos localmente).
class ConsentsView extends StatefulWidget {
  const ConsentsView({super.key});

  @override
  State<ConsentsView> createState() => _ConsentsViewState();
}

class _ConsentsViewState extends State<ConsentsView> {
  // Estado local para chaves opcionais (Cards 6 a 10)
  bool _programasComunitarios = true;
  bool _comunicacaoAvisos = true;
  bool _parceirosAcoes = false;
  bool _relatoriosComunitarios = true;
  bool _notificacoesDispositivo = true;

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
                      'Consentimentos e autorizações',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie autorizações importantes relacionadas ao uso dos seus dados no ConeCTEA.',
                      style: DsTipografia.pageSubtitle.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bloco Introdutório — Sobre esta área
                    _buildAboutSection(context),
                    const SizedBox(height: 32),

                    // SEÇÃO 1 — Necessários para uso do app
                    Text(
                      'NECESSÁRIOS PARA USO DO APP',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.privacidade.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Esses usos são necessários para manter sua conta, proteger seus dados e permitir funcionalidades básicas do ConeCTEA. Por isso, ficam sempre ativos enquanto você utilizar o app.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1 — Conta e acesso
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.userCircle,
                      title: 'Conta e acesso',
                      description:
                          'Necessário para criar conta, acessar o app, manter seu cadastro e proteger sua sessão.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Sempre ativo',
                      statusColor: DsCores.sucesso,
                      items: [
                        'Cadastro no ConeCTEA',
                        'Acesso à conta',
                        'Segurança da sessão',
                        'Recuperação de acesso',
                        'Prevenção de cadastro duplicado',
                      ],
                      onChanged: null,
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Segurança e proteção de dados
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.shieldCheck,
                      title: 'Segurança e proteção de dados',
                      description:
                          'Necessário para proteger sua conta, evitar uso indevido e manter registros mínimos de segurança.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Sempre ativo',
                      statusColor: DsCores.sucesso,
                      items: [
                        'Proteção contra uso indevido',
                        'Registros mínimos de segurança',
                        'Verificações administrativas',
                        'Prevenção de fraude',
                        'Suporte em caso de problema',
                      ],
                      onChanged: null,
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Carteirinha comunitária
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinha comunitária',
                      description:
                          'Necessário quando você solicita, acompanha ou utiliza a carteirinha comunitária ConeCTEA.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Obrigatório para carteirinha',
                      statusColor: DsCores.sucesso,
                      items: [
                        'Solicitação da carteirinha',
                        'Análise administrativa',
                        'Status da solicitação',
                        'Validade da carteirinha',
                        'TEA ID e código QR interno',
                      ],
                      onChanged: null,
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Dependentes e pessoas vinculadas
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.users,
                      title: 'Dependentes e pessoas vinculadas',
                      description:
                          'Necessário quando houver dependentes, crianças, adolescentes ou pessoas vinculadas à sua conta.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Essencial quando aplicável',
                      statusColor: DsCores.privacidade,
                      items: [
                        'Vínculo com responsável',
                        'Dados cadastrais do dependente',
                        'Solicitações vinculadas',
                        'Comunicação com o responsável',
                        'Proteção de dados de crianças e adolescentes',
                      ],
                      onChanged: null,
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Documentos e laudos
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Documentos e laudos',
                      description:
                          'Necessário quando documentos forem enviados para conferência administrativa da solicitação.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Necessário quando enviado',
                      statusColor: DsCores.privacidade,
                      items: [
                        'Documento com foto',
                        'Laudo médico ou documento equivalente',
                        'Conferência administrativa',
                        'Correção de pendências',
                        'Descarte conforme a Política de Privacidade',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Importante: o ConeCTEA não realiza diagnóstico e não usa esses documentos como validação médica própria.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      onChanged: null,
                    ),
                    const SizedBox(height: 32),

                    // SEÇÃO 2 — Autorizações ajustáveis
                    Text(
                      'AUTORIZAÇÕES AJUSTÁVEIS',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.privacidade.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Essas autorizações podem ser alteradas. Ao desativar alguma opção, certas comunicações, programas, ações com parceiros ou benefícios comunitários podem ficar limitados ou indisponíveis.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 6 — Programas comunitários
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.calendarHeart,
                      title: 'Programas comunitários',
                      description:
                          'Permite usar seus dados para inscrição, seleção, comunicação e organização de programas da Família TEA Bauru.',
                      value: _programasComunitarios,
                      isEssential: false,
                      statusLabel: _programasComunitarios
                          ? 'Ativo'
                          : 'Desativado',
                      statusColor: _programasComunitarios
                          ? DsCores.sucesso
                          : DsCores.alerta,
                      items: [
                        'Chamamentos',
                        'Listas de interesse',
                        'Seleção de participantes',
                        'Comunicação de aprovação',
                        'Agendamento inicial, quando houver',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Ao desativar, você poderá não participar de alguns programas pelo app.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _programasComunitarios = newValue;
                        });
                        _showMockSnackBar(
                          context,
                          'Configuração visual em construção.',
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 7 — Comunicação e avisos
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.chatCircleText,
                      title: 'Comunicação e avisos',
                      description:
                          'Permite receber avisos, orientações e comunicados comunitários pelos canais disponíveis.',
                      value: _comunicacaoAvisos,
                      isEssential: false,
                      statusLabel: _comunicacaoAvisos ? 'Ativo' : 'Desativado',
                      statusColor: _comunicacaoAvisos
                          ? DsCores.sucesso
                          : DsCores.alerta,
                      items: [
                        'Avisos sobre programas',
                        'Comunicados da Família TEA Bauru',
                        'Orientações gerais',
                        'Lembretes não obrigatórios',
                        'Informações comunitárias',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Avisos essenciais sobre conta, segurança, solicitação ou carteirinha ainda poderão ser enviados quando necessários.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _comunicacaoAvisos = newValue;
                        });
                        _showMockSnackBar(
                          context,
                          'Configuração visual em construção.',
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 8 — Parceiros e ações externas
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.handshake,
                      title: 'Parceiros e ações externas',
                      description:
                          'Permite o compartilhamento mínimo de dados com parceiros quando você participar de ações ou programas comunitários específicos.',
                      value: _parceirosAcoes,
                      isEssential: false,
                      statusLabel: _parceirosAcoes ? 'Ativo' : 'Desativado',
                      statusColor: _parceirosAcoes
                          ? DsCores.sucesso
                          : DsCores.alerta,
                      items: [
                        'Profissionais parceiros',
                        'Clínicas ou consultórios participantes',
                        'Agendamento inicial',
                        'Confirmação de participação',
                        'Organização da ação comunitária',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'O compartilhamento deve ser limitado ao necessário para a ação. Documentos, laudos, CPF completo e dados sensíveis não devem ser compartilhados como regra.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _parceirosAcoes = newValue;
                        });
                        _showMockSnackBar(
                          context,
                          'Configuração visual em construção.',
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 9 — Relatórios comunitários
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.chartBar,
                      title: 'Relatórios comunitários',
                      description:
                          'Permite o uso de informações de forma agrupada para relatórios, planejamento e busca de apoio para a comunidade.',
                      value: _relatoriosComunitarios,
                      isEssential: false,
                      statusLabel: _relatoriosComunitarios
                          ? 'Ativo'
                          : 'Desativado',
                      statusColor: _relatoriosComunitarios
                          ? DsCores.sucesso
                          : DsCores.alerta,
                      items: [
                        'Quantidade geral de usuários',
                        'Carteirinhas solicitadas ou ativas',
                        'Cidades atendidas de forma geral',
                        'Faixas etárias agrupadas',
                        'Indicadores de impacto social',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Esses relatórios não devem identificar pessoas individualmente.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _relatoriosComunitarios = newValue;
                        });
                        _showMockSnackBar(
                          context,
                          'Configuração visual em construção.',
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 10 — Notificações no dispositivo
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.bell,
                      title: 'Notificações no dispositivo',
                      description:
                          'Permite receber notificações no dispositivo sobre atualizações importantes do app.',
                      value: _notificacoesDispositivo,
                      isEssential: false,
                      statusLabel: _notificacoesDispositivo
                          ? 'Ativo'
                          : 'Desativado',
                      statusColor: _notificacoesDispositivo
                          ? DsCores.sucesso
                          : DsCores.alerta,
                      items: [
                        'Atualizações de solicitação',
                        'Pendências',
                        'Aprovação ou recusa',
                        'Agendamentos iniciais',
                        'Avisos importantes',
                      ],
                      extraWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Notificações devem evitar dados sensíveis. Detalhes importantes devem ser consultados dentro do app.',
                            style: DsTipografia.caption.copyWith(
                              color: DsCores.textMuted,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _notificacoesDispositivo = newValue;
                        });
                        _showMockSnackBar(
                          context,
                          'Configuração visual em construção.',
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Bloco O que acontece ao desativar uma autorização?
                    _buildWhatHappensCard(context),
                    const SizedBox(height: 16),

                    // Bloco final de orientação — Importante
                    _buildWarningCard(context),
                    const SizedBox(height: 32),

                    // Botão de ação do final da tela
                    DsBotao(
                      label: 'Entendi',
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Informação visual em construção.',
                      ),
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
            'Algumas informações são necessárias para o funcionamento do app, segurança da conta, carteirinha comunitária e solicitações. Outras autorizações podem ser ajustadas conforme sua participação em programas, comunicações e ações comunitárias.',
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
          ),
        ],
      ),
    );
  }

  /// Construtor de card de consentimento com Switch e lista de itens.
  Widget _buildConsentSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required bool isEssential,
    String? statusLabel,
    DsCorVisual? statusColor,
    required List<String> items,
    Widget? extraWidget,
    required ValueChanged<bool>? onChanged,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsMolduraIcone(
                icon: icon,
                accentColor: DsCores.privacidade.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DsTipografia.cardTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    if (statusLabel != null && statusColor != null) ...[
                      const SizedBox(height: 6),
                      // Selo/Badge de status visual discreto
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.softBackground,
                          borderRadius: BorderRadius.circular(DsRaios.sm),
                          border: Border.all(color: statusColor.border),
                        ),
                        child: Text(
                          statusLabel,
                          style: DsTipografia.caption.copyWith(
                            color: statusColor.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Switch visual premium customizado da DS V2
              DsSwitch(
                value: value,
                onChanged: isEssential ? null : (v) => onChanged?.call(v),
                token: DsCores.privacidade,
                enabled: !isEssential,
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
          // Itens listados com bullets
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

  /// Construtor do Bloco "O que acontece ao desativar uma autorização?"
  Widget _buildWhatHappensCard(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.question,
                accentColor: DsCores.privacidade.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'O que acontece ao desativar uma autorização?',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Algumas funcionalidades podem ficar limitadas, como participação em programas, recebimento de avisos opcionais ou encaminhamentos com parceiros. Dados necessários para conta, segurança, solicitações, carteirinha e cumprimento de regras do app poderão continuar sendo tratados enquanto forem necessários.',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textPrimary,
              height: 1.4,
            ),
          ),
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
            'O ConeCTEA não vende dados pessoais. Dados sensíveis, documentos, laudos e informações de dependentes devem ser tratados com cuidado especial, conforme a Política de Privacidade. A carteirinha comunitária não é documento oficial e o app não realiza diagnóstico.',
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
