import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela interna informativa: Projetos e Ações.
class ProjectsActionsView extends StatelessWidget {
  const ProjectsActionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DsBotaoVoltar(
                        onPressed: () => Navigator.pop(context),
                        token: DsCores.institucional,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Projetos e ações',
                        style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conheça projetos, chamamentos, eventos e iniciativas comunitárias da Família TEA Bauru.',
                        style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                      ),
                      const SizedBox(height: 32),

                      // Card 1 — Fada do Dente
                      _buildProjectCard(
                        context,
                        icon: PhosphorIconsRegular.star,
                        title: 'Fada do Dente',
                        text: 'Ação comunitária voltada ao encaminhamento inicial para atendimento odontológico com profissional parceiro, conforme disponibilidade e regras da ação.',
                        seloLabel: 'Ação comunitária',
                        actionLabel: 'Ver detalhes',
                        onPressed: () => _showSnackBar(
                          context,
                          'Detalhes do projeto serão disponibilizados nesta área.',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 2 — Vidas
                      _buildProjectCard(
                        context,
                        icon: PhosphorIconsRegular.heartbeat,
                        title: 'Vidas',
                        text: 'Ação comunitária voltada ao apoio inicial para consultas com profissionais parceiros, conforme disponibilidade, critérios e organização da Família TEA Bauru.',
                        seloLabel: 'Ação comunitária',
                        actionLabel: 'Ver detalhes',
                        onPressed: () => _showSnackBar(
                          context,
                          'Detalhes do projeto serão disponibilizados nesta área.',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 3 — Eventos
                      _buildProjectCard(
                        context,
                        icon: PhosphorIconsRegular.calendar,
                        title: 'Eventos',
                        text: 'Eventos, encontros, palestras e ações comunitárias divulgadas pela Família TEA Bauru, incluindo ações maiores como a EXPO Viva Inclusão.',
                        seloLabel: 'Eventos e encontros',
                        actionLabel: 'Ver eventos',
                        onPressed: () => _showSnackBar(
                          context,
                          'A área de eventos será disponibilizada em breve.',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bloco final — Importante
                      _buildWarningCard(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Botão final
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: DsBotao(
                    label: 'Entendi',
                    onPressed: () => Navigator.pop(context),
                    variante: DsBotaoVariante.acao,
                    token: DsCores.institucional,
                    icon: PhosphorIconsRegular.check,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
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

  Widget _buildProjectCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    required String seloLabel,
    required String actionLabel,
    required VoidCallback onPressed,
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
                accentColor: const Color(0xFFA78BFA), // token institucional accent
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
            text,
            style: DsTipografia.body.copyWith(
              color: DsCores.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          DsSelo.fromCorVisual(
            label: seloLabel,
            token: DsCores.institucional,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DsBotao(
              label: actionLabel,
              onPressed: onPressed,
              variante: DsBotaoVariante.acao,
              token: DsCores.institucional,
              icon: PhosphorIconsRegular.arrowRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DsCores.alerta.softBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DsRaios.lg),
        border: Border.all(color: DsCores.alerta.border.withValues(alpha: 0.3)),
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
            'A participação em projetos, ações ou eventos depende da disponibilidade, critérios e organização de cada iniciativa. O ConeCTEA pode apoiar a comunicação e a organização, mas não garante atendimento, vaga, benefício ou serviço.',
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
