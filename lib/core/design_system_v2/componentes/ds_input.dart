import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

/// Campo de texto oficial do Design System V2 do ConeCTEA.
///
/// Este componente define apenas a camada visual e estrutural do input.
/// Ele NÃO valida CPF, NÃO acessa Supabase, NÃO navega, NÃO persiste dados
/// e NÃO contém regra de negócio.
///
/// Responsabilidades:
/// - visual Night Blue / Dark Glass;
/// - label externo legível;
/// - hint com contraste seguro;
/// - bordas e foco padronizados;
/// - suporte a ícone, sufixo, helper, erro, máscara e teclado;
/// - altura mínima confortável para toque;
/// - compatibilidade com formulários Flutter.
///
/// Regras:
/// - validações devem ser recebidas por callback;
/// - controllers pertencem à tela/feature;
/// - máscaras pertencem à tela/feature;
/// - lógica sensível permanece fora da DS V2.
class DsInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final String? semanticsLabel;

  const DsInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autofillHints,
    this.semanticsLabel,
  })  : assert(maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(!obscureText || maxLines == 1);

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        enabled ? DsCores.textPrimary : DsCores.textMuted;

    final effectiveIconColor =
        enabled ? DsCores.iconSecondary : DsCores.iconMuted;

    return Semantics(
      label: semanticsLabel ?? label,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DsTipografia.label.copyWith(
              color: enabled ? DsCores.textSecondary : DsCores.textMuted,
            ),
          ),
          const SizedBox(height: DsEspacamentos.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DsTamanhos.inputHeight,
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              readOnly: readOnly,
              autofocus: autofocus,
              obscureText: obscureText,
              maxLines: maxLines,
              minLines: minLines,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              inputFormatters: inputFormatters,
              validator: validator,
              onChanged: onChanged,
              onFieldSubmitted: onFieldSubmitted,
              onTap: onTap,
              autofillHints: autofillHints,
              cursorColor: DsCores.primary,
              style: DsTipografia.body.copyWith(
                color: effectiveTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                helperText: helperText,
                errorText: errorText,
                helperMaxLines: 2,
                errorMaxLines: 3,
                filled: true,
                fillColor: enabled
                    ? DsCores.inputBackground.withValues(alpha: 0.64)
                    : DsCores.surface.withValues(alpha: 0.38),
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: DsEspacamentos.md,
                  horizontal: DsEspacamentos.md,
                ),
                hintStyle: DsTipografia.bodySmall.copyWith(
                  color: DsCores.inputPlaceholder,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                helperStyle: DsTipografia.caption.copyWith(
                  color: DsCores.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                errorStyle: DsTipografia.caption.copyWith(
                  color: DsCores.danger,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                prefixIcon: icon == null ? null : Icon(icon),
                prefixIconColor: effectiveIconColor,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: DsTamanhos.inputHeight,
                  minHeight: DsTamanhos.inputHeight,
                ),
                suffixIcon: suffixIcon,
                suffixIconColor: effectiveIconColor,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: DsTamanhos.inputHeight,
                  minHeight: DsTamanhos.inputHeight,
                ),
                border: _border(
                  DsCores.inputBorder.withValues(alpha: 0.45),
                  1,
                ),
                enabledBorder: _border(
                  DsCores.inputBorder.withValues(alpha: 0.55),
                  1,
                ),
                focusedBorder: _border(
                  DsCores.primary.withValues(alpha: 0.95),
                  1.6,
                ),
                disabledBorder: _border(
                  DsCores.border.withValues(alpha: 0.28),
                  1,
                ),
                errorBorder: _border(
                  DsCores.danger.withValues(alpha: 0.70),
                  1.2,
                ),
                focusedErrorBorder: _border(
                  DsCores.danger,
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
