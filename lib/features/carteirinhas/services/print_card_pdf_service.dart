import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_request.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/carteirinhas/services/print_support_profile_local_service.dart';

/// **PrintCardPdfService**
///
/// Serviço local responsável por estruturar a geração do documento PDF e
/// delegar o gerenciamento da visualização e impressão nativa ao sistema operacional.
class PrintCardPdfService {
  // Constantes de diagnóstico de performance (Tarefa 2)
  static const bool _debugPdfDisableLogo = false;
  static const bool _debugPdfDisableQr = false;

  /// Gera os bytes do PDF na memória de forma estritamente local
  Future<Uint8List> buildPrintCardPdfBytes(PrintCardRequest request) async {
    final stopwatch = Stopwatch()..start();
    int lastTime = 0;

    void logStage(String stageName) {
      if (kDebugMode) {
        final elapsed = stopwatch.elapsedMilliseconds;
        final duration = elapsed - lastTime;
        debugPrint(
          '[PrintPDF] $stageName: ${duration}ms (total: ${elapsed}ms)',
        );
        lastTime = elapsed;
      }
    }

    logStage('inicio do metodo');

    // Carrega a logo real do ConeCTEA se disponível (uma única vez)
    pw.MemoryImage? logoImage;
    if (!_debugPdfDisableLogo) {
      try {
        final logoBytes = await rootBundle.load(
          'assets/images/conectea_logo.png',
        );
        logStage('rootBundle.load logo');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
        logStage('criação do MemoryImage da logo');
      } catch (_) {
        logStage('falha ao carregar a logo');
      }
    } else {
      logStage('logo desabilitada via flag de debug');
    }

    // Definição rígida do formato A4 paisagem (landscape) com margens reduzidas para melhor aproveitamento
    final pageFormat = PdfPageFormat.a4.landscape.copyWith(
      marginLeft: 10,
      marginRight: 10,
      marginTop: 10,
      marginBottom: 10,
    );

    final displayName = request.member.displayName.trim().isNotEmpty
        ? request.member.displayName
        : 'Nome não informado';

    final teaId = request.activeCard.cardNumber;
    final validade = ConecteaDateTimeHelper.formatProjectDateShort(
      request.activeCard.validUntil,
    );
    final vinculo =
        (request.activeCard.isSupportNetwork || request.member.isSupportNetwork)
        ? 'REDE DE APOIO TEA'
        : 'PESSOA TEA';

    final statusLabel = request.activeCard.status.toUpperCase() == 'ACTIVE'
        ? 'ATIVA'
        : 'PENDENTE';

    // BirthDate formatado
    String? birthDateAndAge;
    if (request.options.includeBirthDateAndAge &&
        request.member.dateOfBirth.trim().isNotEmpty) {
      birthDateAndAge = _getBirthDateAndAge(request.member.dateOfBirth);
    }

    // Tipo Sanguíneo
    String? bloodType;
    if (request.options.includeBloodType) {
      bloodType =
          (request.bloodTypeOverride != null &&
              request.bloodTypeOverride!.trim().isNotEmpty)
          ? request.bloodTypeOverride!
          : request.member.bloodType;
      if (bloodType.trim().isEmpty) bloodType = null;
    }

    // Cidade / UF
    String? cityUf;
    if (request.options.includeCityUf) {
      cityUf =
          (request.cityUfOverride != null &&
              request.cityUfOverride!.trim().isNotEmpty)
          ? request.cityUfOverride!
          : (request.member.city.trim().isNotEmpty &&
                request.member.state.trim().isNotEmpty)
          ? '${request.member.city} / ${request.member.state}'
          : null;
    }
    logStage('montagem dos dados em strings');

    // Carrega rascunho de perfil local apenas se solicitado (Tarefa 2)
    PrintSupportProfileDraft? draft;
    if (request.includeProfile) {
      try {
        final localService = PrintSupportProfileLocalService();
        draft = await localService.loadDraft(request.member.id);
        logStage('leitura do SharedPreferences do Perfil');
      } catch (_) {
        logStage('falha ao ler perfil local');
      }
    } else {
      logStage('perfil desconsiderado (includeProfile == false)');
    }

    final pdf = pw.Document();
    logStage('criação do Document');

    // --- PÁGINA 1: Externa / Carteirinha (frente e verso lado a lado) ---
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Column(
              children: [
                // Área superior reservada para as logos
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    logoImage != null
                        ? pw.Container(
                            height: 42,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          )
                        : pw.Text(
                            '[Logo ConeCTEA]',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey500,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                    pw.Text(
                      '[Logo Família TEA Bauru]',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // Área principal dos cards (alinhados horizontalmente)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Frente da carteirinha (Painel Esquerdo)
                    pw.Expanded(
                      flex: 5,
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: _buildFrontCardSkeleton(
                          displayName: displayName,
                          teaId: teaId,
                          validade: validade,
                          vinculo: vinculo,
                          birthDateAndAge: birthDateAndAge,
                          bloodType: bloodType,
                          cityUf: cityUf,
                          status: statusLabel,
                          logoImage: logoImage,
                        ),
                      ),
                    ),
                    // Divisor Central de Dobra (Linha tracejada discreta)
                    pw.Container(
                      width: 12,
                      height: 96 * PdfPageFormat.mm,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'DOBRA',
                            style: pw.TextStyle(
                              fontSize: 5,
                              color: PdfColors.grey600,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Expanded(
                            child: pw.Container(
                              width: 0.8,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  left: pw.BorderSide(
                                    color: PdfColors.grey600,
                                    width: 0.8,
                                    style: pw.BorderStyle.dashed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'DOBRA',
                            style: pw.TextStyle(
                              fontSize: 5,
                              color: PdfColors.grey600,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verso da carteirinha (Painel Direito)
                    pw.Expanded(
                      flex: 5,
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: _buildBackCardSkeleton(
                          request,
                          logoImage: logoImage,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // Área dos textos informativos (alinhados na base, sem afetar a posição dos cards)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Avisos da Frente (Esquerdo)
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                        child: pw.Text(
                          'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ),
                    // Espaço do divisor
                    pw.SizedBox(width: 12),
                    // Avisos do Verso (Direito)
                    pw.Expanded(
                      flex: 5,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                color: PdfColors.grey900,
                              ),
                            ),
                            if (request.includeProfile) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '* Perfil de Apoio TEA disponível no verso.',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                            ],
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Gerado localmente no aparelho.',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.grey800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
    logStage('adição Página 1');

    // --- PÁGINA 2 E PÁGINA 3 CONDICIONAL: Interna / Perfil de Apoio TEA (Opcional, em folha dupla/verso) ---
    if (request.includeProfile) {
      bool hasPage3 = false;
      if (draft == null || !draft.hasAnyContent) {
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return _buildEmptyProfilePage();
            },
          ),
        );
        logStage('adição Página 2 (Perfil Vazio)');
      } else {
        final String preferredName =
            (draft.includePreferredName &&
                draft.preferredName.trim().isNotEmpty)
            ? draft.preferredName.trim()
            : '';
        final String supportLevel =
            (draft.includeSupportLevel && draft.supportLevel.trim().isNotEmpty)
            ? draft.supportLevel.trim()
            : '';

        // Como me comunico
        String commText = '';
        if (draft.includeCommunication) {
          final List<String> items = [];
          if (draft.commSpeech) items.add('Fala');
          if (draft.commGestures) items.add('Gestos/Expressões');
          if (draft.commPictograms) items.add('Figuras/Pictogramas');
          if (draft.commApps) items.add('Aplicativos/Dispositivos');

          final optionsStr = items.join(' | ');
          final notesStr = draft.communicationNotes.trim();
          if (optionsStr.isNotEmpty && notesStr.isNotEmpty) {
            commText = '$optionsStr\n$notesStr';
          } else if (optionsStr.isNotEmpty) {
            commText = optionsStr;
          } else {
            commText = notesStr;
          }
        }

        // Helper interno para formatar listas dinâmicas com "• "
        String formatList(List<String> list) {
          final clean = list
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (clean.isEmpty) return '';
          return clean.map((e) => '• $e').join('\n');
        }

        final String curiosities = draft.includeCuriosities
            ? formatList(draft.abilities)
            : '';
        final String likes = draft.includeLikes ? formatList(draft.likes) : '';
        final String irritations = draft.includeIrritations
            ? formatList(draft.irritations)
            : '';

        final String foodLikes = draft.includeFoodLikes
            ? formatList(draft.foodLikes)
            : '';
        final String foodDislikes = draft.includeFoodDislikes
            ? formatList(draft.foodDislikes)
            : '';
        final String medications = draft.includeMedications
            ? formatList(draft.medications)
            : '';
        final String allergies = draft.includeAllergies
            ? formatList(draft.allergies)
            : '';
        final String supportTips = draft.includeSupportTips
            ? formatList(draft.supportTips)
            : '';

        // Coleta de Specs para a Metade Esquerda
        final leftSpecs = <_ProfileBlockSpec>[];
        if (draft.includeAbout && draft.about.trim().isNotEmpty) {
          leftSpecs.add(_ProfileBlockSpec('Sobre mim', draft.about.trim()));
        }
        if (curiosities.isNotEmpty) {
          leftSpecs.add(
            _ProfileBlockSpec('Curiosidades sobre mim', curiosities),
          );
        }
        if (likes.isNotEmpty) {
          leftSpecs.add(_ProfileBlockSpec('Coisas que eu gosto', likes));
        }
        if (irritations.isNotEmpty) {
          leftSpecs.add(
            _ProfileBlockSpec('Coisas que me irritam', irritations),
          );
        }

        // Coleta de Specs para a Metade Direita
        final rightSpecs = <_ProfileBlockSpec>[];
        if (foodLikes.isNotEmpty) {
          rightSpecs.add(_ProfileBlockSpec('Comidas que eu gosto', foodLikes));
        }
        if (foodDislikes.isNotEmpty) {
          rightSpecs.add(
            _ProfileBlockSpec(
              'Comidas que eu não gosto / que me incomodam',
              foodDislikes,
            ),
          );
        }
        if (medications.isNotEmpty) {
          rightSpecs.add(_ProfileBlockSpec('Medicações', medications));
        }
        if (allergies.isNotEmpty) {
          rightSpecs.add(_ProfileBlockSpec('Alergias', allergies));
        }
        if (draft.includeOtherImportantInfo &&
            draft.otherImportantInfo.trim().isNotEmpty) {
          rightSpecs.add(
            _ProfileBlockSpec(
              'Outras informações importantes',
              draft.otherImportantInfo.trim(),
            ),
          );
        }
        if (supportTips.isNotEmpty) {
          rightSpecs.add(
            _ProfileBlockSpec('Como você pode me ajudar', supportTips),
          );
        }

        // Constantes de layout para cálculo de overflow físico (Tarefa 2)
        const double pageHeightUseful = 555.275; // Altura útil da página
        const double footerHeightReserved = 25.0; // Altura do rodapé e margem
        const double leftHeaderHeight =
            139.38; // Título (19 pt) + Foto 3x4 (115.38 pt) + Espaçador (5 pt)

        // Limites úteis reais para a distribuição dos blocos na Página 2
        const double leftLimitP2 =
            pageHeightUseful -
            leftHeaderHeight -
            footerHeightReserved; // ~390.89 pt
        const double rightLimitP2 =
            pageHeightUseful - footerHeightReserved; // ~530.275 pt

        // Algoritmo de partição para a Metade Esquerda
        final leftP2 = <_ProfileBlockSpec>[];
        final leftP3 = <_ProfileBlockSpec>[];
        double leftHeightP2 = 0.0;

        for (final block in leftSpecs) {
          final double h = _estimateBlockHeight(
            block.label,
            block.content,
            block.isList,
          );
          if (leftHeightP2 + h <= leftLimitP2) {
            leftP2.add(block);
            leftHeightP2 += h;
          } else {
            final double remainingSpace = leftLimitP2 - leftHeightP2;
            if (remainingSpace >= 50.0) {
              if (block.isList) {
                final items = block.getItems();
                final p2Items = <String>[];
                final p3Items = <String>[];
                double currentH = 28.0;

                for (final item in items) {
                  final itemText = item.startsWith('•')
                      ? item.substring(1).trim()
                      : item;
                  final int itemLines = (itemText.length / 75.0).ceil();
                  final double itemH = (itemLines * 9.6) + 2.5;

                  if (leftHeightP2 + currentH + itemH <= leftLimitP2) {
                    p2Items.add(item);
                    currentH += itemH;
                  } else {
                    p3Items.add(item);
                  }
                }

                if (p2Items.isNotEmpty && p3Items.isNotEmpty) {
                  leftP2.add(
                    _ProfileBlockSpec(block.label, p2Items.join('\n')),
                  );
                  leftP3.add(
                    _ProfileBlockSpec(
                      '${block.label} (continuação)',
                      p3Items.join('\n'),
                    ),
                  );
                  leftHeightP2 += currentH;
                  continue;
                }
              } else {
                final paragraphs = block.content.split('\n');
                final p2Paragraphs = <String>[];
                final p3Paragraphs = <String>[];
                double currentH = 28.0;

                for (final para in paragraphs) {
                  final int textLines = para.trim().isEmpty
                      ? 1
                      : (para.trim().length / 80.0).ceil();
                  final double paraH = textLines * 9.6;

                  if (leftHeightP2 + currentH + paraH <= leftLimitP2) {
                    p2Paragraphs.add(para);
                    currentH += paraH;
                  } else {
                    p3Paragraphs.add(para);
                  }
                }

                if (p2Paragraphs.isNotEmpty && p3Paragraphs.isNotEmpty) {
                  leftP2.add(
                    _ProfileBlockSpec(block.label, p2Paragraphs.join('\n')),
                  );
                  leftP3.add(
                    _ProfileBlockSpec(
                      '${block.label} (continuação)',
                      p3Paragraphs.join('\n'),
                    ),
                  );
                  leftHeightP2 += currentH;
                  continue;
                }
              }
            }
            leftP3.add(block);
          }
        }

        // Algoritmo de partição para a Metade Direita
        final rightP2 = <_ProfileBlockSpec>[];
        final rightP3 = <_ProfileBlockSpec>[];
        double rightHeightP2 = 0.0;

        for (final block in rightSpecs) {
          final double h = _estimateBlockHeight(
            block.label,
            block.content,
            block.isList,
          );
          if (rightHeightP2 + h <= rightLimitP2) {
            rightP2.add(block);
            rightHeightP2 += h;
          } else {
            final double remainingSpace = rightLimitP2 - rightHeightP2;
            if (remainingSpace >= 50.0) {
              if (block.isList) {
                final items = block.getItems();
                final p2Items = <String>[];
                final p3Items = <String>[];
                double currentH = 28.0;

                for (final item in items) {
                  final itemText = item.startsWith('•')
                      ? item.substring(1).trim()
                      : item;
                  final int itemLines = (itemText.length / 75.0).ceil();
                  final double itemH = (itemLines * 9.6) + 2.5;

                  if (rightHeightP2 + currentH + itemH <= rightLimitP2) {
                    p2Items.add(item);
                    currentH += itemH;
                  } else {
                    p3Items.add(item);
                  }
                }

                if (p2Items.isNotEmpty && p3Items.isNotEmpty) {
                  rightP2.add(
                    _ProfileBlockSpec(block.label, p2Items.join('\n')),
                  );
                  rightP3.add(
                    _ProfileBlockSpec(
                      '${block.label} (continuação)',
                      p3Items.join('\n'),
                    ),
                  );
                  rightHeightP2 += currentH;
                  continue;
                }
              } else {
                final paragraphs = block.content.split('\n');
                final p2Paragraphs = <String>[];
                final p3Paragraphs = <String>[];
                double currentH = 28.0;

                for (final para in paragraphs) {
                  final int textLines = para.trim().isEmpty
                      ? 1
                      : (para.trim().length / 80.0).ceil();
                  final double paraH = textLines * 9.6;

                  if (rightHeightP2 + currentH + paraH <= rightLimitP2) {
                    p2Paragraphs.add(para);
                    currentH += paraH;
                  } else {
                    p3Paragraphs.add(para);
                  }
                }

                if (p2Paragraphs.isNotEmpty && p3Paragraphs.isNotEmpty) {
                  rightP2.add(
                    _ProfileBlockSpec(block.label, p2Paragraphs.join('\n')),
                  );
                  rightP3.add(
                    _ProfileBlockSpec(
                      '${block.label} (continuação)',
                      p3Paragraphs.join('\n'),
                    ),
                  );
                  rightHeightP2 += currentH;
                  continue;
                }
              }
            }
            rightP3.add(block);
          }
        }

        // Construção dos Widgets da Página 2 Esquerda
        final leftWidgetsP2 = <pw.Widget>[
          pw.Text(
            'Perfil de Apoio TEA',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 30 * PdfPageFormat.mm,
                height: 40 * PdfPageFormat.mm,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600, width: 1),
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(3),
                  ),
                ),
                alignment: pw.Alignment.center,
                child: () {
                  final photoBytes = request.supportProfilePhotoBytes;
                  if (photoBytes != null && photoBytes.isNotEmpty) {
                    return pw.Image(
                      pw.MemoryImage(photoBytes),
                      fit: pw.BoxFit.cover,
                    );
                  }
                  return pw.Text(
                    'Foto 3x4',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  );
                }(),
              ),
              if (preferredName.isNotEmpty ||
                  supportLevel.isNotEmpty ||
                  commText.isNotEmpty) ...[
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (preferredName.isNotEmpty) ...[
                        _buildHeaderField('Me chame de:', preferredName),
                        pw.SizedBox(height: 3),
                      ],
                      if (supportLevel.isNotEmpty) ...[
                        _buildHeaderField('Nível de suporte:', supportLevel),
                        if (commText.isNotEmpty) pw.SizedBox(height: 3),
                      ],
                      if (commText.isNotEmpty) ...[
                        _buildHeaderField('Como me comunico:', commText),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 5),
          ...leftP2.map((b) => _buildProfileBlock(b.label, b.content)),
          pw.Spacer(),
          _buildProfileFooter(),
        ];

        // Construção dos Widgets da Página 2 Direita
        final rightWidgetsP2 = <pw.Widget>[
          ...rightP2.map((b) => _buildProfileBlock(b.label, b.content)),
          pw.Spacer(),
          _buildProfileFooter(),
        ];

        // Adiciona Página 2
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: leftWidgetsP2,
                      ),
                    ),
                    pw.Container(
                      width: 16,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'DOBRA',
                            style: pw.TextStyle(
                              fontSize: 4,
                              color: PdfColors.grey500,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Expanded(
                            child: pw.Container(
                              width: 0.8,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  left: pw.BorderSide(
                                    color: PdfColors.grey400,
                                    width: 0.8,
                                    style: pw.BorderStyle.dashed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'DOBRA',
                            style: pw.TextStyle(
                              fontSize: 4,
                              color: PdfColors.grey500,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: rightWidgetsP2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        logStage('adição Página 2');

        // Adiciona Página 3 Condicional se houver blocos excedentes
        if (leftP3.isNotEmpty || rightP3.isNotEmpty) {
          hasPage3 = true;
          final leftWidgetsP3 = <pw.Widget>[
            pw.Text(
              'Perfil de Apoio TEA — continuação',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 6),
            ...leftP3.map((b) => _buildProfileBlock(b.label, b.content)),
            pw.Spacer(),
            _buildProfileFooter(),
          ];

          final rightWidgetsP3 = <pw.Widget>[
            ...rightP3.map((b) => _buildProfileBlock(b.label, b.content)),
            pw.Spacer(),
            _buildProfileFooter(),
          ];

          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
              build: (pw.Context context) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: leftWidgetsP3,
                        ),
                      ),
                      pw.Container(
                        width: 16,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'DOBRA',
                              style: pw.TextStyle(
                                fontSize: 4,
                                color: PdfColors.grey500,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Expanded(
                              child: pw.Container(
                                width: 0.8,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    left: pw.BorderSide(
                                      color: PdfColors.grey400,
                                      width: 0.8,
                                      style: pw.BorderStyle.dashed,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'DOBRA',
                              style: pw.TextStyle(
                                fontSize: 4,
                                color: PdfColors.grey500,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: rightWidgetsP3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          logStage('adição Página 3');
        }
      }
      if (kDebugMode) {
        final totalPagesCount = hasPage3 ? 3 : 2;
        debugPrint('[PrintPDF] Quantidade de páginas: $totalPagesCount');
        debugPrint(
          '[PrintPDF] Página de continuação criada: ${totalPagesCount > 2 ? 'sim' : 'não'}',
        );
      }
    }

    logStage('antes de pdf.save()');
    // Pré-salva o PDF em bytes uma única vez para evitar múltiplas renderizações concorrentes no onLayout
    final pdfBytes = await pdf.save();
    logStage('depois de pdf.save() (geração de bytes)');
    return pdfBytes;
  }

  /// Abre a visualização nativa de impressão com os bytes do PDF
  Future<void> previewPrintCardPdfBytes(Uint8List bytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Carteirinha ConeCTEA',
      format: PdfPageFormat.a4.landscape,
      dynamicLayout: false,
      usePrinterSettings: false,
    );
  }

  /// Compartilha os bytes do PDF usando o menu nativo de compartilhamento
  Future<void> sharePrintCardPdfBytes(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'carteirinha_conectea.pdf');
  }

  /// Método legado de compatibilidade que gera e abre o visualizador diretamente
  Future<void> previewBasicPrintPdf(PrintCardRequest request) async {
    final bytes = await buildPrintCardPdfBytes(request);
    await previewPrintCardPdfBytes(bytes);
  }

  /// Constrói a página do perfil quando não está preenchido
  pw.Widget _buildEmptyProfilePage() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Perfil de Apoio TEA',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Perfil de Apoio TEA não preenchido neste aparelho.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Spacer(),
                _buildProfileFooter(),
              ],
            ),
          ),
          pw.Container(
            width: 16,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'DOBRA',
                  style: pw.TextStyle(
                    fontSize: 4,
                    color: PdfColors.grey500,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Expanded(
                  child: pw.Container(
                    width: 0.8,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(
                          color: PdfColors.grey400,
                          width: 0.8,
                          style: pw.BorderStyle.dashed,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'DOBRA',
                  style: pw.TextStyle(
                    fontSize: 4,
                    color: PdfColors.grey500,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [pw.Spacer(), _buildProfileFooter()],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o rodapé informativo do perfil
  pw.Widget _buildProfileFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Documento comunitário/interno de uso opcional. Não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou qualquer documento oficial.',
                style: pw.TextStyle(
                  fontSize: 6.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 1.5),
              pw.Text(
                'Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                style: pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          'Gerado localmente no aparelho.',
          style: pw.TextStyle(
            fontSize: 5.5,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }

  /// Constrói o esqueleto visual básico da carteirinha (Frente) com opcionais refinados
  pw.Widget _buildFrontCardSkeleton({
    required String displayName,
    required String teaId,
    required String validade,
    required String vinculo,
    String? birthDateAndAge,
    String? bloodType,
    String? cityUf,
    required String status,
    pw.MemoryImage? logoImage,
  }) {
    final isSupport = vinculo.contains('APOIO');
    final isAtiva = status == 'ATIVA';

    return pw.Container(
      width: 142 * PdfPageFormat.mm,
      height: 96 * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: 2.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // TOPO: Cabeçalho com Logos e Pílulas de Validade/Status lado a lado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              logoImage != null
                  ? pw.Container(
                      height: 26,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  : pw.Text(
                      '[Logo ConeCTEA]',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
              pw.Row(
                children: [
                  // Pílula de Validade (Contraste Reforçado)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                      border: pw.Border.all(color: PdfColors.black, width: 0.9),
                    ),
                    child: pw.Text(
                      'Validade: $validade',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  // Pílula de Status (Contraste Reforçado)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: isAtiva ? PdfColors.grey200 : PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 0.9,
                        style: isAtiva
                            ? pw.BorderStyle.solid
                            : pw.BorderStyle.dashed,
                      ),
                    ),
                    child: pw.Text(
                      status,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // Títulos do Cartão
          pw.Text(
            'CARTEIRINHA DE IDENTIFICAÇÃO',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.Text(
            isSupport
                ? 'REDE DE APOIO AO TRANSTORNO DO ESPECTRO AUTISTA'
                : 'PESSOA COM TRANSTORNO DO ESPECTRO AUTISTA',
            style: pw.TextStyle(
              fontSize: 6.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),

          pw.Spacer(),

          // MIOLO: Iniciais do Avatar e Dados do Membro lado a lado
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Avatar circular simulando a identidade digital
              pw.Container(
                width: 46,
                height: 46,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.black, width: 1.8),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  _getInitials(displayName),
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              // Dados Principais
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      displayName,
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    if (birthDateAndAge != null &&
                        birthDateAndAge.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Nascimento: $birthDateAndAge',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 5),
                    // Selos horizontais para Tipo Sanguíneo e Município
                    pw.Row(
                      children: [
                        if (bloodType != null &&
                            bloodType.trim().isNotEmpty) ...[
                          _buildFrontSelo('TIPO SANGUÍNEO', bloodType.trim()),
                          pw.SizedBox(width: 6),
                        ],
                        if (cityUf != null && cityUf.trim().isNotEmpty) ...[
                          _buildFrontSelo('MUNICÍPIO', cityUf.trim()),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.Spacer(),

          // BASE: Token em container destacado e Tag do Vínculo
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Token destacado (Contraste Reforçado)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.black, width: 1.0),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    text: 'TOKEN: ',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                    children: [
                      pw.TextSpan(
                        text: teaId,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pílula do Vínculo (Contraste Reforçado)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.black, width: 1.0),
                ),
                child: pw.Text(
                  vinculo,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Documento de uso interno da Família TEA Bauru. Não substitui RG ou laudo oficial.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey900),
          ),
        ],
      ),
    );
  }

  /// Constrói pequenos selos informativos horizontais na frente da carteirinha
  pw.Widget _buildFrontSelo(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        border: pw.Border.all(color: PdfColors.black, width: 0.9),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          children: [
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o esqueleto visual do Verso com contatos e QR Code real
  pw.Widget _buildBackCardSkeleton(
    PrintCardRequest request, {
    pw.MemoryImage? logoImage,
  }) {
    final List<pw.Widget> identificacaoWidgets = [];
    final List<pw.Widget> contatoWidgets = [];

    // CPF (sempre mascarado)
    if (request.options.includeMaskedCpf) {
      final cpf = request.member.cpf.trim();
      if (cpf.isNotEmpty) {
        final clean = cpf.replaceAll(RegExp(r'\D'), '');
        final cpfMasked = clean.length == 11
            ? '${clean.substring(0, 3)}.***.***-${clean.substring(9, 11)}'
            : cpf;
        identificacaoWidgets.add(_buildBackInfoLine('CPF', cpfMasked));
      }
    }

    // Telefone
    if (request.options.includePhone) {
      final phone =
          (request.phoneOverride != null &&
              request.phoneOverride!.trim().isNotEmpty)
          ? request.phoneOverride!.trim()
          : request.member.phone.trim();
      if (phone.isNotEmpty) {
        contatoWidgets.add(_buildBackInfoLine('TELEFONE', phone));
      }
    }

    // CID (Tag estilizada como na carteirinha digital)
    if (request.options.includeCid) {
      final cid =
          (request.cidOverride != null &&
              request.cidOverride!.trim().isNotEmpty)
          ? request.cidOverride!.trim()
          : request.member.cid.trim();
      if (cid.isNotEmpty) {
        identificacaoWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4.5),
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border.all(color: PdfColors.black, width: 1.0),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.RichText(
              text: pw.TextSpan(
                text: 'CID: ',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                children: [
                  pw.TextSpan(
                    text: cid,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Raça/Cor
    if (request.options.includeRaceColor) {
      final race =
          (request.raceColorOverride != null &&
              request.raceColorOverride!.trim().isNotEmpty)
          ? request.raceColorOverride!.trim()
          : (request.member.racaCor ?? '').trim();
      if (race.isNotEmpty) {
        identificacaoWidgets.add(_buildBackInfoLine('RAÇA/COR', race));
      }
    }

    // Gênero
    if (request.options.includeGender) {
      final gender =
          (request.genderOverride != null &&
              request.genderOverride!.trim().isNotEmpty)
          ? request.genderOverride!.trim()
          : (request.member.gender ?? '').trim();
      if (gender.isNotEmpty) {
        identificacaoWidgets.add(_buildBackInfoLine('GÊNERO', gender));
      }
    }

    // Cidade / UF
    if (request.options.includeCityUf) {
      final cityUf =
          (request.cityUfOverride != null &&
              request.cityUfOverride!.trim().isNotEmpty)
          ? request.cityUfOverride!
          : (request.member.city.trim().isNotEmpty &&
                request.member.state.trim().isNotEmpty)
          ? '${request.member.city} / ${request.member.state}'
          : null;
      if (cityUf != null) {
        identificacaoWidgets.add(_buildBackInfoLine('CIDADE / UF', cityUf));
      }
    }

    // Responsável Principal
    if (request.options.includeResponsible) {
      final overrideName = request.responsibleNameOverride?.trim() ?? '';
      final overridePhone = request.responsiblePhoneOverride?.trim() ?? '';

      final String respName;
      if (overrideName.isNotEmpty) {
        respName = overrideName;
      } else {
        respName = request.member.responsiblePersonName ?? '';
      }

      final String respPhone;
      if (overridePhone.isNotEmpty) {
        respPhone = overridePhone;
      } else {
        respPhone = request.member.responsiblePhone ?? '';
      }

      if (respName.isNotEmpty || respPhone.isNotEmpty) {
        final displayName = respName.isNotEmpty ? respName : 'RESP. PRINC.';
        contatoWidgets.add(
          _buildBackContactLine('RESP. PRINC.', displayName, respPhone),
        );
      }
    }

    // Responsáveis Extras
    for (final extra in request.extraResponsibles) {
      if (extra.hasAnyContent) {
        contatoWidgets.add(
          _buildBackContactLine('RESP. EXTRA', extra.name, extra.phone),
        );
      }
    }

    // Contato de Emergência
    if (request.options.includeEmergencyContacts) {
      final overrideName = request.emergencyNameOverride?.trim() ?? '';
      final overridePhone = request.emergencyPhoneOverride?.trim() ?? '';

      final String emergName;
      if (overrideName.isNotEmpty) {
        emergName = overrideName;
      } else {
        emergName = request.member.emergencyPersonName ?? '';
      }

      final String emergPhone;
      if (overridePhone.isNotEmpty) {
        emergPhone = overridePhone;
      } else {
        emergPhone = request.member.emergencyPhone ?? '';
      }

      if (emergName.isNotEmpty || emergPhone.isNotEmpty) {
        final displayName = emergName.isNotEmpty
            ? emergName
            : 'CONTATO DE EMERGÊNCIA';
        contatoWidgets.add(
          _buildBackContactLine('EMERGÊNCIA', displayName, emergPhone),
        );
      }
    }

    // Contatos de Emergência Extras
    for (final extra in request.extraEmergencyContacts) {
      if (extra.hasAnyContent) {
        contatoWidgets.add(
          _buildBackContactLine('EMERGÊNCIA EXTRA', extra.name, extra.phone),
        );
      }
    }

    // QR Code data (Url de validação ou CardNumber como fallback)
    final qrData = request.activeCard.qrValidationUrl.trim().isNotEmpty
        ? request.activeCard.qrValidationUrl.trim()
        : request.activeCard.cardNumber.trim();

    return pw.Container(
      width: 142 * PdfPageFormat.mm,
      height: 96 * PdfPageFormat.mm,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: 2.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Coluna Esquerda: Informações Adicionais agrupadas por Identificação e Contatos
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INFORMAÇÕES ADICIONAIS',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        width: 30,
                        height: 2.5,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.black,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(2),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (identificacaoWidgets.isNotEmpty) ...[
                              ...identificacaoWidgets,
                              pw.SizedBox(height: 6),
                            ],
                            if (contatoWidgets.isNotEmpty) ...[
                              ...contatoWidgets,
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Carteirinha de uso interno da Família TEA Bauru. Não substitui CIPTEA, RG, CPF ou outro documento oficial. A autenticidade pode ser verificada pelo QR Code.',
                        style: pw.TextStyle(
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),

                // Coluna Direita: Bloco do QR Code e autenticidade (estilo digital)
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // QR Code com borda sutil
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1.5,
                          ),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(5),
                          ),
                          color: PdfColors.grey100,
                        ),
                        child: _debugPdfDisableQr
                            ? pw.Container(
                                width: 82,
                                height: 82,
                                color: PdfColors.grey300,
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'QR Disabled',
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              )
                            : pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: qrData,
                                width: 82,
                                height: 82,
                              ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'VALIDAR AUTENTICIDADE',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      logoImage != null
                          ? pw.Container(
                              height: 20,
                              child: pw.Image(
                                logoImage,
                                fit: pw.BoxFit.contain,
                              ),
                            )
                          : pw.RichText(
                              text: pw.TextSpan(
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                children: [
                                  pw.TextSpan(
                                    text: 'Cone',
                                    style: pw.TextStyle(
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: 'CTEA',
                                    style: pw.TextStyle(
                                      color: PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      pw.Text(
                        'Família TEA Bauru',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '#TODOSPELOAUTISMO',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          // Rodapé do verso
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Documento gerado sem fins clínicos ou comprobatórios governamentais.',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey900,
                    ),
                  ),
                ),
                pw.Text(
                  'Gerado localmente no aparelho.',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBackInfoLine(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4.5),
      child: pw.RichText(
        text: pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          children: [
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBackContactLine(String prefix, String name, String phone) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4.5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$prefix: $name',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          if (phone.isNotEmpty) ...[
            pw.Text(
              'Tel: $phone',
              style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
            ),
          ],
        ],
      ),
    );
  }

  /// Constrói um bloco com conteúdo simulado para o Perfil de Apoio com destaque visual
  pw.Widget _buildProfileBlock(String label, String text) {
    final cleanText = _normalizePdfText(text);
    final List<String> lines = cleanText.split('\n');
    final isList = lines.any((line) => line.trim().startsWith('•'));

    pw.Widget contentWidget;
    if (isList) {
      contentWidget = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: lines.map((line) {
          final cleanLine = line.trim();
          if (cleanLine.isEmpty) return pw.SizedBox.shrink();

          final hasBullet = cleanLine.startsWith('•');
          final itemText = hasBullet
              ? cleanLine.substring(1).trim()
              : cleanLine;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (hasBullet) ...[
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(
                      top: 3.5,
                      left: 1.0,
                      right: 4.5,
                    ),
                    child: pw.Container(
                      width: 3.0,
                      height: 3.0,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.black,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ),
                ],
                pw.Expanded(
                  child: pw.Text(
                    itemText,
                    style: pw.TextStyle(fontSize: 8.0, color: PdfColors.black),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      contentWidget = pw.Text(
        cleanText,
        style: pw.TextStyle(fontSize: 8.0, color: PdfColors.black),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 2),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.7),
              ),
            ),
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9.0,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: contentWidget,
          ),
        ],
      ),
    );
  }

  /// Helper exclusivo para campos do topo do Perfil de Apoio
  pw.Widget _buildHeaderField(String label, String value) {
    final cleanValue = _normalizePdfText(value);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 1.0),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          child: pw.Text(
            cleanValue,
            style: pw.TextStyle(
              fontSize: 8.0,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Formata data de nascimento e idade de forma segura
  String _getBirthDateAndAge(String dob) {
    final cleanDob = dob.trim();
    if (cleanDob.isEmpty) return '';
    try {
      DateTime? dt;
      if (cleanDob.contains('/')) {
        final parts = cleanDob.split('/');
        if (parts.length == 3) {
          dt = DateTime.parse(
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
          );
        }
      } else if (cleanDob.contains('-')) {
        dt = DateTime.parse(cleanDob);
      }
      if (dt != null) {
        final today = DateTime.now();
        int age = today.year - dt.year;
        if (today.month < dt.month ||
            (today.month == dt.month && today.day < dt.day)) {
          age--;
        }
        final formattedDate = cleanDob.contains('/')
            ? cleanDob
            : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        return '$formattedDate · $age anos';
      }
    } catch (_) {}
    return cleanDob;
  }

  /// Extrai as iniciais do nome do membro de forma segura
  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Normaliza caracteres de travessão incompatíveis com a fonte do PDF
  String _normalizePdfText(String text) {
    return text.replaceAll('—', '-').replaceAll('–', '-');
  }

  /// Estima a altura de um bloco de perfil no PDF de forma conservadora
  double _estimateBlockHeight(String label, String content, bool isList) {
    const double baseHeight = 28.0;
    final lines = content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (isList) {
      double contentHeight = 0.0;
      for (final line in lines) {
        final itemText = line.startsWith('•') ? line.substring(1).trim() : line;
        final int itemLines = (itemText.length / 75.0).ceil();
        contentHeight += (itemLines * 9.6) + 2.5;
      }
      return baseHeight + contentHeight;
    } else {
      double contentHeight = 0.0;
      for (final line in lines) {
        final int textLines = line.isEmpty ? 1 : (line.length / 80.0).ceil();
        contentHeight += textLines * 9.6;
      }
      return baseHeight + contentHeight;
    }
  }
}

class _ProfileBlockSpec {
  final String label;
  final String content;
  final bool isList;

  _ProfileBlockSpec(this.label, this.content)
    : isList = content.split('\n').any((line) => line.trim().startsWith('•'));

  List<String> getItems() {
    return content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
