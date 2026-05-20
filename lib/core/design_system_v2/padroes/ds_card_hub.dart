import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/componentes/ds_card.dart';
import 'package:conectea/core/design_system_v2/componentes/ds_moldura_icone.dart';
import 'package:conectea/core/design_system_v2/componentes/ds_selo.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tokens_visuais.dart';

/// Layouts disponíveis para o card de Hub.
enum DsCardHubLayout {
  vertical,
  horizontal,
}

/// Card oficial para hubs e entradas de módulos no Design System V2.
///
/// Este padrão compõe:
/// - DsCard para a casca Dark Glass;
/// - DsMolduraIcone para o ícone premium;
/// - DsSelo para etiquetas genéricas;
/// - DsTokenVisual para semântica visual não ligada a status.
///
/// Não usar este componente para status de carteirinha/solicitação.
class DsCardHub extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final DsTokenVisual token;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? badgeText;
  final bool enabled;
  final bool compact;
  final bool showChevron;
  final DsCardHubLayout layout;
  final double? badgeMaxWidth;

  const DsCardHub({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.token,
    this.onTap,
    this.trailing,
    this.badgeText,
    this.enabled = true,
    this.compact = false,
    this.showChevron = true,
    this.layout = DsCardHubLayout.horizontal,
    this.badgeMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = compact
        ? const EdgeInsets.symmetric(
            vertical: DsEspacamentos.md,
            horizontal: DsEspacamentos.md,
          )
        : const EdgeInsets.all(DsEspacamentos.lg);

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: DsCard(
        accentColor: enabled ? token.accent : null,
        showTopAccent: enabled,
        showGlow: enabled,
        onTap: enabled ? onTap : null,
        padding: effectivePadding,
        child: layout == DsCardHubLayout.horizontal
            ? _buildHorizontalLayout()
            : _buildVerticalLayout(),
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    final effectiveTrailing = _buildTrailing();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIcon(),
        const SizedBox(width: DsEspacamentos.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _buildTitle(maxLines: 1)),
                  if (badgeText != null) ...[
                    const SizedBox(width: DsEspacamentos.xs),
                    _buildBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              _buildDescription(maxLines: compact ? 1 : 2),
            ],
          ),
        ),
        if (effectiveTrailing != null) ...[
          const SizedBox(width: DsEspacamentos.md),
          effectiveTrailing,
        ],
      ],
    );
  }

  Widget _buildVerticalLayout() {
    final effectiveTrailing = _buildTrailing();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIcon(),
            if (effectiveTrailing != null) ...[
              effectiveTrailing,
            ],
          ],
        ),
        const SizedBox(height: DsEspacamentos.md),
        if (badgeText != null) ...[
          _buildBadge(),
          const SizedBox(height: DsEspacamentos.sm),
        ],
        _buildTitle(maxLines: 2),
        const SizedBox(height: 6),
        _buildDescription(maxLines: compact ? 2 : 3),
      ],
    );
  }

  Widget _buildIcon() {
    final size = compact ? DsTamanhos.iconFrameSm : DsTamanhos.iconFrameMd;

    return DsMolduraIcone(
      icon: icon,
      accentColor: token.accent,
      size: size,
      iconSize: compact ? DsTamanhos.iconSm : DsTamanhos.iconMd,
      subtleGlow: enabled,
    );
  }

  Widget _buildBadge() {
    return DsSelo.fromTokenVisual(
      label: badgeText!,
      token: token,
      compact: true,
      maxWidth: badgeMaxWidth ?? (compact ? 72.0 : 96.0),
    );
  }

  Widget? _buildTrailing() {
    if (trailing != null) {
      return trailing;
    }

    if (!showChevron || onTap == null) {
      return null;
    }

    return Icon(
      Icons.chevron_right_rounded,
      color: token.accent.withValues(alpha: enabled ? 0.85 : 0.35),
      size: compact ? 20 : 22,
    );
  }

  Widget _buildTitle({required int maxLines}) {
    return Text(
      title,
      style: DsTipografia.cardTitle.copyWith(
        fontSize: compact ? 16 : 18,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }

  Widget _buildDescription({required int maxLines}) {
    return Text(
      description,
      style: compact ? DsTipografia.cardMuted : DsTipografia.cardDescription,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
