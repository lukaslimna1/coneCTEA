/// Valida um número de CPF seguindo o algoritmo de dígitos verificadores.
/// Utilizado no fluxo de Autenticação (Registro).
bool isValidAuthCpf(String cpf) {
  // Remove caracteres não numéricos
  final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

  // CPF deve ter exatamente 11 dígitos
  if (cleanCpf.length != 11) return false;

  // Bloqueia sequências repetidas conhecidas (111.111.111-11, etc)
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;

  final digits = cleanCpf.split('').map((e) => int.parse(e)).toList();

  // Cálculo do primeiro dígito verificador
  int sum = 0;
  for (int i = 0; i < 9; i++) {
    sum += digits[i] * (10 - i);
  }
  int firstDigit = (sum * 10) % 11;
  if (firstDigit == 10) firstDigit = 0;
  if (firstDigit != digits[9]) return false;

  // Cálculo do segundo dígito verificador
  sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += digits[i] * (11 - i);
  }
  int secondDigit = (sum * 10) % 11;
  if (secondDigit == 10) secondDigit = 0;
  if (secondDigit != digits[10]) return false;

  return true;
}
