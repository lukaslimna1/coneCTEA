// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/opcoes/opcoes_cadastrais.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';

/// Campo de formulário padronizado tipo Dropdown para Indicação por Instituição (Sim/Não).
class CampoIndicacaoInstituicao extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoIndicacaoInstituicao({
    super.key,
    this.value,
    this.onChanged,
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
    final String labelTexto = '${label ?? 'Foi indicado por alguma instituição?'}${requiredField ? ' *' : ''}';

    return DsDropdown(
      label: labelTexto,
      value: value,
      items: OpcoesCadastrais.simNao,
      onChanged: onChanged,
      enabled: enabled,
      hint: hint ?? 'Selecione',
      helperText: helperText,
      icon: PhosphorIconsRegular.bank,
      semanticsLabel: semanticsLabel,
      validator: validator ??
          (requiredField
              ? (value) => ValidadoresCadastrais.campoObrigatorio(
                    value,
                    mensagem: 'Opção de indicação é obrigatória',
                  )
              : null),
    );
  }
}
