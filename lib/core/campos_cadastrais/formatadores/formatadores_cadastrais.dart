// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Centralizadores de formatadores e máscaras de texto cadastrais.
class FormatadoresCadastrais {
  /// Retorna um novo formatador de máscara de CPF (###.###.###-##).
  static MaskTextInputFormatter obterMascaraCpf() {
    return MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
    );
  }

  /// Retorna um novo formatador de máscara de telefone brasileiro ((##) #####-####).
  static MaskTextInputFormatter obterMascaraTelefone() {
    return MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );
  }

  /// Retorna um novo formatador de máscara de data de nascimento (##/##/####).
  static MaskTextInputFormatter obterMascaraDataNascimento() {
    return MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );
  }
}
