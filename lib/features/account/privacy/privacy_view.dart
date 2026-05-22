import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:conectea/features/account/privacy/stored_data_view.dart';
import 'package:conectea/features/account/privacy/information_usage_view.dart';
import 'package:conectea/features/account/privacy/consents_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de Privacidade e Dados dentro da Central do Usuário.
///
/// Apresenta o design e a estrutura de gerenciamento da LGPD e privacidade.
/// Lógica e navegação definitivas serão acopladas em etapas posteriores.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

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
                      'Privacidade e dados',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consulte como suas informações são tratadas, gerencie autorizações e acesse os documentos legais do ConeCTEA.',
                      style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Card 1 — Dados armazenados
                    _buildPrivacyCard(
                      context,
                      icon: PhosphorIconsRegular.database,
                      title: 'Dados armazenados',
                      description: 'Veja quais tipos de informações podem estar vinculadas à sua conta, dependentes, solicitações e carteirinhas comunitárias.',
                      actionLabel: 'Ver dados armazenados',
                      actionIcon: PhosphorIconsRegular.eye,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StoredDataView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Uso das informações
                    _buildPrivacyCard(
                      context,
                      icon: PhosphorIconsRegular.info,
                      title: 'Uso das informações',
                      description: 'Entenda para quais finalidades seus dados podem ser usados no app, como conta, segurança, solicitações, programas e suporte.',
                      actionLabel: 'Ver uso das informações',
                      actionIcon: PhosphorIconsRegular.article,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InformationUsageView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Consentimentos
                    _buildPrivacyCard(
                      context,
                      icon: PhosphorIconsRegular.checkSquare,
                      title: 'Consentimentos',
                      description: 'Consulte autorizações necessárias e opcionais relacionadas ao uso dos seus dados, comunicações, programas e ações com parceiros.',
                      actionLabel: 'Ver consentimentos',
                      actionIcon: PhosphorIconsRegular.sliders,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConsentsView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Política de privacidade
                    _buildPrivacyCard(
                      context,
                      icon: PhosphorIconsRegular.fileLock,
                      title: 'Política de privacidade',
                      description: 'Leia como o ConeCTEA coleta, utiliza, protege, compartilha e descarta dados pessoais, documentos e informações sensíveis.',
                      actionLabel: 'Ler política',
                      actionIcon: PhosphorIconsRegular.shieldCheck,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'A Política de Privacidade será disponibilizada nesta área.',
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
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Termos de uso
                    _buildPrivacyCard(
                      context,
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Termos de uso',
                      description: 'Conheça as regras de uso do ConeCTEA, os limites da carteirinha comunitária e as responsabilidades de usuários, comunidade e parceiros.',
                      actionLabel: 'Ler termos de uso',
                      actionIcon: PhosphorIconsRegular.scroll,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Os Termos de Uso serão disponibilizados nesta área.',
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

  /// Construtor de card de privacidade Dark Glass customizado.
  Widget _buildPrivacyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required IconData actionIcon,
    VoidCallback? onPressed,
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
          DsBotao(
            label: actionLabel,
            onPressed: onPressed ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fluxo visual em construção.',
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
            icon: actionIcon,
          ),
        ],
      ),
    );
  }
}
