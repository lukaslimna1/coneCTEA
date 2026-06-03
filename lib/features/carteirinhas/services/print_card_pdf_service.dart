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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.grey400,
                width: 1.5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Versão para impressão — ConeCTEA',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Prévia técnica do documento de impressão.',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Nome: ${request.member.displayName}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'ID do Membro: ${request.member.id}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Text(
                  'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Gerado localmente no aparelho.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Aciona a impressão/prévia nativa do sistema passando os bytes em memória
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'carteirinha_conectea_${request.member.displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
    );
  }
}
