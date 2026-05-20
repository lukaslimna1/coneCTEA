import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/componentes/ds_selo.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tokens_status.dart';

/// Selo específico para status de carteirinha e solicitação.
///
/// Este padrão compõe:
/// - DsTokenStatus para resolver a semântica visual do status;
/// - DsSelo para renderizar a base visual do selo.
///
/// Não usar para tags genéricas como "Em breve", "Beta" ou "Protegido".
/// Para esses casos, usar DsSelo diretamente.
class DsSeloStatus extends StatelessWidget {
  final String? status;
  final DsTokenStatus? token;
  final bool compact;
  final bool shortLabel;
  final bool uppercase;
  final bool showIcon;
  final double borderWidth;
  final double? maxWidth;
  final String? semanticsLabel;

  const DsSeloStatus({
    super.key,
    this.status,
    this.token,
    this.compact = false,
    this.shortLabel = true,
    this.uppercase = true,
    this.showIcon = true,
    this.borderWidth = 1.0,
    this.maxWidth,
    this.semanticsLabel,
  }) : assert(borderWidth >= 0);

  @override
  Widget build(BuildContext context) {
    final effectiveToken = token ?? DsTokenStatus.fromStatus(status);
    final effectiveLabel =
        shortLabel ? effectiveToken.shortLabel : effectiveToken.label;

    return Semantics(
      label: semanticsLabel ?? effectiveToken.semanticLabel,
      child: ExcludeSemantics(
        child: DsSelo(
          label: effectiveLabel,
          labelColor: effectiveToken.primary,
          backgroundColor: effectiveToken.pillBackground,
          borderColor: effectiveToken.pillBorder,
          icon: showIcon ? effectiveToken.icon : null,
          iconColor: effectiveToken.iconColor,
          compact: compact,
          uppercase: uppercase,
          borderWidth: borderWidth,
          maxWidth: maxWidth,
        ),
      ),
    );
  }
}
