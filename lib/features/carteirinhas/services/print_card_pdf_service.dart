import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_request.dart';

/// **PrintCardPdfService**
///
/// Serviço local responsável por estruturar a geração do documento PDF e
/// delegar o gerenciamento da visualização e impressão nativa ao sistema operacional.
class PrintCardPdfService {
  
  /// Gera os bytes do PDF na memória de forma estritamente local e invoca a visualização/impressão do sistema
  Future<void> previewBasicPrintPdf(PrintCardRequest request) async {
    final pdf = pw.Document();

    // Definição rígida do formato A4 paisagem (landscape) para evitar miniaturização em retrato
    final pageFormat = PdfPageFormat.a4.landscape;

    // --- PÁGINA 1: Externa / Carteirinha (frente e verso lado a lado) ---
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          final pw.Widget leftPanel = pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildCardSkeleton(
                title: 'Frente da carteirinha',
                displayName: request.member.displayName,
                isFront: true,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          );

          final pw.Widget rightPanel = pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildCardSkeleton(
                title: 'Verso da carteirinha',
                displayName: request.member.displayName,
                isFront: false,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              if (request.includeProfile) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  '* Perfil de Apoio TEA disponível no verso.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Text(
                'Gerado localmente no aparelho.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          );

          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: [
                // Área superior da página reservada conceitualmente para as logos (fora da dobra/corte da carteirinha)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '[Logo ConeCTEA]',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '[Logo Família TEA Bauru]',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                // Área principal de corte e dobra
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      // Painel Esquerdo
                      pw.Expanded(
                        flex: 5,
                        child: leftPanel,
                      ),
                      // Divisor Central de Dobra
                      pw.Container(
                        width: 40,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                width: 1,
                                color: PdfColors.grey300,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Transform.rotateBox(
                                angle: 1.57079, // 90 graus em radianos
                                child: pw.Text(
                                  'Dobre aqui',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                width: 1,
                                color: PdfColors.grey300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Painel Direito
                      pw.Expanded(
                        flex: 5,
                        child: rightPanel,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );

    // --- PÁGINA 2: Interna / Perfil de Apoio TEA (Opcional, em folha dupla/verso) ---
    if (request.includeProfile) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Título
                  pw.Text(
                    'Perfil de Apoio TEA',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  // Subtítulo
                  pw.Text(
                    'Página opcional para ajudar escola, cuidadores, familiares, eventos ou consultas a conhecerem melhor a pessoa e entenderem como apoiar.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Colunas de Placeholders do Perfil (Organizadas em 2 colunas largas para aproveitar o A4 landscape)
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        // Coluna Esquerda
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildProfilePlaceholder('Foto / Como gosto de ser chamado(a)'),
                              _buildProfilePlaceholder('Nível de suporte', placeholderText: '[Nível 1 / Nível 2 / Nível 3]'),
                              _buildProfilePlaceholder('Sobre mim'),
                              _buildProfilePlaceholder('Como me comunico'),
                              _buildProfilePlaceholder('Coisas que eu gosto'),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 24),
                        // Linha central de guia física de dobra no verso
                        pw.Container(
                          width: 1,
                          color: PdfColors.grey200,
                        ),
                        pw.SizedBox(width: 24),
                        // Coluna Direita
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildProfilePlaceholder('Coisas que me irritam'),
                              _buildProfilePlaceholder('Coisas que eu posso fazer'),
                              _buildProfilePlaceholder('Como você pode me ajudar'),
                              _buildProfilePlaceholder('Alimentação', placeholderText: '[Comidas que eu gosto]\n[Comidas que eu não gosto ou que me incomodam]'),
                              _buildProfilePlaceholder('Informações úteis'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 16),
                  pw.Divider(color: PdfColors.grey300, thickness: 1),
                  pw.SizedBox(height: 8),
                  // Rodapé do Perfil
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Conteúdo opcional, gerenciado localmente, e não substitui documentos oficiais.',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 24),
                      pw.Text(
                        'Gerado localmente no aparelho.',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Aciona a impressão/prévia nativa do sistema passando os bytes em memória
    // Passando o formato explícito A4 landscape para forçar o sistema operacional a renderizar em orientação paisagem
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'carteirinha_conectea_${request.member.displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
      format: pageFormat,
    );
  }

  /// Constrói o esqueleto visual básico da carteirinha (Frente ou Verso)
  pw.Widget _buildCardSkeleton({
    required String title,
    required String displayName,
    required bool isFront,
  }) {
    return pw.Container(
      width: 130 * PdfPageFormat.mm,
      height: 90 * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey700, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Topo do card
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Corpo do card
          if (isFront) ...[
            pw.Text(
              'Nome: $displayName',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'TEA-ID: [será inserido]',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Validade: [será inserida]',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ] else ...[
            pw.Center(
              child: pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '[QR Code]',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 8),
          // Placeholder de espaço para o rodapé do card, se necessário
          pw.SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Constrói um bloco placeholder para o Perfil de Apoio
  pw.Widget _buildProfilePlaceholder(String label, {String? placeholderText}) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              alignment: pw.Alignment.topLeft,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                placeholderText ?? '[Placeholder - O conteúdo será inserido em etapa futura]',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
      ),
    );
  }
}
