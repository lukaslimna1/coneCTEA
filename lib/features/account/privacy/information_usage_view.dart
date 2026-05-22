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
                      'Entenda, de forma simples, para que as informações podem ser usadas no app.',
                      style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Card 1 — Funcionamento da conta
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.userCircle,
                      title: 'Funcionamento da conta',
                      description: 'Informações podem ser usadas para manter cadastro, acesso e recursos básicos do app.',
                      items: [
                        'Cadastro',
                        'Login',
                        'Dados da conta',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Carteirinha comunitária
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinha comunitária',
                      description: 'Alguns dados podem apoiar a solicitação, análise e manutenção da carteirinha comunitária.',
                      items: [
                        'Solicitação',
                        'Análise administrativa',
                        'Validade da carteirinha',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Dependentes
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.usersThree,
                      title: 'Dependentes',
                      description: 'Informações de dependentes podem ser usadas para organizar vínculos e dados cadastrais.',
                      items: [
                        'Vínculo com responsável',
                        'Dados cadastrais',
                        'Correções solicitadas',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Comunicação e suporte
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.chatCircleText,
                      title: 'Comunicação e suporte',
                      description: 'Algumas informações podem ajudar no atendimento, suporte e envio de avisos importantes.',
                      items: [
                        'Notificações',
                        'Atendimento',
                        'Orientações',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Segurança e auditoria
                    _buildUsageCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.shieldCheck,
                      title: 'Segurança e auditoria',
                      description: 'Registros mínimos podem ser usados para proteger o app e apoiar verificações administrativas.',
                      items: [
                        'Segurança',
                        'Auditoria',
                        'Prevenção de uso indevido',
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Ação visual no final
                    DsBotao(
                      label: 'Entendi',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Informação visual em construção.',
                              style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
                            ),
                            backgroundColor: DsCores.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
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

  /// Construtor de card de categoria de uso de dados Dark Glass.
  Widget _buildUsageCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> items,
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
        ],
      ),
    );
  }
}
