import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';
import 'print_active_card_selection_sheet.dart';
import 'print_type_decision_sheet.dart';
import 'print_review_info_sheet.dart';
import 'print_support_profile_sheet.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_request.dart';


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
              Text(
                'Versão para impressão',
                style: DsTipografia.cardTitle,
              ),
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
                  final Member? selected = await PrintActiveCardSelectionSheet.show(
                    context,
                    activeMembers: activeMembers,
                    activeCardsMap: activeCardsMap,
                    paletteSeed: paletteSeed,
                  );
                  if (selected != null && context.mounted) {
                    // Abre a Bottom Sheet de decisão condicional por tipo
                    final String? decision = await PrintTypeDecisionSheet.show(
                      context,
                      member: selected,
                    );
                    if (decision != null && context.mounted) {
                      // Abre a nova Bottom Sheet de Revisão das Informações
                      // Abre a nova Bottom Sheet de Revisão das Informações e recebe a requisição estruturada
                      final PrintCardRequest? printRequest = await PrintReviewInfoSheet.show(
                        context,
                        member: selected,
                        includeProfile: decision == 'include_profile',
                      );

                      if (printRequest != null && context.mounted) {
                        if (printRequest.includeProfile) {
                          // Abre a Bottom Sheet do Perfil de Apoio TEA
                          final bool? supportContinue = await PrintSupportProfileSheet.show(
                            context,
                            member: selected,
                          );

                          if (supportContinue == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Próxima etapa: preparar visualização da impressão.'),
                                backgroundColor: DsCores.carteirinha.accent,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Próxima etapa: preparar visualização da impressão.'),
                              backgroundColor: DsCores.carteirinha.accent,
                              duration: const Duration(seconds: 4),
                            ),
                          );
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
