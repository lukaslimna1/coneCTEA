import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_summary.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_counts.dart';

class AdminDependentCpfChangeListResult {
  final List<AdminDependentCpfChangeSummary> items;
  final AdminDependentCpfChangeCounts counts;
  final DateTime serverNow;
  final bool hasMore;

  const AdminDependentCpfChangeListResult({
    required this.items,
    required this.counts,
    required this.serverNow,
    required this.hasMore,
  });

  factory AdminDependentCpfChangeListResult.fromJson(
    Map<String, dynamic> json,
    int limit,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map(
          (e) => AdminDependentCpfChangeSummary.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    final rawCounts = json['counts'] as Map<dynamic, dynamic>? ?? {};
    final counts = AdminDependentCpfChangeCounts.fromJson(
      Map<String, dynamic>.from(rawCounts),
    );

    final rawServerNow = json['server_now'];
    final serverNow = rawServerNow != null
        ? DateTime.parse(rawServerNow.toString())
        : DateTime.now();

    final hasMore = itemsList.length >= limit;

    return AdminDependentCpfChangeListResult(
      items: itemsList,
      counts: counts,
      serverNow: serverNow,
      hasMore: hasMore,
    );
  }
}
