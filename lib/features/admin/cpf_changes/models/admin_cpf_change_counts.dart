class AdminCpfChangeCounts {
  final int analysis;
  final int corrections;
  final int completed;
  final int confirmation;
  final int rejected;
  final int cancelled;
  final int expired;
  final int failed;
  final int expiredFailed;
  final int total;

  const AdminCpfChangeCounts({
    required this.analysis,
    required this.corrections,
    required this.completed,
    required this.confirmation,
    required this.rejected,
    required this.cancelled,
    required this.expired,
    required this.failed,
    required this.expiredFailed,
    required this.total,
  });

  factory AdminCpfChangeCounts.fromJson(Map<String, dynamic> json) {
    return AdminCpfChangeCounts(
      analysis: json['analysis'] as int? ?? 0,
      corrections: json['corrections'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      confirmation: json['confirmation'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      expired: json['expired'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      expiredFailed: json['expired_failed'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  factory AdminCpfChangeCounts.empty() {
    return const AdminCpfChangeCounts(
      analysis: 0,
      corrections: 0,
      completed: 0,
      confirmation: 0,
      rejected: 0,
      cancelled: 0,
      expired: 0,
      failed: 0,
      expiredFailed: 0,
      total: 0,
    );
  }
}
