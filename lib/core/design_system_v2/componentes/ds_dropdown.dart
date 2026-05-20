import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

/// Componente de Dropdown oficial do Design System V2 do ConeCTEA.
///
/// Este componente define apenas a camada visual e estrutural do dropdown.
/// Ele NÃO acessa Supabase, NÃO navega, NÃO persiste dados
/// e NÃO contém regra de negócio.
class DsDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? semanticsLabel;

  const DsDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.helperText,
    this.errorText,
    this.icon,
    this.enabled = true,
    this.validator,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        enabled ? DsCores.textPrimary : DsCores.textMuted;

    final effectiveIconColor =
        enabled ? DsCores.inputIcon : DsCores.iconMuted;

    return Semantics(
      label: semanticsLabel ?? label,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DsTipografia.inputLabel.copyWith(
              color: enabled ? DsCores.textPrimary : DsCores.textMuted,
            ),
          ),
          const SizedBox(height: DsEspacamentos.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DsTamanhos.inputHeight,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: DsTipografia.inputText.copyWith(
                      color: effectiveTextColor,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
              validator: validator,
              dropdownColor: DsCores.surfaceCard,
              icon: Icon(
                Icons.arrow_drop_down,
                color: enabled ? DsCores.inputSuffixIcon : DsCores.iconMuted,
              ),
              style: DsTipografia.inputText.copyWith(
                color: effectiveTextColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                helperText: helperText,
                errorText: errorText,
                helperMaxLines: 2,
                errorMaxLines: 3,
                filled: true,
                fillColor: enabled
                    ? DsCores.inputBackground
                    : DsCores.surface.withValues(alpha: 0.38),
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: DsEspacamentos.md,
                  horizontal: DsEspacamentos.md,
                ),
                hintStyle: DsTipografia.inputHint,
                helperStyle: DsTipografia.caption.copyWith(
                  color: DsCores.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                errorStyle: DsTipografia.caption.copyWith(
                  color: DsCores.perigo.accent,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                prefixIcon: icon == null ? null : Icon(icon),
                prefixIconColor: effectiveIconColor,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: DsTamanhos.inputHeight,
                  minHeight: DsTamanhos.inputHeight,
                ),
                border: _border(
                  DsCores.inputBorder,
                  1,
                ),
                enabledBorder: _border(
                  DsCores.inputBorder,
                  1,
                ),
                focusedBorder: _border(
                  DsCores.inputFocusBorder,
                  1.5,
                ),
                disabledBorder: _border(
                  DsCores.border.withValues(alpha: 0.28),
                  1,
                ),
                errorBorder: _border(
                  DsCores.perigo.accent.withValues(alpha: 0.70),
                  1.2,
                ),
                focusedErrorBorder: _border(
                  DsCores.perigo.accent,
                  1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(DsRaios.input),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}
