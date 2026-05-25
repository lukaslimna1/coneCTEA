import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

enum _BlockType { header, aviso, section }

class _LegalBlock {
  final _BlockType type;
  final int number;
  final String title;
  final String content;

  const _LegalBlock({
    required this.type,
    this.number = 0,
    required this.title,
    required this.content,
  });
}

class _HeaderInfo {
  final String title;
  final String version;
  final String date;
  final List<String> contacts;

  const _HeaderInfo({
    required this.title,
    required this.version,
    required this.date,
    required this.contacts,
  });
}

/// Modal rolável premium utilizado para exibir Termos de Uso e Política de Privacidade
/// no fluxo de cadastro com visual alinhado às telas internas do app.
class RegisterScrollableDialog extends StatelessWidget {
  final String title;
  final String content;

  const RegisterScrollableDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isTerms = title.toLowerCase().contains('termos');
    final accentColor = isTerms ? DsCores.termos.accent : DsCores.privacidade.accent;

    return AlertDialog(
      backgroundColor: DsCores.background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DsRaios.modal),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Círculo com ícone semântico destacado
            Container(
              width: DsTamanhos.iconFrameSm,
              height: DsTamanhos.iconFrameSm,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DsRaios.sm),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Icon(
                isTerms ? PhosphorIconsRegular.fileText : PhosphorIconsRegular.shieldCheck,
                color: accentColor,
                size: DsTamanhos.iconSm,
              ),
            ),
            const SizedBox(width: DsEspacamentos.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DsTipografia.sectionTitle.copyWith(
                      fontSize: 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTerms
                        ? 'Regras e termos da nossa comunidade'
                        : 'Como cuidamos da sua segurança de dados',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Botão Fechar claro e acessível
            IconButton(
              icon: Icon(
                PhosphorIconsRegular.x,
                color: DsCores.textMuted,
                size: DsTamanhos.iconSm,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildLegalBlocks(content, isTerms, accentColor),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        DsBotao(
          label: 'ENTENDI',
          onPressed: () => Navigator.pop(context),
          icon: PhosphorIconsRegular.check,
          variante: DsBotaoVariante.acao,
          token: isTerms ? DsCores.termos : DsCores.privacidade,
        ),
      ],
    );
  }

  Widget _buildLegalBlocks(String text, bool isTerms, Color accentColor) {
    final blocks = _parseLegalContent(text);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((block) => _buildBlockItem(block, isTerms, accentColor)).toList(),
      ),
    );
  }

  /// Faz o parse robusto do conteúdo legal em blocos bem estruturados.
  /// Identifica cabeçalho de metadados, Aviso Importante e seções numeradas.
  List<_LegalBlock> _parseLegalContent(String text) {
    final parts = text.split('─────────────────────────────');
    final blocks = <_LegalBlock>[];

    if (parts.isEmpty) return blocks;

    // Parte 0: Cabeçalho de Metadados
    final headerContent = parts[0].trim();
    if (headerContent.isNotEmpty) {
      blocks.add(_LegalBlock(
        type: _BlockType.header,
        title: '',
        content: headerContent,
      ));
    }

    // Processa o restante das partes em pares (título + corpo)
    for (int i = 1; i < parts.length; i += 2) {
      if (i + 1 >= parts.length) {
        // Fallback para conteúdo extra no fim do arquivo
        final remaining = parts[i].trim();
        if (remaining.isNotEmpty) {
          blocks.add(_LegalBlock(
            type: _BlockType.section,
            number: 0,
            title: '',
            content: remaining,
          ));
        }
        break;
      }

      final rawTitle = parts[i].trim();
      final rawContent = parts[i + 1].trim();

      if (rawTitle.isEmpty && rawContent.isEmpty) continue;

      if (rawTitle.toUpperCase() == 'AVISO IMPORTANTE') {
        blocks.add(_LegalBlock(
          type: _BlockType.aviso,
          title: rawTitle,
          content: rawContent,
        ));
      } else {
        // Seção numerada
        final match = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(rawTitle);
        if (match != null) {
          final number = int.parse(match.group(1)!);
          final titleText = match.group(2)!;
          blocks.add(_LegalBlock(
            type: _BlockType.section,
            number: number,
            title: titleText,
            content: rawContent,
          ));
        } else {
          // Fallback se não for seção numerada típica
          blocks.add(_LegalBlock(
            type: _BlockType.section,
            number: 0,
            title: rawTitle,
            content: rawContent,
          ));
        }
      }
    }

    return blocks;
  }

  _HeaderInfo _parseHeaderInfo(String headerText) {
    final lines = headerText.split('\n');
    String titleText = '';
    String version = '1.0';
    String date = '21/05/2026';
    final contacts = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('📄') || trimmed.startsWith('🛡️') || trimmed.contains('TERMOS') || trimmed.contains('POLÍTICA')) {
        titleText = trimmed;
      } else if (trimmed.startsWith('Versão:')) {
        version = trimmed.replaceFirst('Versão:', '').trim();
      } else if (trimmed.startsWith('Última atualização:')) {
        date = trimmed.replaceFirst('Última atualização:', '').trim();
      } else {
        contacts.add(trimmed);
      }
    }

    return _HeaderInfo(
      title: titleText,
      version: version,
      date: date,
      contacts: contacts,
    );
  }

  Widget _buildBlockItem(_LegalBlock block, bool isTerms, Color accentColor) {
    switch (block.type) {
      case _BlockType.header:
        final headerInfo = _parseHeaderInfo(block.content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Versão e Data sutil e premium
            Container(
              margin: const EdgeInsets.only(bottom: DsEspacamentos.md),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(DsRaios.sm),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsFill.info, color: accentColor, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Versão ${headerInfo.version}',
                        style: DsTipografia.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DsCores.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Atualizado em ${headerInfo.date}',
                    style: DsTipografia.caption.copyWith(
                      fontSize: 11,
                      color: DsCores.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Card sutil de contatos e informações institucionais
            if (headerInfo.contacts.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: DsEspacamentos.md),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DsRaios.md),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações Gerais',
                      style: DsTipografia.label.copyWith(
                        fontSize: 12,
                        color: DsCores.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...headerInfo.contacts.map((contact) {
                      IconData contactIcon = PhosphorIconsRegular.info;
                      if (contact.toLowerCase().contains('comunidade') || contact.toLowerCase().contains('responsável')) {
                        contactIcon = PhosphorIconsRegular.users;
                      } else if (contact.toLowerCase().contains('e-mail') || contact.toLowerCase().contains('email')) {
                        contactIcon = PhosphorIconsRegular.envelope;
                      } else if (contact.toLowerCase().contains('whatsapp') || contact.toLowerCase().contains('renata')) {
                        contactIcon = PhosphorIconsRegular.whatsappLogo;
                      } else if (contact.toLowerCase().contains('instagram') || contact.contains('@')) {
                        contactIcon = PhosphorIconsRegular.instagramLogo;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(contactIcon, size: 14, color: DsCores.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                contact,
                                style: DsTipografia.caption.copyWith(
                                  fontSize: 12,
                                  color: DsCores.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        );

      case _BlockType.aviso:
        return Container(
          margin: const EdgeInsets.only(bottom: DsEspacamentos.md),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D3A).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(DsRaios.lg),
            border: Border.all(color: accentColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsRegular.info, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Aviso importante',
                    style: DsTipografia.legalTitle.copyWith(
                      fontSize: 15,
                      color: DsCores.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                block.content,
                style: DsTipografia.legalBody.copyWith(
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        );

      case _BlockType.section:
        return Container(
          margin: const EdgeInsets.only(bottom: DsEspacamentos.md),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(DsRaios.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge numérico premium
              if (block.number > 0) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        const Color(0xFF22D3EE).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DsRaios.xs),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${block.number}',
                    style: GoogleFonts.outfit(
                      fontSize: block.number > 9 ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF22D3EE),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (block.title.isNotEmpty)
                      Text(
                        block.title,
                        style: DsTipografia.legalTitle.copyWith(
                          fontSize: 14.5,
                          height: 1.3,
                        ),
                      ),
                    if (block.content.isNotEmpty) ...[
                      if (block.title.isNotEmpty) const SizedBox(height: 8),
                      Text(
                        block.content,
                        style: DsTipografia.legalBody.copyWith(
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
