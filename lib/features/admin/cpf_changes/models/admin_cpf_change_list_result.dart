import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_summary.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_counts.dart';

class AdminCpfChangeListResult {
  final List<AdminCpfChangeSummary> items;
  final AdminCpfChangeCounts counts;
  final DateTime serverNow;
  final bool hasMore;

  const AdminCpfChangeListResult({
    required this.items,
    required this.counts,
    required this.serverNow,
    required this.hasMore,
  });

  factory AdminCpfChangeListResult.fromJson(
    Map<String, dynamic> json,
    int limit,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map(
          (e) => AdminCpfChangeSummary.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    final rawCounts = json['counts'] as Map<dynamic, dynamic>? ?? {};
    final counts = AdminCpfChangeCounts.fromJson(
      Map<String, dynamic>.from(rawCounts),
    );

    final rawServerNow = json['server_now'];
    final serverNow = rawServerNow != null
        ? DateTime.parse(rawServerNow.toString())
        : DateTime.now();

    // NOTA OPERACIONAL:
    // Derivar hasMore comparando o número de itens retornados com o limite da página.
    // RISCO CONHECIDO: Se o número total de itens no banco de dados for exatamente um múltiplo
    // exato do limite (ex: 20, 40, etc.), o hasMore será erroneamente avaliado como true,
    // gerando uma requisição vazia na página subsequente. Isso é um comportamento comum
    // em paginações por offset simples e é aceito para a versão v1 sem desperdício de egress severo.
    final hasMore = itemsList.length >= limit;

    return AdminCpfChangeListResult(
      items: itemsList,
      counts: counts,
      serverNow: serverNow,
      hasMore: hasMore,
    );
  }
}
