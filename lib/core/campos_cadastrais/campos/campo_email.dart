// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';
import '../helpers/dado_protegido_toggle.dart';

/// Campo de formulário padronizado para E-mail com teclado apropriado e validador local.
class CampoEmail extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoEmail({
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
    final String labelTexto = '${label ?? 'E-mail'}${requiredField ? ' *' : ''}';

    return DsInput(
      label: labelTexto,
      controller: controller,
      enabled: enabled,
      hint: hint ?? 'exemplo@email.com',
      helperText: helperText,
      icon: PhosphorIconsRegular.envelope,
      keyboardType: TextInputType.emailAddress,
      semanticsLabel: semanticsLabel,
      validator: validator ??
          (requiredField
              ? (value) => ValidadoresCadastrais.email(value)
              : (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return ValidadoresCadastrais.email(value);
                }),
    );
  }
}

/// Campo de E-mail protegido de forma visual com Mostrar/Ocultar.
///
/// Desbloqueio real por senha/biometria será tratado em frente futura de segurança.
class CampoEmailProtegido extends StatelessWidget {
  final String valorVisivel;
  final String valorOculto;
  final bool iniciarVisivel;
  final String? semanticsLabel;

  const CampoEmailProtegido({
    super.key,
    this.valorVisivel = 'l***@email.com',
    this.valorOculto = 'l***@email.com',
    this.iniciarVisivel = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CampoDadoProtegidoToggle(
      label: 'E-mail',
      valorVisivel: valorVisivel,
      valorOculto: valorOculto,
      icon: PhosphorIconsRegular.lock,
      iniciarVisivel: iniciarVisivel,
      semanticsLabel: semanticsLabel,
    );
  }
}
