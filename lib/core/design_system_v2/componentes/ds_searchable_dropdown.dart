import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_medidas.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_tipografia.dart';

/// Componente de Dropdown com Busca oficial do Design System V2 do ConeCTEA.
///
/// Este componente define apenas a camada visual e estrutural do dropdown pesquisável.
/// Ele NÃO acessa Supabase, NÃO navega, NÃO persiste dados
/// e NÃO contém regra de negócio.
class DsSearchableDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? hint;
  final String? searchHint;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? semanticsLabel;

  const DsSearchableDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.searchHint,
    this.helperText,
    this.errorText,
    this.icon,
    this.enabled = true,
    this.validator,
    this.semanticsLabel,
  });

  @override
  State<DsSearchableDropdown> createState() => _DsSearchableDropdownState();
}

class _DsSearchableDropdownState extends State<DsSearchableDropdown> {
  late final SearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        widget.enabled ? DsCores.textPrimary : DsCores.textMuted;

    final effectiveIconColor =
        widget.enabled ? DsCores.inputIcon : DsCores.iconMuted;

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: DsTipografia.inputLabel.copyWith(
              color: widget.enabled ? DsCores.textPrimary : DsCores.textMuted,
            ),
          ),
          const SizedBox(height: DsEspacamentos.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DsTamanhos.inputHeight,
            ),
            child: _DsSearchableDropdownFormField(
              value: widget.value,
              validator: widget.validator,
              enabled: widget.enabled,
              builder: (FormFieldState<String> field) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        searchViewTheme: SearchViewThemeData(
                          backgroundColor: DsCores.glassStrong,
                          elevation: 8.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DsRaios.input),
                            side: BorderSide(
                              color: DsCores.border.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          headerTextStyle: DsTipografia.inputText.copyWith(color: DsCores.textPrimary),
                          headerHintStyle: DsTipografia.inputHint,
                        ),
                      ),
                      child: SearchAnchor(
                        searchController: _searchController,
                        viewBackgroundColor: DsCores.glassStrong,
                        viewElevation: 8.0,
                        viewShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DsRaios.input),
                          side: BorderSide(
                            color: DsCores.border.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        viewHintText: widget.searchHint ?? 'Digite para buscar...',
                        viewConstraints: BoxConstraints(
                          maxHeight: 320,
                          maxWidth: constraints.maxWidth,
                        ),
                        viewLeading: IconButton(
                          icon: Icon(Icons.arrow_back, color: DsCores.textPrimary),
                          onPressed: () {
                            if (_searchController.isOpen) {
                              _searchController.closeView(null);
                            }
                          },
                        ),
                        viewTrailing: [
                          IconButton(
                            icon: Icon(Icons.clear, color: DsCores.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        ],
                        builder: (BuildContext context, SearchController controller) {
                          return InkWell(
                            onTap: widget.enabled ? () => controller.openView() : null,
                            borderRadius: BorderRadius.circular(DsRaios.input),
                            child: InputDecorator(
                              isFocused: controller.isOpen,
                              decoration: InputDecoration(
                                hintText: widget.hint,
                                helperText: widget.helperText,
                                errorText: field.errorText ?? widget.errorText,
                                helperMaxLines: 2,
                                errorMaxLines: 3,
                                filled: true,
                                fillColor: widget.enabled
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
                                prefixIcon: widget.icon == null ? null : Icon(widget.icon),
                                prefixIconColor: effectiveIconColor,
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: DsTamanhos.inputHeight,
                                  minHeight: DsTamanhos.inputHeight,
                                ),
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down,
                                  color: widget.enabled ? DsCores.inputSuffixIcon : DsCores.iconMuted,
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
                        suggestionsBuilder: (BuildContext context, SearchController controller) {
                          final keyword = controller.text.toLowerCase();
                          final filtered = widget.items.where((item) => item.toLowerCase().contains(keyword)).toList();

                          return filtered.map((item) {
                            final bool isSelected = field.value == item;
                            return MenuItemButton(
                              onPressed: () {
                                field.didChange(item);
                                widget.onChanged?.call(item);
                                controller.closeView(item);
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
                          }).toList();
                        },
                      ),
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

class _DsSearchableDropdownFormField extends FormField<String> {
  const _DsSearchableDropdownFormField({
    required String? value,
    super.validator,
    super.enabled,
    required super.builder,
  }) : super(
          initialValue: value,
        );

  @override
  FormFieldState<String> createState() => _DsSearchableDropdownFormFieldState();
}

class _DsSearchableDropdownFormFieldState extends FormFieldState<String> {
  @override
  void didUpdateWidget(_DsSearchableDropdownFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}
