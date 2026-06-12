import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/conta/institucional/about_conectea_view.dart';
import 'package:conectea/features/conta/institucional/family_tea_view.dart';
import 'package:conectea/features/conta/suporte/support_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela principal Institucional da Central do Usuário.
///
/// Apresenta informações sobre a iniciativa ConeCTEA, a Família TEA Bauru,
/// a natureza comunitária do projeto, finalidade da carteirinha e projetos.
class InstitutionalView extends StatelessWidget {
  const InstitutionalView({super.key});

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
                      token: DsCores.institucional,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Institucional',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conheça o ConeCTEA, a Família TEA Bauru, os projetos comunitários e a finalidade da carteirinha.',
                      style: DsTipografia.pageSubtitle.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card destaque inicial — ConeCTEA
                    _buildIntroCard(context),
                    const SizedBox(height: 32),

                    // Título da Seção
                    Text(
                      'SOBRE A INICIATIVA',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.institucional.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1 — Família TEA Bauru
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.usersThree,
                      title: 'Família TEA Bauru',
                      description:
                          'Comunidade e rede de apoio formada por famílias, responsáveis, voluntários, profissionais e parceiros unidos por inclusão, respeito e acolhimento.',
                      dataLabel: 'Comunidade responsável pelo ConeCTEA',
                      actionLabel: 'Conhecer comunidade',
                      actionIcon: PhosphorIconsRegular.arrowRight,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FamilyTeaView(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Natureza da iniciativa
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.globeSimple,
                      title: 'Iniciativa comunitária',
                      description:
                          'O ConeCTEA apoia a organização de ações comunitárias da Família TEA Bauru. Ele não é órgão público, serviço governamental, clínica, empresa ou documento oficial.',
                      dataLabel: 'Social, comunitário e colaborativo',
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Carteirinha comunitária
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinha comunitária',
                      description:
                          'A carteirinha do ConeCTEA tem uso interno e comunitário. Ela ajuda na organização da comunidade, mas não é documento oficial e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou serviço público.',
                      dataLabel: 'Uso interno e comunitário',
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Atuação principal
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.mapPin,
                      title: 'Atuação principal',
                      description:
                          'A atuação principal da Família TEA Bauru acontece em Bauru/SP, com ações de apoio, informação, acolhimento e articulação comunitária.',
                      dataLabel: 'Bauru/SP',
                    ),
                    const SizedBox(height: 16),

                    // Card 6 — Canais oficiais
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.headset,
                      title: 'Canais oficiais',
                      description:
                          'Use os canais oficiais para falar com a Família TEA Bauru, acompanhar avisos, pedir suporte ou buscar orientações sobre o ConeCTEA.',
                      dataLabel: 'Contato e suporte da comunidade',
                      actionLabel: 'Ir para suporte',
                      actionIcon: PhosphorIconsRegular.arrowRight,
                      onPressed: () {
                        // Navega para a tela de suporte se estiver disponível no build context,
                        // senão exibe snackbar temporário conforme especificado.
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportView(),
                            ),
                          );
                        } catch (_) {
                          _showMockSnackBar(
                            context,
                            'Acesse a área de suporte pelos canais oficiais.',
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Card final — Importante
                    _buildWarningCard(context),
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

  /// Construtor do Card Introdutório oficial do ConeCTEA.
  Widget _buildIntroCard(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsMolduraIcone(
                icon: PhosphorIconsRegular.info,
                accentColor: Color(0xFFA78BFA), // token institucional accent
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ConeCTEA',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA é o app comunitário da Família TEA Bauru, criado para apoiar a organização de informações, solicitações, carteirinhas comunitárias, comunicações e ações da comunidade.',
            style: DsTipografia.body.copyWith(
              color: DsCores.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Selo/Badge "App comunitário"
          DsSelo.fromCorVisual(
            label: 'App comunitário',
            token: DsCores.institucional,
          ),
          const SizedBox(height: 16),
          // Botão "Saiba mais"
          SizedBox(
            width: double.infinity,
            child: DsBotao(
              label: 'Saiba mais',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutConecteaView(),
                ),
              ),
              variante: DsBotaoVariante.acao,
              token: DsCores.institucional,
              icon: PhosphorIconsRegular.arrowRight,
            ),
          ),
        ],
      ),
    );
  }

  /// Construtor genérico de Card de Informação Institucional.
  Widget _buildInstitutionalCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String dataLabel,
    String? actionLabel,
    IconData? actionIcon,
    DsCorVisual token = DsCores.institucional,
    VoidCallback? onPressed,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(icon: icon, accentColor: token.accent),
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
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Dado destacado/Selo descritivo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(DsRaios.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              dataLabel,
              style: DsTipografia.body.copyWith(
                color: DsCores.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DsBotao(
                label: actionLabel,
                onPressed: onPressed,
                variante: DsBotaoVariante.acao,
                token: token,
                icon: actionIcon,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construtor de Card de Orientação Importante.
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
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA não é serviço médico, não realiza diagnóstico e não substitui atendimento profissional, laudos, documentos oficiais ou serviços públicos. A carteirinha é comunitária e deve ser usada apenas dentro da finalidade do app.',
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
