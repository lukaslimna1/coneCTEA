// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/formatadores/formatadores_cadastrais.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';

/// Campo de formulário padronizado para Data de Nascimento com máscara e validação local.
class CampoDataNascimento extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoDataNascimento({
    super.key,
    required this.controller,
    this.enabled = true,
    this.requiredField = true,
    this.label,
    this.hint,
    this.helperText,
    this.semanticsLabel,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final String labelTexto = '${label ?? 'Data de nascimento'}${requiredField ? ' *' : ''}';

    return DsInput(
      label: labelTexto,
      controller: controller,
      enabled: enabled,
      hint: hint ?? '00/00/0000',
      helperText: helperText,
      icon: PhosphorIconsRegular.calendarBlank,
      keyboardType: TextInputType.datetime,
      inputFormatters: [FormatadoresCadastrais.obterMascaraDataNascimento()],
      semanticsLabel: semanticsLabel,
      validator: validator ??
          (requiredField
              ? (value) => ValidadoresCadastrais.dataNascimentoCompleta(value)
              : (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return ValidadoresCadastrais.dataNascimentoCompleta(value);
                }),
    );
  }
}
