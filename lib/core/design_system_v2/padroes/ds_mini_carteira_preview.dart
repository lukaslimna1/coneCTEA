import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// Padrão unificado de casca de carteirinha do Design System V2 do ConeCTEA.
///
/// Componente estritamente puro e de apresentação, ideal para exibirPreviews
/// de carteirinhas de identificação ativas ou pendentes com moldura premium Dark Glass,
/// acento e glow semântico a partir do status, e suporte a injeção por slots.
class DsMiniCarteiraPreview extends StatelessWidget {
  /// O widget que representa a carteirinha em si (ex: DigitalCardWidget)
  final Widget cardWidget;

  /// A chave técnica do status para definir a cor do acento, glow e selo (ex: active, waiting_docs)
  final String? status;

  /// Indica se a carteirinha está pendente
  final bool isPending;

  /// Se deve exibir o selo de status centralizado sobreposto ao preview
  final bool showStatusSeal;

  /// Se deve reduzir a opacidade do preview da carteirinha quando estiver pendente
  final bool dimWhenPending;

  /// Widget informativo opcional renderizado logo abaixo do preview do cartão (ex: protocolo/requerimento)
  final Widget? footerInfo;

  /// Widget de ações opcionais renderizado abaixo do footerInfo (ex: botão de suporte/CTA)
  final Widget? actionSection;

  /// Ação opcional ao tocar no preview da carteirinha
  final VoidCallback? onTap;

  /// Descrição semântica de acessibilidade para o cartão
  final String? semanticsLabel;

  /// Se o selo de status deve usar a versão curta (shortLabel) do token
  final bool statusSealShortLabel;

  /// String opcional para sobrescrever o label exibido no selo de status
  final String? statusSealLabelOverride;

  const DsMiniCarteiraPreview({
    super.key,
    required this.cardWidget,
    this.status,
    this.isPending = false,
    this.showStatusSeal = false,
    this.dimWhenPending = true,
    this.statusSealShortLabel = true,
    this.statusSealLabelOverride,
    this.footerInfo,
    this.actionSection,
    this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusToken = DsTokenStatus.fromStatus(status);
    final statusColor = statusToken.primary;
    final localFooter = footerInfo;
    final localAction = actionSection;

    return Semantics(
      label: semanticsLabel ?? statusToken.semanticLabel,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0A192F), // Tom de fundo profundo premium
              Color(0xFF060D1A), // Quase preto
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(
              0x2494A3B4,
            ), // Padrão premium de borda translúcida
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Camada de vidro sutil
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.025),
                ),
              ),
            ),

            // Efeito de luz sutil no canto inferior direito (Glow dinâmico)
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.12),
                      statusColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Borda superior colorida (Acento Premium Semântico)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Bloco de Preview da Carteirinha (ID-1 AspectRatio)
                  GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: AspectRatio(
                      aspectRatio: 1.58,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: isPending && dimWhenPending ? 0.6 : 1.0,
                              child: cardWidget,
                            ),
                            if (showStatusSeal && status != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.55),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 10,
                                      offset: Offset.zero,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusToken.icon,
                                      size: 14.0,
                                      color: statusToken.iconColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        (statusSealLabelOverride ??
                                                (statusSealShortLabel
                                                    ? statusToken.shortLabel
                                                    : statusToken.label))
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                          height: 1.1,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Elementos Dinâmicos injetados por Slots
                  ?localFooter,
                  ?localAction,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
