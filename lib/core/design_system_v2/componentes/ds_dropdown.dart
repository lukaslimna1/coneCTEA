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
            child: _DsDropdownFormField(
              value: value,
              validator: validator,
              enabled: enabled,
              builder: (FormFieldState<String> field) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return MenuAnchor(
                      crossAxisUnconstrained: false,
                      style: MenuStyle(
                        backgroundColor: WidgetStateProperty.all(DsCores.glassStrong),
                        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                        elevation: WidgetStateProperty.all(8.0),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DsRaios.input),
                            side: BorderSide(
                              color: DsCores.border.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                        ),
                        minimumSize: WidgetStateProperty.all(
                          Size(constraints.maxWidth, 0),
                        ),
                        maximumSize: WidgetStateProperty.all(
                          Size(constraints.maxWidth, 320),
                        ),
                      ),
                      builder: (BuildContext context, MenuController controller, Widget? child) {
                        return InkWell(
                          onTap: enabled
                              ? () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(DsRaios.input),
                          child: InputDecorator(
                            isFocused: controller.isOpen,
                            decoration: InputDecoration(
                              hintText: hint,
                              helperText: helperText,
                              errorText: field.errorText ?? errorText,
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
                              suffixIcon: Icon(
                                Icons.arrow_drop_down,
                                color: enabled ? DsCores.inputSuffixIcon : DsCores.iconMuted,
                              ),
                              suffixIconConstraints: const BoxConstraints(
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
                            isEmpty: field.value == null || field.value!.isEmpty,
                            child: Text(
                              field.value ?? '',
                              style: DsTipografia.inputText.copyWith(
                                color: effectiveTextColor,
                              ),
                            ),
                          ),
                        );
                      },
                      menuChildren: items.map((String item) {
                        final bool isSelected = field.value == item;
                        return MenuItemButton(
                          onPressed: () {
                            field.didChange(item);
                            if (onChanged != null) {
                              onChanged!(item);
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                              if (isSelected) {
                                return DsCores.surfaceElevated.withValues(alpha: 0.75);
                              }
                              if (states.contains(WidgetState.hovered) ||
                                  states.contains(WidgetState.pressed)) {
                                return DsCores.surfaceElevated.withValues(alpha: 0.65);
                              }
                              return Colors.transparent;
                            }),
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                vertical: DsEspacamentos.md,
                                horizontal: DsEspacamentos.md,
                              ),
                            ),
                            minimumSize: WidgetStateProperty.all(
                              Size(constraints.maxWidth, 48),
                            ),
                          ),
                          child: SizedBox(
                            width: constraints.maxWidth - 32,
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DsTipografia.inputText.copyWith(
                                color: isSelected ? DsCores.textPrimary : DsCores.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
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

class _DsDropdownFormField extends FormField<String> {
  const _DsDropdownFormField({
    required String? value,
    super.validator,
    super.enabled,
    required super.builder,
  }) : super(
          initialValue: value,
        );

  @override
  FormFieldState<String> createState() => _DsDropdownFormFieldState();
}

class _DsDropdownFormFieldState extends FormFieldState<String> {
  @override
  void didUpdateWidget(_DsDropdownFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}
