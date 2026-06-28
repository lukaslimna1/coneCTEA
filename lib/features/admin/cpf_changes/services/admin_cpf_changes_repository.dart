import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_filter.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_list_result.dart';

class AdminCpfChangesRepository {
  final SupabaseClient _supabase;

  AdminCpfChangesRepository({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Busca de forma segura e econômica as solicitações de alteração de CPF.
  /// Retorna um resultado contendo os itens paginados e os contadores consolidados.
  Future<AdminCpfChangeListResult> listCpfChangeRequests({
    required AdminCpfChangeFilter filter,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final sanitizedSearch = (search != null && search.trim().isNotEmpty)
        ? search.trim()
        : null;

    int sanitizedLimit = limit;
    if (sanitizedLimit < 1) {
      sanitizedLimit = 20;
    } else if (sanitizedLimit > 50) {
      sanitizedLimit = 50;
    }

    final int sanitizedOffset = offset < 0 ? 0 : offset;

    try {
      final response = await _supabase.rpc(
        'conectea_admin_list_cpf_change_requests_v1',
        params: {
          'p_filter': filter.technicalKey,
          'p_search': sanitizedSearch,
          'p_limit': sanitizedLimit,
          'p_offset': sanitizedOffset,
        },
      );

      if (response == null) {
        throw const FormatException('Retorno nulo da RPC de alteração de CPF.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response as Map,
      );
      return AdminCpfChangeListResult.fromJson(data, sanitizedLimit);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Acesso negado: privilégios insuficientes.');
      }
      throw Exception('Erro ao processar listagem de solicitações.');
    } catch (_) {
      throw Exception('Erro de conexão ou comunicação com o banco.');
    }
  }
}
