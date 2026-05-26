import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/perfil/widgets/my_data_logged_header.dart';
import 'package:conectea/features/account/privacidade/privacy_policy_content.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual de leitura da Política de Privacidade do ConeCTEA.
///
/// Apresenta o documento de forma organizada em cards individuais,
/// sem exigência de checkbox ou trava de leitura, pois é uma tela apenas para consulta.
class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Faz o parser básico de trechos em negrito (**texto**) dentro de uma string
  /// e retorna uma lista de InlineSpans correspondente.
  List<InlineSpan> _parseInlineMarkdown(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final List<String> parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty && i == 0) continue;

      final bool isBold = i % 2 != 0;
      spans.add(
        TextSpan(
          text: parts[i],
          style: isBold
              ? baseStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DsCores.textPrimary,
                )
              : baseStyle,
        ),
      );
    }
    return spans;
  }

  /// Renderiza uma única linha tratando o bullet point "- " e trechos em negrito.
  Widget _renderMarkdownLine(
    String line,
    TextStyle baseStyle, {
    Color? bulletColor,
  }) {
    final String trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      return const SizedBox(height: 8);
    }

    // Verifica se a linha é um item de lista (bullet point)
    if (trimmedLine.startsWith('- ')) {
      // Remove o prefixo '- ' mantendo o restante do conteúdo
      final String contentText = trimmedLine.substring(2);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Círculo indicador em destaque
            Container(
              margin: const EdgeInsets.only(top: 6, right: 10),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: bulletColor ?? DsCores.privacidade.accent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: _parseInlineMarkdown(contentText, baseStyle),
                ),
                style: baseStyle,
              ),
            ),
          ],
        ),
      );
    }

    // Linha comum de texto
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text.rich(
        TextSpan(children: _parseInlineMarkdown(line, baseStyle)),
        style: baseStyle,
      ),
    );
  }

  /// Renderiza o bloco de texto Markdown completo, linha por linha.
  Widget _renderMarkdownContent(
    String rawText,
    TextStyle baseStyle, {
    Color? bulletColor,
  }) {
    final List<String> lines = rawText.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) =>
                _renderMarkdownLine(line, baseStyle, bulletColor: bulletColor),
          )
          .toList(),
    );
  }

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
              child: Stack(
                children: [
                  // Área Central Rolável
                  Positioned.fill(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DsBotaoVoltar(
                            onPressed: () => Navigator.pop(context),
                            token: DsCores.privacidade,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Política de privacidade',
                            style: DsTipografia.pageTitle.copyWith(
                              color: DsCores.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Entenda como suas informações pessoais, documentos e laudos são protegidos no app.',
                            style: DsTipografia.pageSubtitle.copyWith(
                              color: DsCores.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Card Compacto de Metadados
                          _buildMetadataCard(),
                          const SizedBox(height: 16),

                          // Bloco Aviso Importante
                          _buildImportantNoticeCard(),
                          const SizedBox(height: 24),

                          // Cards das Seções de 1 a 18
                          ..._buildSectionsList(),
                        ],
                      ),
                    ),
                  ),

                  // Rodapé Fixo
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildFixedFooter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de metadados do topo com informações da versão e publicação.
  Widget _buildMetadataCard() {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.shieldCheck,
                accentColor: DsCores.privacidade.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  PrivacyPolicyContent.documentTitle,
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 16),
          _buildMetadataRow('Versão', PrivacyPolicyContent.version),
          const SizedBox(height: 10),
          _buildMetadataRow(
            'Última atualização',
            PrivacyPolicyContent.lastUpdated,
          ),
          const SizedBox(height: 10),
          _buildMetadataRow('Aplicativo', PrivacyPolicyContent.appName),
          const SizedBox(height: 10),
          _buildMetadataRow(
            'Comunidade responsável',
            PrivacyPolicyContent.responsibleCommunity,
          ),
          const SizedBox(height: 10),
          _buildMetadataRow(
            'Cidade de atuação principal',
            PrivacyPolicyContent.mainCity,
          ),
        ],
      ),
    );
  }

  /// Construtor de linha de dados de metadados.
  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: DsTipografia.bodySmall.copyWith(
            color: DsCores.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Bloco especial de Aviso Importante estilizado com DsCores.alerta.
  Widget _buildImportantNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DsCores.alerta.softBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DsRaios.lg),
        border: Border.all(color: DsCores.alerta.border.withValues(alpha: 0.4)),
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
                  'Aviso importante',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _renderMarkdownContent(
            PrivacyPolicyContent.importantNotice,
            DsTipografia.legalBody.copyWith(color: DsCores.textPrimary),
            bulletColor: DsCores.alerta.accent,
          ),
        ],
      ),
    );
  }

  /// Constrói em loop a lista de cards das seções 1 a 18.
  List<Widget> _buildSectionsList() {
    return PrivacyPolicyContent.sections.map((section) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DsCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DsMolduraIcone(
                    icon: PhosphorIconsRegular.article,
                    accentColor: DsCores.privacidade.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${section.number}. ${section.title}',
                      style: DsTipografia.legalTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              const SizedBox(height: 16),
              _renderMarkdownContent(
                section.content,
                DsTipografia.legalBody.copyWith(color: DsCores.textSecondary),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Rodapé fixo simplificado contendo apenas o botão "Entendi" sempre habilitado.
  Widget _buildFixedFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: DsCores.glassStrong,
        border: Border(top: BorderSide(color: DsCores.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: DsBotao(
          label: 'Entendi',
          onPressed: () => Navigator.pop(context),
          variante: DsBotaoVariante.acao,
          token: DsCores.privacidade,
          icon: PhosphorIconsRegular.check,
        ),
      ),
    );
  }
}
