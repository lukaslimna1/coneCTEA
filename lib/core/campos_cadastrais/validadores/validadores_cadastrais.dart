// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

/// Centralizadores de validadores puramente algorítmicos e locais de campos.
class ValidadoresCadastrais {
  /// Validador genérico de campo obrigatório.
  static String? campoObrigatorio(String? value, {String? mensagem}) {
    if (value == null || value.trim().isEmpty) {
      return mensagem ?? 'Campo obrigatório';
    }
    return null;
  }

  /// Validador algorítmico oficial de CPF unificado (sem acessar banco ou serviços).
  static String? cpf(String? value, {String? mensagem}) {
    if (value == null || value.trim().isEmpty) {
      return mensagem ?? 'Campo obrigatório';
    }

    // Remove caracteres não numéricos
    final cleanCpf = value.replaceAll(RegExp(r'[^0-9]'), '');

    // CPF deve ter exatamente 11 dígitos
    if (cleanCpf.length != 11) return 'CPF inválido';

    // Bloqueia sequências repetidas conhecidas (111.111.111-11, etc)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return 'CPF inválido';

    final digits = cleanCpf.split('').map((e) => int.parse(e)).toList();

    // Cálculo do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != digits[9]) return 'CPF inválido';

    // Cálculo do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    if (secondDigit != digits[10]) return 'CPF inválido';

    return null;
  }

  /// Validador sintático simples de e-mail.
  static String? email(String? value, {String? mensagem}) {
    if (value == null || value.trim().isEmpty) {
      return mensagem ?? 'Campo obrigatório';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'E-mail inválido';
    }
    return null;
  }

  /// Validador de formato de telefone brasileiro simples.
  static String? telefone(String? value, {String? mensagem}) {
    if (value == null || value.trim().isEmpty) {
      return mensagem ?? 'Campo obrigatório';
    }
    // Remove caracteres não numéricos
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.length < 10 || cleanValue.length > 11) {
      return 'Telefone inválido';
    }
    return null;
  }

  /// Validador de data de nascimento completa.
  static String? dataNascimentoCompleta(String? value, {String? mensagem}) {
    if (value == null || value.trim().isEmpty) {
      return mensagem ?? 'Campo obrigatório';
    }
    if (value.length < 10) {
      return 'Data incompleta';
    }
    final parts = value.split('/');
    if (parts.length != 3) {
      return 'Data inválida';
    }
    final dia = int.tryParse(parts[0]);
    final mes = int.tryParse(parts[1]);
    final ano = int.tryParse(parts[2]);
    if (dia == null || mes == null || ano == null) {
      return 'Data inválida';
    }
    if (dia < 1 || dia > 31 || mes < 1 || mes > 12 || ano < 1900 || ano > DateTime.now().year) {
      return 'Data inválida';
    }
    return null;
  }
}
