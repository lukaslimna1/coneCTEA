class ProfileStringUtils {
  /// Formata uma string de CPF (11 dígitos) para o padrão 000.000.000-00
  static String formatCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '—';

    final d = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length != 11) return cpf;

    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }
}
