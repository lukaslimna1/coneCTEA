import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

/// Switch oficial do Design System V2 do ConeCTEA.
///
/// Segue a identidade visual Night Blue / Dark Glass Premium.
/// Suporta rótulo (label) e descrição detalhada integrados.
/// Possui área de toque mínima confortável de 48dp e acessibilidade nativa.
class DsSwitch extends StatelessWidget {
  /// Estado do switch (ativo/inativo).
  final bool value;

  /// Callback disparado quando o estado é alterado.
  /// Se for nulo, o switch ficará no estado desabilitado.
  final ValueChanged<bool>? onChanged;

  /// Rótulo curto opcional.
  final String? label;

  /// Descrição textual opcional exibida abaixo do rótulo.
  final String? description;

  /// Token de intenção visual para personalizar a cor ativa (ex: sucesso, segurança, privacidade).
  /// Se nulo, usará [DsCores.seguranca] por padrão.
  final DsCorVisual? token;

  /// Se o componente está ativo e interativo.
  final bool enabled;

  /// Rótulo opcional de acessibilidade.
  final String? semanticsLabel;

  const DsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.token,
    this.enabled = true,
    this.semanticsLabel,
  });

  bool get _isInteractive => enabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final effectiveToken = token ?? DsCores.seguranca;

    // Switch propriamente dito (a chave interativa)
    final Widget switchToggle = Semantics(
      label: semanticsLabel ?? label ?? 'Chave de seleção',
      value: value ? 'Ativado' : 'Desativado',
      toggled: value,
      enabled: _isInteractive,
      child: GestureDetector(
        onTap: _isInteractive ? () => onChanged!(!value) : null,
        child: Container(
          // Garante a área mínima de toque confortável de 48dp conforme DsTamanhos.minTouchTarget
          width: DsTamanhos.minTouchTarget,
          height: DsTamanhos.minTouchTarget,
          alignment: Alignment.center,
          color: Colors.transparent, // Área invisível clicável
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DsRaios.pill),
              color: value
                  ? effectiveToken.softBackground.withValues(alpha: 0.25)
                  : DsCores.inputBackground,
              border: Border.all(
                color: value
                    ? effectiveToken.accent.withValues(alpha: 0.50)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: value
                  ? DsSombras.glow(effectiveToken.accent, alpha: 0.08, blurRadius: 10)
                  : DsSombras.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? effectiveToken.accent : DsCores.textSecondary,
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: effectiveToken.accent.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            )
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Se não houver label nem descrição, renderiza apenas o switch puro
    if (label == null && description == null) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isInteractive ? 1.0 : 0.55,
        child: switchToggle,
      );
    }

    // Caso contrário, renderiza layout estruturado (label + descrição + switch)
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: _isInteractive ? 1.0 : 0.55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isInteractive ? () => onChanged!(!value) : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: DsTipografia.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: DsCores.textPrimary,
                      ),
                    ),
                  if (description != null) ...[
                    const SizedBox(height: DsEspacamentos.xs),
                    Text(
                      description!,
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: DsEspacamentos.md),
          switchToggle,
        ],
      ),
    );
  }
}
