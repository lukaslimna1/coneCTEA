import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

/// Checkbox oficial do Design System V2 do ConeCTEA.
///
/// Segue a identidade visual Night Blue / Dark Glass Premium.
/// Suporta rótulo (label) baseado em [Widget] (para permitir links e textos ricos)
/// e descrição textual opcional.
/// Possui área de toque mínima confortável de 48dp e acessibilidade nativa.
class DsCheckbox extends StatelessWidget {
  /// Estado do checkbox (marcado/desmarcado).
  final bool value;

  /// Callback disparado quando o estado é alterado.
  /// Se for nulo, o checkbox ficará no estado desabilitado.
  final ValueChanged<bool?>? onChanged;

  /// Rótulo do checkbox. Declarado como [Widget] para suportar
  /// textos simples, spans ricos ou widgets com links interativos.
  final Widget label;

  /// Descrição textual opcional exibida abaixo do rótulo.
  final String? description;

  /// Token de intenção visual para personalizar a cor ativa (ex: sucesso, segurança, privacidade, termos).
  /// Se nulo, usará [DsCores.sucesso] por padrão.
  final DsCorVisual? token;

  /// Se o componente está ativo e interativo.
  final bool enabled;

  /// Rótulo opcional de acessibilidade.
  final String? semanticsLabel;

  const DsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    this.token,
    this.enabled = true,
    this.semanticsLabel,
  });

  bool get _isInteractive => enabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final effectiveToken = token ?? DsCores.sucesso;

    // Checkbox propriamente dito (a caixinha interativa)
    final Widget checkboxSquare = Semantics(
      label: semanticsLabel ?? 'Caixa de seleção',
      value: value ? 'Marcado' : 'Desmarcado',
      checked: value,
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
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0), // Raio sutil ideal para caixas de 22x22
              color: value
                  ? effectiveToken.softBackground.withValues(alpha: 0.25)
                  : DsCores.inputBackground,
              border: Border.all(
                color: value
                    ? effectiveToken.accent
                    : Colors.white.withValues(alpha: 0.30),
                width: value ? 2.0 : 1.5,
              ),
              boxShadow: value
                  ? DsSombras.glow(effectiveToken.accent, alpha: 0.06, blurRadius: 8)
                  : DsSombras.none,
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: value ? 1.0 : 0.0,
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: effectiveToken.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: _isInteractive ? 1.0 : 0.55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          checkboxSquare,
          const SizedBox(width: DsEspacamentos.sm),
          Expanded(
            child: GestureDetector(
              onTap: _isInteractive ? () => onChanged!(!value) : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0), // Centraliza levemente com a área de toque do checkbox
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label,
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
          ),
        ],
      ),
    );
  }
}
