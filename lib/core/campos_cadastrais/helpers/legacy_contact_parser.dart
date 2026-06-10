enum LegacyContactClassification {
  empty,
  nameOnly,
  complete,
  phoneOnlyLegacy,
  ambiguous,
}

class LegacyContactParts {
  final LegacyContactClassification classification;
  final String? name;
  final String? phone;
  final String rawValue;

  const LegacyContactParts({
    required this.classification,
    this.name,
    this.phone,
    required this.rawValue,
  });
}

class LegacyContactParser {
  /// Construtor privado para impedir instanciação.
  LegacyContactParser._();

  /// Realiza o parsing de um contato no formato composto legado.
  ///
  /// A ordem lógica de classificação aplicada é:
  /// 1. empty - se o valor for nulo, vazio ou contendo apenas espaços.
  /// 2. complete / phoneOnlyLegacy / ambiguous - baseado na análise do último separador " - ".
  /// 3. phoneOnlyLegacy - se o valor integral for um telefone válido.
  /// 4. ambiguous - se houver números remanescentes na string.
  /// 5. nameOnly - para o restante das strings estritamente textuais e seguras.
  static LegacyContactParts parse(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const LegacyContactParts(
        classification: LegacyContactClassification.empty,
        name: null,
        phone: null,
        rawValue: '',
      );
    }

    final trimmedRaw = rawValue.trim();

    // Procurar pelo último separador " - " na string original para não perder o separador inicial
    if (rawValue.contains(' - ')) {
      final lastIndex = rawValue.lastIndexOf(' - ');
      final leftPart = rawValue.substring(0, lastIndex).trim();
      final rightPart = rawValue.substring(lastIndex + 3).trim();

      if (_isValidPhone(rightPart)) {
        if (leftPart.isEmpty) {
          // Separador com parte esquerda vazia e telefone válido -> phoneOnlyLegacy
          return LegacyContactParts(
            classification: LegacyContactClassification.phoneOnlyLegacy,
            name: null,
            phone: rightPart,
            rawValue: trimmedRaw,
          );
        }
        return LegacyContactParts(
          classification: LegacyContactClassification.complete,
          name: leftPart,
          phone: rightPart,
          rawValue: trimmedRaw,
        );
      } else {
        // Possui separador " - ", mas a parte direita não é um telefone válido -> ambiguous
        return LegacyContactParts(
          classification: LegacyContactClassification.ambiguous,
          name: null,
          phone: null,
          rawValue: trimmedRaw,
        );
      }
    }

    // Verificar se o valor integral é um telefone válido
    if (_isValidPhone(trimmedRaw)) {
      return LegacyContactParts(
        classification: LegacyContactClassification.phoneOnlyLegacy,
        name: null,
        phone: trimmedRaw,
        rawValue: trimmedRaw,
      );
    }

    // Verificar se a string possui dígitos numéricos não resolvidos
    if (trimmedRaw.contains(RegExp(r'[0-9]'))) {
      return LegacyContactParts(
        classification: LegacyContactClassification.ambiguous,
        name: null,
        phone: null,
        rawValue: trimmedRaw,
      );
    }

    // Restante textual seguro -> nameOnly
    return LegacyContactParts(
      classification: LegacyContactClassification.nameOnly,
      name: trimmedRaw,
      phone: null,
      rawValue: trimmedRaw,
    );
  }

  /// Helper privado para reconhecer se uma string pode ser um telefone válido.
  ///
  /// Regras de validação:
  /// - Remove caracteres não-numéricos para contagem e verificação.
  /// - Exige exatamente 10 ou 11 dígitos numéricos limpos.
  /// - Rejeita sequências de dígitos idênticos repetidos (ex: "99999999999").
  static bool _isValidPhone(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 10 && clean.length != 11) {
      return false;
    }
    // Rejeita sequências repetidas como 1111111111 ou 99999999999
    if (RegExp(r'^([0-9])\1+$').hasMatch(clean)) {
      return false;
    }
    return true;
  }
}
