import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de Ajuda e Suporte.
///
/// Apresenta o design e os canais oficiais de contato da Família TEA Bauru
/// de maneira estruturada e em conformidade com a identidade visual do app.
class SupportView extends StatelessWidget {
  const SupportView({super.key});

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
                      token: DsCores.suporte,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ajuda e suporte',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encontre os canais oficiais da Família TEA Bauru e orientações de apoio.',
                      style: DsTipografia.pageSubtitle.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card Introdutório — Família TEA Bauru
                    _buildIntroCard(context),
                    const SizedBox(height: 24),

                    // CANAIS OFICIAIS
                    Text(
                      'CANAIS OFICIAIS',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.suporte.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1 — WhatsApp oficial
                    _buildChannelCard(
                      context,
                      icon: PhosphorIconsRegular.phone,
                      title: 'WhatsApp oficial',
                      description:
                          'Canal oficial de contato com Renata Ferreguti, representante/presidente da Família TEA Bauru.',
                      dataValue: '+55 14 99101-2961',
                      actionLabel: 'Falar pelo WhatsApp',
                      actionIcon: PhosphorIconsRegular.chatCircleText,
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Canal visual em construção.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2 — Grupo comunitário
                    _buildChannelCard(
                      context,
                      icon: PhosphorIconsRegular.usersThree,
                      title: 'Grupo comunitário',
                      description:
                          'Grupo comunitário oficial para comunicação e apoio da comunidade.',
                      dataValue: 'Grupo oficial da Família TEA Bauru',
                      actionLabel: 'Acessar grupo',
                      actionIcon: PhosphorIconsRegular.arrowSquareOut,
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Canal visual em construção.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — Instagram
                    _buildChannelCard(
                      context,
                      icon: PhosphorIconsRegular.instagramLogo,
                      title: 'Instagram',
                      description:
                          'Acompanhe comunicados, ações e informações públicas da comunidade.',
                      dataValue: '@familiateabauru',
                      actionLabel: 'Abrir Instagram',
                      actionIcon: PhosphorIconsRegular.camera,
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Canal visual em construção.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — E-mail principal
                    _buildChannelCard(
                      context,
                      icon: PhosphorIconsRegular.envelope,
                      title: 'E-mail principal',
                      description: 'Canal principal para contato por e-mail.',
                      dataValue: 'familiateabauru@gmail.com',
                      actionLabel: 'Enviar e-mail',
                      actionIcon: PhosphorIconsRegular.paperPlaneTilt,
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Canal visual em construção.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — E-mail ConeCTEA
                    _buildChannelCard(
                      context,
                      icon: PhosphorIconsRegular.envelopeSimple,
                      title: 'E-mail ConeCTEA',
                      description:
                          'Canal secundário relacionado ao projeto ConeCTEA.',
                      dataValue: 'conecteabauru@gmail.com',
                      actionLabel: 'Enviar e-mail',
                      actionIcon: PhosphorIconsRegular.paperPlaneTilt,
                      onPressed: () => _showMockSnackBar(
                        context,
                        'Canal visual em construção.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 6 — Site oficial
                    _buildChannelCard(
                      context,
                      icon: PhosphorIconsRegular.globe,
                      title: 'Site oficial',
                      description: 'Site oficial da iniciativa.',
                      dataValue: 'Em breve',
                      actionLabel: 'Ver site',
                      actionIcon: PhosphorIconsRegular.browser,
                      isDisabled: true,
                      onPressed: () =>
                          _showMockSnackBar(context, 'Site oficial em breve.'),
                    ),
                    const SizedBox(height: 32),

                    // SEÇÃO FAQ
                    Text(
                      'Perguntas frequentes',
                      style: DsTipografia.sectionTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Respostas rápidas sobre o ConeCTEA e a carteirinha comunitária.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FAQ 1
                    _FaqItem(
                      question: 'O ConeCTEA é um app oficial do governo?',
                      answer:
                          'Não. O ConeCTEA é uma iniciativa comunitária da Família TEA Bauru.',
                      token: DsCores.suporte,
                      icon: PhosphorIconsRegular.question,
                    ),
                    const SizedBox(height: 12),

                    // FAQ 2
                    _FaqItem(
                      question:
                          'A carteirinha substitui CIPTEA, RG, CPF ou laudo?',
                      answer:
                          'Não. A carteirinha do ConeCTEA é comunitária e interna. Ela não substitui documentos oficiais, laudos ou serviços públicos.',
                      token: DsCores.alerta,
                      icon: PhosphorIconsRegular.identificationCard,
                    ),
                    const SizedBox(height: 12),

                    // FAQ 3
                    _FaqItem(
                      question: 'O app faz diagnóstico?',
                      answer:
                          'Não. O ConeCTEA não realiza diagnóstico e não substitui atendimento profissional.',
                      token: DsCores.alerta,
                      icon: PhosphorIconsRegular.warningCircle,
                    ),
                    const SizedBox(height: 12),

                    // FAQ 4
                    _FaqItem(
                      question: 'Como acompanho minha solicitação?',
                      answer:
                          'As solicitações aparecem dentro do app, nas áreas de carteirinha e acompanhamento.',
                      token: DsCores.suporte,
                      icon: PhosphorIconsRegular.clock,
                    ),
                    const SizedBox(height: 12),

                    // FAQ 5
                    _FaqItem(
                      question: 'Como falo com a equipe?',
                      answer:
                          'Use os canais oficiais exibidos nesta tela para falar com a Família TEA Bauru.',
                      token: DsCores.suporte,
                      icon: PhosphorIconsRegular.chatCircleText,
                    ),
                    const SizedBox(height: 12),

                    // FAQ 6
                    _FaqItem(
                      question: 'O site oficial já está disponível?',
                      answer:
                          'Ainda não. O site oficial será informado quando estiver disponível.',
                      token: DsCores.suporte,
                      icon: PhosphorIconsRegular.globe,
                    ),
                    const SizedBox(height: 32),

                    // Card de orientação importante — Importante
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

  /// Construtor de Card Introdutório oficial Família TEA Bauru.
  Widget _buildIntroCard(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.buildings,
                accentColor: DsCores.suporte.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Família TEA Bauru',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rede de apoio comunitária, informal, social e colaborativa com atuação principal em Bauru/SP.',
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
          ),
          const SizedBox(height: 16),
          // Selo/Badge discreto "Comunidade responsável pelo ConeCTEA"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: DsCores.suporte.softBackground,
              borderRadius: BorderRadius.circular(DsRaios.sm),
              border: Border.all(color: DsCores.suporte.border),
            ),
            child: Text(
              'Comunidade responsável pelo ConeCTEA',
              style: DsTipografia.caption.copyWith(
                color: DsCores.suporte.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construtor de Card de canal oficial Dark Glass.
  Widget _buildChannelCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String dataValue,
    required String actionLabel,
    required IconData actionIcon,
    bool isDisabled = false,
    required VoidCallback onPressed,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(icon: icon, accentColor: DsCores.suporte.accent),
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

          // Dado em destaque
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(DsRaios.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              dataValue,
              style: DsTipografia.body.copyWith(
                color: isDisabled ? DsCores.textSecondary : DsCores.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão de ação do card
          DsBotao(
            label: actionLabel,
            onPressed: isDisabled ? null : onPressed,
            variante: DsBotaoVariante.acao,
            token: DsCores.suporte,
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
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
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

/// Item expansível e interativo para a seção de FAQ (Perguntas Frequentes).
///
/// Gerencia seu próprio estado aberto/fechado localmente.
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final DsCorVisual token;
  final IconData icon;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.token,
    required this.icon,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(16),
      borderColor: _isExpanded
          ? widget.token.accent.withValues(alpha: 0.3)
          : null,
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsMolduraIcone(
                icon: widget.icon,
                accentColor: widget.token.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    widget.question,
                    style: DsTipografia.body.copyWith(
                      color: DsCores.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(
                  _isExpanded
                      ? PhosphorIconsRegular.caretUp
                      : PhosphorIconsRegular.caretDown,
                  color: _isExpanded ? widget.token.accent : DsCores.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52.0, right: 8.0),
              child: Text(
                widget.answer,
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
