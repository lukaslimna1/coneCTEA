import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';
import 'print_active_card_selection_sheet.dart';
import 'print_type_decision_sheet.dart';
import 'print_review_info_sheet.dart';
import 'print_support_profile_sheet.dart';
import 'print_actions_bottom_sheet.dart';
import 'package:conectea/features/carteirinhas/services/print_card_pdf_service.dart';

/// **PrintModeEntryCard**
/// Componente de entrada visual discreto e premium para o fluxo
/// de visualização/geração do PDF de impressão da carteirinha comunitária.
class PrintModeEntryCard extends StatelessWidget {
  final bool isActive;
  final List<Member> activeMembers;
  final Map<String, DigitalCard> activeCardsMap;
  final String? paletteSeed;

  const PrintModeEntryCard({
    super.key,
    required this.isActive,
    required this.activeMembers,
    required this.activeCardsMap,
    this.paletteSeed,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      showTopAccent: true,
      accentColor: DsCores.carteirinha.accent,
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0), // Respiro de 20px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e Título do Card
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.printer,
                color: DsCores.carteirinha.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Versão para impressão', style: DsTipografia.cardTitle),
            ],
          ),
          const SizedBox(height: 8),

          // Descrição do Card (voz ativa de produto)
          Text(
            'Gere uma versão em PDF da carteirinha comunitária para imprimir. Você poderá escolher quais informações opcionais deseja incluir.',
            style: DsTipografia.cardDescription,
          ),
          const SizedBox(height: 20),

          // Botão e Observação do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Observação
              Expanded(
                child: Text(
                  'Disponível para carteirinhas ativas.',
                  style: DsTipografia.cardMuted,
                ),
              ),
              const SizedBox(width: 16),
              // Botão (Abre a Bottom Sheet de Seleção de Carteirinha Ativa)
              DsBotao(
                label: 'Começar',
                variante: DsBotaoVariante.acao,
                token: DsCores.carteirinha,
                icon: PhosphorIconsRegular.caretRight,
                fullWidth: false,
                onPressed: () async {
                  final Member? selected =
                      await PrintActiveCardSelectionSheet.show(
                        context,
                        activeMembers: activeMembers,
                        activeCardsMap: activeCardsMap,
                        paletteSeed: paletteSeed,
                      );
                  if (selected != null && context.mounted) {
                    final activeCard = activeCardsMap[selected.id];
                    if (activeCard == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Não foi possível localizar a carteirinha ativa para impressão.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    // Abre a Bottom Sheet de decisão condicional por tipo
                    final String? decision = await PrintTypeDecisionSheet.show(
                      context,
                      member: selected,
                    );
                    if (decision != null && context.mounted) {
                      // Abre a nova Bottom Sheet de Revisão das Informações
                      // Abre a nova Bottom Sheet de Revisão das Informações e recebe a requisição estruturada
                      var printRequest = await PrintReviewInfoSheet.show(
                        context,
                        member: selected,
                        activeCard: activeCard,
                        includeProfile: decision == 'include_profile',
                      );

                      if (printRequest != null && context.mounted) {
                        bool shouldGeneratePdf = false;
                        if (printRequest.includeProfile) {
                          // Abre a Bottom Sheet do Perfil de Apoio TEA
                          final supportResult =
                              await PrintSupportProfileSheet.show(
                                context,
                                member: selected,
                              );
                          if (supportResult != null &&
                              supportResult.continuePrint) {
                            shouldGeneratePdf = true;
                            printRequest = printRequest.copyWith(
                              supportProfilePhotoBytes:
                                  supportResult.photoBytes,
                              clearSupportProfilePhoto:
                                  supportResult.photoBytes == null,
                            );
                          }
                        } else {
                          shouldGeneratePdf = true;
                        }

                        if (shouldGeneratePdf && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Preparando documento de impressão...',
                              ),
                              backgroundColor: DsCores.carteirinha.accent,
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          try {
                            // Gera os bytes do PDF na memória de forma estritamente local (Tarefa 4)
                            final pdfBytes = await PrintCardPdfService()
                                .buildPrintCardPdfBytes(printRequest);

                            if (context.mounted) {
                              // Abre a nova Bottom Sheet de ações do PDF
                              await PrintActionsBottomSheet.show(
                                context,
                                onPreview: () async {
                                  try {
                                    await PrintCardPdfService()
                                        .previewPrintCardPdfBytes(pdfBytes);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Não foi possível abrir a visualização agora.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                                onShare: () async {
                                  try {
                                    await PrintCardPdfService()
                                        .sharePrintCardPdfBytes(pdfBytes);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Não foi possível compartilhar o PDF agora.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            }
                          } catch (error, stackTrace) {
                            if (kDebugMode) {
                              debugPrint(
                                '[ModoImpressao] Falha ao preparar PDF: ${error.runtimeType}',
                              );
                              debugPrint(
                                '[ModoImpressao] Detalhe técnico: $error',
                              );
                              debugPrint(
                                '[ModoImpressao] StackTrace: $stackTrace',
                              );
                            }
                            // Captura silenciosa e segura em caso de erros de preparação
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Não foi possível preparar a versão para impressão agora.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
