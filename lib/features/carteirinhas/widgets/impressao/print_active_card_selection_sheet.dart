import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';


/// **PrintActiveCardSelectionSheet**
/// Diálogo modal bottom sheet que permite ao usuário ou responsável escolher
/// uma das carteirinhas ativas do sistema para preencher as opções de impressão.
class PrintActiveCardSelectionSheet extends StatefulWidget {
  final List<Member> activeMembers;
  final Map<String, DigitalCard> activeCardsMap;
  final String? paletteSeed;

  const PrintActiveCardSelectionSheet({
    super.key,
    required this.activeMembers,
    required this.activeCardsMap,
    this.paletteSeed,
  });

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<Member?> show(
    BuildContext context, {
    required List<Member> activeMembers,
    required Map<String, DigitalCard> activeCardsMap,
    String? paletteSeed,
  }) {
    return showModalBottomSheet<Member>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintActiveCardSelectionSheet(
          activeMembers: activeMembers,
          activeCardsMap: activeCardsMap,
          paletteSeed: paletteSeed,
        );
      },
    );
  }

  @override
  State<PrintActiveCardSelectionSheet> createState() =>
      _PrintActiveCardSelectionSheetState();
}

class _PrintActiveCardSelectionSheetState
    extends State<PrintActiveCardSelectionSheet> {
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    // Seleção automática do primeiro se houver apenas um
    if (widget.activeMembers.length == 1) {
      _selectedMemberId = widget.activeMembers.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveCards = widget.activeMembers.isNotEmpty;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      decoration: BoxDecoration(
        color: DsCores.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DsRaios.card),
          topRight: Radius.circular(DsRaios.card),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.80,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alça de arraste visual (Drag Handle)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Título e Ícone
                Row(
                  children: [
                    Icon(
                      PhosphorIconsBold.printer,
                      color: DsCores.carteirinha.accent,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Escolha a carteirinha',
                        style: DsTipografia.sectionTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Texto explicativo
                Text(
                  'Selecione qual carteirinha ativa você deseja preparar para impressão. Somente carteirinhas ativas aparecem aqui.',
                  style: DsTipografia.infoBody,
                ),
                const SizedBox(height: 20),

                // Lista de Carteirinhas Ativas
                if (!hasActiveCards)
                  // Estado Informativo / Vazio se não houver carteirinhas ativas
                  DsCard(
                    borderColor: DsCores.alerta.border,
                    backgroundColor: DsCores.alerta.softBackground.withValues(alpha: 0.1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          PhosphorIconsRegular.shieldWarning,
                          color: DsCores.alerta.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nenhuma carteirinha ativa disponível para impressão.',
                                style: DsTipografia.cardTitle.copyWith(
                                  color: DsCores.alerta.accent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A versão para impressão só pode ser gerada para carteirinhas ativas.',
                                style: DsTipografia.cardDescription.copyWith(
                                  color: DsCores.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Lista de opções rolável com Flexible
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.activeMembers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = widget.activeMembers[index];
                        final card = widget.activeCardsMap[member.id];
                        final isSelected = member.id == _selectedMemberId;

                        if (card == null) return const SizedBox.shrink();

                        return DsCard(
                          borderColor: isSelected
                              ? DsCores.carteirinha.accent
                              : Colors.white.withValues(alpha: 0.08),
                          borderWidth: isSelected ? 1.6 : 1.0,
                          backgroundColor: isSelected
                              ? DsCores.carteirinha.softBackground.withValues(alpha: 0.06)
                              : DsCores.surfaceElevated.withValues(alpha: 0.35),
                          showGlow: isSelected,
                          accentColor: DsCores.carteirinha.accent,
                          onTap: () {
                            setState(() {
                              _selectedMemberId = member.id;
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar Oficial da DS V2
                              DsAvatar(
                                initials: member.initials,
                                size: 40.0,
                                paletteSeed: widget.paletteSeed,
                                isSelected: isSelected,
                              ),
                              const SizedBox(width: 14),

                              // Informações de Nome e Vínculo (Discreto e Seguro contra Overflow)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      member.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: DsTipografia.cardTitle.copyWith(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.teaRelationLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: DsTipografia.caption.copyWith(
                                        color: DsCores.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Indicador de Seleção Simples
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? DsCores.carteirinha.accent
                                        : Colors.white.withValues(alpha: 0.3),
                                    width: isSelected ? 6 : 1.5,
                                  ),
                                  color: isSelected ? Colors.transparent : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: DsBotao(
                        label: 'Cancelar',
                        variante: DsBotaoVariante.secundario,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DsBotao(
                        label: 'Continuar',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.sucesso,
                        // Habilita se houver cartão ativo e seleção válida
                        onPressed: (_selectedMemberId != null && hasActiveCards)
                            ? () {
                                final selectedMember = widget.activeMembers.firstWhere(
                                  (m) => m.id == _selectedMemberId,
                                );
                                Navigator.pop(context, selectedMember);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
