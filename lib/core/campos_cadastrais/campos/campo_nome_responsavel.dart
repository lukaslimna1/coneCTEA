// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';

/// Campo de formulário padronizado para Nome do Responsável.
class CampoNomeResponsavel extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoNomeResponsavel({
    super.key,
    required this.controller,
    this.enabled = true,
    this.requiredField = false,
    this.label,
    this.hint,
    this.helperText,
    this.semanticsLabel,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final String labelTexto = '${label ?? 'Nome do Responsável (Opcional)'}${requiredField ? ' *' : ''}';

    return DsInput(
      label: labelTexto,
      controller: controller,
      enabled: enabled,
      hint: hint ?? 'Digite o nome do responsável',
      helperText: helperText,
      icon: PhosphorIconsRegular.user,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      semanticsLabel: semanticsLabel,
      validator: validator ??
          (requiredField
              ? (value) => ValidadoresCadastrais.campoObrigatorio(
                    value,
                    mensagem: 'Nome do responsável é obrigatório',
                  )
              : null),
    );
  }
}
