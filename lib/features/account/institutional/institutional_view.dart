import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada Institucional.
///
/// Apresenta informações sobre o ConeCTEA, a comunidade Família TEA Bauru,
/// a natureza comunitária da iniciativa e os limites da carteirinha digital.
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
                      token: DsCores.institucional,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Institucional',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conheça a iniciativa, a comunidade responsável e os limites da carteirinha comunitária.',
                      style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Card Introdutório — ConeCTEA
                    _buildIntroCard(context),
                    const SizedBox(height: 32),

                    // Seção de cards informativos
                    Text(
                      'INFORMAÇÕES INSTITUCIONAIS',
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
                      description: 'Rede de apoio comunitária, informal, social e colaborativa com atuação principal em Bauru/SP.',
                      dataLabel: 'Comunidade responsável pela iniciativa',
                      actionLabel: 'Conhecer a comunidade',
                      actionIcon: PhosphorIconsRegular.arrowSquareOut,
                      onPressed: () => _showMockSnackBar(context, 'Conteúdo visual em construção.'),
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Natureza da iniciativa
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.leaf,
                      title: 'Natureza da iniciativa',
                      description: 'O ConeCTEA apoia uma iniciativa comunitária. Ele não representa serviço público, órgão governamental ou documento oficial.',
                      dataLabel: 'Social, comunitário e colaborativo',
                      actionLabel: 'Entendi',
                      actionIcon: PhosphorIconsRegular.checkCircle,
                      onPressed: () => _showMockSnackBar(context, 'Informação visual em construção.'),
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Carteirinha comunitária (com cor semântica DsCores.alerta moderada)
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinha comunitária',
                      description: 'A carteirinha do ConeCTEA é interna e comunitária. Ela não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou serviço público.',
                      dataLabel: 'Não é documento oficial',
                      actionLabel: 'Ver orientação',
                      actionIcon: PhosphorIconsRegular.info,
                      token: DsCores.alerta,
                      onPressed: () => _showMockSnackBar(context, 'Orientação visual em construção.'),
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Atuação principal
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.mapPin,
                      title: 'Atuação principal',
                      description: 'A atuação principal da comunidade acontece em Bauru/SP, com foco em apoio, informação e articulação comunitária.',
                      dataLabel: 'Bauru/SP',
                      actionLabel: 'Ver detalhes',
                      actionIcon: PhosphorIconsRegular.eye,
                      onPressed: () => _showMockSnackBar(context, 'Conteúdo visual em construção.'),
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Canais oficiais
                    _buildInstitutionalCard(
                      context,
                      icon: PhosphorIconsRegular.headset,
                      title: 'Canais oficiais',
                      description: 'Os canais oficiais de contato e comunicação ficam disponíveis na área de Ajuda e Suporte.',
                      dataLabel: 'WhatsApp, Instagram, e-mails e grupo comunitário',
                      actionLabel: 'Ir para suporte',
                      actionIcon: PhosphorIconsRegular.arrowRight,
                      onPressed: () => _showMockSnackBar(context, 'Navegação visual em construção.'),
                    ),
                    const SizedBox(height: 32),

                    // Card de Orientação Importante — Importante
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              DsMolduraIcone(
                icon: PhosphorIconsRegular.info,
                accentColor: DsCores.institucional.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ConeCTEA',
                  style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA é uma iniciativa social e comunitária voltada à organização de informações, carteirinha comunitária e apoio à rede da Família TEA Bauru.',
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
          ),
          const SizedBox(height: 16),
          // Selo/Badge discreto "Iniciativa comunitária"
          DsSelo.fromCorVisual(
            label: 'Iniciativa comunitária',
            token: DsCores.institucional,
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
    required String actionLabel,
    required IconData actionIcon,
    DsCorVisual token = DsCores.institucional,
    required VoidCallback onPressed,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      borderColor: token == DsCores.alerta ? token.border.withValues(alpha: 0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: icon,
                accentColor: token.accent,
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

          // Dado destacado
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
          const SizedBox(height: 16),

          // Botão de ação do card
          DsBotao(
            label: actionLabel,
            onPressed: onPressed,
            variante: DsBotaoVariante.acao,
            token: token,
            icon: actionIcon,
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
                  style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O ConeCTEA não é um serviço médico, não realiza diagnóstico e não substitui atendimento profissional, documentos oficiais ou serviços públicos.',
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
