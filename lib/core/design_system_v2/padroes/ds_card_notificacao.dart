import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Padrão de Card de Notificação oficial da DS V2.
///
/// Componente stateful responsável por exibir notificações estruturadas.
/// Gerencia a expansão de textos longos e ações customizadas futuras,
/// suportando status persistidos ou intenções visuais puras.
class DsCardNotificacao extends StatefulWidget {
  final String titulo;
  final String mensagem;
  final String? dataTexto;
  final IconData icone;
  final DsCorVisual? visual;
  final DsTokenStatus? status;
  final bool lida;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final bool expansivel;
  final int maxLinhasMensagem;

  const DsCardNotificacao({
    super.key,
    required this.titulo,
    required this.mensagem,
    this.dataTexto,
    required this.icone,
    this.visual,
    this.status,
    this.lida = true,
    this.onTap,
    this.actionLabel,
    this.onActionTap,
    this.expansivel = true,
    this.maxLinhasMensagem = 2,
  });

  @override
  State<DsCardNotificacao> createState() => _DsCardNotificacaoState();
}

class _DsCardNotificacaoState extends State<DsCardNotificacao> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    // 1. Resolve a semântica de cor
    final Color accentColor = widget.status?.primary ??
        widget.visual?.accent ??
        DsCores.fallback.accent;

    // 2. Resolve a lógica de expansão
    final bool isLongMessage = widget.mensagem.length > 90; // heurística básica
    final bool hasAction =
        widget.actionLabel != null && widget.actionLabel!.isNotEmpty;

    return DsCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      hasGradient: true,
      onTap: () {
        // Ao tocar no card, dispara onTap da feature e alterna expansão
        widget.onTap?.call();
        if (widget.expansivel && isLongMessage) {
          setState(() {
            _expandido = !_expandido;
          });
        }
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Acento lateral
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: widget.lida
                    ? accentColor.withValues(alpha: 0.5)
                    : accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DsRaios.card),
                  bottomLeft: Radius.circular(DsRaios.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DsEspacamentos.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone destacado
                    DsMolduraIcone(
                      icon: widget.icone,
                      accentColor: accentColor,
                      size: 42,
                      iconSize: DsTamanhos.iconMd,
                      radius: DsRaios.md,
                      subtleGlow: !widget.lida,
                    ),
                    const SizedBox(width: DsEspacamentos.md),
                    // Conteúdo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.titulo,
                                  style: DsTipografia.cardTitle,
                                ),
                              ),
                              if (!widget.lida)
                                Container(
                                  margin: const EdgeInsets.only(
                                      top: 4, left: DsEspacamentos.xs),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: DsSombras.glow(accentColor,
                                        alpha: 0.5, blurRadius: 4),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: DsEspacamentos.xs),
                          Text(
                            widget.mensagem,
                            maxLines: (widget.expansivel && !_expandido)
                                ? widget.maxLinhasMensagem
                                : null,
                            overflow: (widget.expansivel && !_expandido)
                                ? TextOverflow.ellipsis
                                : null,
                            style: DsTipografia.cardDescription,
                          ),
                          if (widget.expansivel && isLongMessage) ...[
                            const SizedBox(height: DsEspacamentos.xs),
                            Text(
                              _expandido ? 'Ver menos' : 'Ver mais',
                              style: DsTipografia.label
                                  .copyWith(color: DsCores.textSecondary),
                            ),
                          ],
                          if (widget.dataTexto != null) ...[
                            const SizedBox(height: DsEspacamentos.sm),
                            Row(
                              children: [
                                const Icon(PhosphorIconsRegular.clock,
                                    size: 14, color: DsCores.iconMuted),
                                const SizedBox(width: DsEspacamentos.xs),
                                Text(
                                  widget.dataTexto!,
                                  style: DsTipografia.cardMuted,
                                ),
                              ],
                            ),
                          ],
                          if (hasAction) ...[
                            const SizedBox(height: DsEspacamentos.md),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () {
                                  // Separado do clique principal do card
                                  widget.onActionTap?.call();
                                },
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: DsEspacamentos.md),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.actionLabel!,
                                        style: DsTipografia.label
                                            .copyWith(color: accentColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
