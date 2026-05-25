/// Helper para validação de CPF na feature de solicitações.
/// Realiza a limpeza de caracteres e validação dos dígitos verificadores.
bool isValidCpf(String cpf) {
  // Remove caracteres não numéricos
  String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  // CPF deve ter exatamente 11 dígitos
  if (cleanCpf.length != 11) return false;

  // Rejeita sequências repetidas conhecidas (000.000.000-00, etc)
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;

  // Cálculo do primeiro dígito verificador
  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += int.parse(cleanCpf[i]) * (10 - i);
  }
  int firstDigit = 11 - (sum % 11);
  if (firstDigit >= 10) firstDigit = 0;

  if (int.parse(cleanCpf[9]) != firstDigit) return false;

  // Cálculo do segundo dígito verificador
  sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += int.parse(cleanCpf[i]) * (11 - i);
  }
  int secondDigit = 11 - (sum % 11);
  if (secondDigit >= 10) secondDigit = 0;

  if (int.parse(cleanCpf[10]) != secondDigit) return false;

  return true;
}
