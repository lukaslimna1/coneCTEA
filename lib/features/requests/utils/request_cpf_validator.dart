/// Helper para validação de CPF na feature de solicitações.
/// Extraído da AddMemberPage na Fase 14G-9.
bool isValidCpf(String cpf) {
  String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleanCpf.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;
  return true;
}
