// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';

/// Campo de formulário padronizado tipo Dropdown Pesquisável para Cidade.
class CampoCidade extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? searchHint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoCidade({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.requiredField = true,
    this.label,
    this.hint,
    this.searchHint,
    this.helperText,
    this.semanticsLabel,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final String labelTexto = '${label ?? 'Cidade'}${requiredField ? ' *' : ''}';

    return DsSearchableDropdown(
      label: labelTexto,
      value: value,
      items: items,
      onChanged: onChanged,
      enabled: enabled,
      hint: hint ?? 'Selecione a cidade',
      searchHint: searchHint ?? 'Buscar cidade...',
      helperText: helperText,
      icon: PhosphorIconsRegular.mapPin,
      semanticsLabel: semanticsLabel,
      validator: validator ??
          (requiredField
              ? (value) => ValidadoresCadastrais.campoObrigatorio(
                    value,
                    mensagem: 'Cidade é obrigatória',
                  )
              : null),
    );
  }
}
