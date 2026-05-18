class ConecteaDateTimeHelper {
  static const Duration projectUtcOffset = Duration(hours: -3);

  /// Converte um [DateTime] para o fuso horário oficial de Brasília/Bauru (UTC-3),
  /// independente do fuso configurado no aparelho.
  static DateTime toProjectTime(DateTime value) {
    return value.toUtc().add(projectUtcOffset);
  }

  /// Retorna o [DateTime] atual sob o fuso oficial do projeto (Bauru/SP - UTC-3)
  static DateTime get nowProjectTime {
    return DateTime.now().toUtc().add(projectUtcOffset);
  }

  /// Verifica se dois [DateTime] pertencem ao mesmo dia no fuso oficial do projeto
  static bool isSameProjectDay(DateTime a, DateTime b) {
    final projA = toProjectTime(a);
    final projB = toProjectTime(b);
    return projA.year == projB.year &&
        projA.month == projB.month &&
        projA.day == projB.day;
  }

  /// Formata apenas a hora e minutos no fuso do projeto (HH:mm)
  static String formatProjectTime(DateTime value) {
    final projTime = toProjectTime(value);
    final hour = projTime.hour.toString().padLeft(2, '0');
    final minute = projTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formata a data para o cabeçalho de Notificações, retornando a data absoluta no padrão Bauru/SP (ex: "18 de maio").
  /// Todo o cálculo é realizado de forma blindada no fuso do projeto.
  static String formatProjectDateHeader(DateTime value) {
    return formatProjectDate(value);
  }

  /// Formata a data em formato absoluto de dia e mês (ex: "18 de maio")
  static String formatProjectDate(DateTime value) {
    final projTime = toProjectTime(value);
    
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];

    if (projTime.month < 1 || projTime.month > 12) {
      return '${projTime.day}/${projTime.month}/${projTime.year}';
    }

    return '${projTime.day} de ${months[projTime.month - 1]}';
  }
}
