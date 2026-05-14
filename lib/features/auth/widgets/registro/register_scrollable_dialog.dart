import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';

/// Modelo interno de seção dos Termos de Uso.
class _TermsSection {
  final int number;   // 0 = cabeçalho, ≥1 = seção numerada
  final String title;
  final String body;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.body,
  });
}

/// Modal rolável utilizado para exibir Termos de Uso e Política de Privacidade
/// no fluxo de cadastro Auth.
///
/// Termos de Uso: renderizado como blocos/seções premium.
/// Política de Privacidade: mantido no formato de texto corrido.
class RegisterScrollableDialog extends StatelessWidget {
  final String title;
  final String content;

  const RegisterScrollableDialog({
    super.key,
    required this.title,
    required this.content,
  });

  // ─── Build principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isTerms = title.contains('Termos');

    return AlertDialog(
      backgroundColor: const Color(0xFF0C2445),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Icon(
            isTerms ? PhosphorIcons.fileText() : PhosphorIcons.shieldCheck(),
            color: AppColors.cyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildLegalBlocks(content),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            text: 'Compreendido',
            onPressed: () => Navigator.pop(context),
            icon: PhosphorIcons.check(),
            variant: PremiumButtonVariant.premiumCard,
            colorOverride: Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  // ─── Blocos estruturados (Termos de Uso e Política de Privacidade) ──────────

  Widget _buildLegalBlocks(String text) {
    final sections = _parseTermsSections(text);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map(_buildSectionBlock).toList(),
      ),
    );
  }

  /// Faz o parse do conteúdo de string existente em seções.
  /// Detecta linhas que iniciam com "N. Título" e agrupa o
  /// restante como corpo. Não altera o texto jurídico.
  List<_TermsSection> _parseTermsSections(String text) {
    final lines = text.trim().split('\n');
    final sections = <_TermsSection>[];
    final sectionHeader = RegExp(r'^(\d+)\.\s+(.+)$');

    String headerBuffer = '';
    int? currentNum;
    String currentTitle = '';
    String currentBody = '';

    void flush() {
      if (currentNum != null) {
        final num = currentNum;
        sections.add(_TermsSection(
          number: num,
          title: currentTitle,
          body: currentBody.trim(),
        ));
      } else if (headerBuffer.trim().isNotEmpty) {
        sections.add(_TermsSection(
          number: 0,
          title: '',
          body: headerBuffer.trim(),
        ));
      }
    }

    for (final line in lines) {
      final match = sectionHeader.firstMatch(line.trim());
      if (match != null) {
        flush();
        currentNum = int.parse(match.group(1)!);
        currentTitle = match.group(2)!;
        currentBody = '';
      } else {
        if (currentNum != null) {
          currentBody += '$line\n';
        } else {
          headerBuffer += '$line\n';
        }
      }
    }
    flush();

    return sections;
  }

  Widget _buildSectionBlock(_TermsSection section) {
    // Bloco de cabeçalho (metadados: versão, instituição, contato)
    if (section.number == 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.15)),
        ),
        child: Text(
          section.body,
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Bloco de seção numerada
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge numérico
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${section.number}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                if (section.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    section.body,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.65,
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
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
