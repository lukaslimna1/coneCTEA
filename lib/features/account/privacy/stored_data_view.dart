import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
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
                      'Dados armazenados',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veja quais tipos de informações podem estar vinculadas à sua conta.',
                      style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Card 1 — Dados da conta
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.user,
                      title: 'Dados da conta',
                      description: 'Informações usadas para identificar e manter sua conta no app.',
                      items: [
                        'Nome completo do titular da conta',
                        'Endereço de e-mail de acesso',
                        'Número de telefone/celular informado',
                        'Cidade e estado de residência',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Dados de dependentes
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.usersThree,
                      title: 'Dados de dependentes',
                      description: 'Informações vinculadas aos dependentes cadastrados na sua conta.',
                      items: [
                        'Dados cadastrais e de identificação',
                        'Nome e vínculo do responsável legal',
                        'Informações de contato de emergência',
                        'Informações complementares e de apoio',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Carteirinhas comunitárias
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinhas comunitárias',
                      description: 'Informações usadas para emissão, análise e manutenção da carteirinha comunitária.',
                      items: [
                        'Solicitações de emissão realizadas',
                        'Status da análise e emissão',
                        'Validade da carteirinha emitida',
                        'Histórico administrativo de controle interno',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Documentos sensíveis
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Documentos sensíveis',
                      description: 'Documentos usados apenas quando necessários para análise administrativa.',
                      items: [
                        'Documento oficial de identificação com foto',
                        'Laudo médico para comprovação de diagnóstico',
                        'Outros comprovantes solicitados na validação',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Registros técnicos
                    _buildDataCategoryCard(
                      context,
                      icon: PhosphorIconsRegular.terminalWindow,
                      title: 'Registros técnicos',
                      description: 'Alguns registros mínimos podem existir para segurança, funcionamento e auditoria do app.',
                      items: [
                        'Registro simplificado de data/hora de acesso',
                        'Notificações enviadas ao dispositivo',
                        'Eventos técnicos mínimos de estabilidade',
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Ação visual no final
                    DsBotao(
                      label: 'Solicitar informações',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Solicitação visual em construção.',
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
                      icon: PhosphorIconsRegular.export,
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

  /// Construtor de card de categoria de dados Dark Glass.
  Widget _buildDataCategoryCard(
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
