// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';
import '../helpers/dado_protegido_toggle.dart';

/// Campo de formulário padronizado para CID (Classificação Internacional de Doenças).
class CampoCid extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoCid({
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
    final String labelTexto = '${label ?? 'CID (Opcional)'}${requiredField ? ' *' : ''}';

    return DsInput(
      label: labelTexto,
      controller: controller,
      enabled: enabled,
      hint: hint ?? 'Ex: F84.0',
      helperText: helperText,
      icon: PhosphorIconsRegular.clipboardText,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      semanticsLabel: semanticsLabel,
      validator: validator ??
          (requiredField
              ? (value) => ValidadoresCadastrais.campoObrigatorio(
                    value,
                    mensagem: 'CID é obrigatório',
                  )
              : null),
    );
  }
}

/// Campo de CID protegido de forma visual com Mostrar/Ocultar.
///
/// Desbloqueio real por senha/biometria será tratado em frente futura de segurança.
/// Não realiza nenhuma validação de CID, não sugere diagnóstico e não chama serviços.
class CampoCidProtegido extends StatelessWidget {
  final String valorVisivel;
  final String valorOculto;
  final bool iniciarVisivel;
  final String? semanticsLabel;

  const CampoCidProtegido({
    super.key,
    this.valorVisivel = 'Não informado',
    this.valorOculto = 'Oculto',
    this.iniciarVisivel = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CampoDadoProtegidoToggle(
      label: 'CID',
      valorVisivel: valorVisivel,
      valorOculto: valorOculto,
      icon: PhosphorIconsRegular.lock,
      iniciarVisivel: iniciarVisivel,
      semanticsLabel: semanticsLabel,
    );
  }
}
