import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_filter.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_list_result.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_sensitive_review.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_action_result.dart';
class AdminDependentCpfChangesRepository {
  final SupabaseClient _supabase;

  AdminDependentCpfChangesRepository({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Busca de forma segura e econômica as solicitações de alteração de CPF de dependente.
  /// Retorna um resultado contendo os itens paginados e os contadores consolidados.
  Future<AdminDependentCpfChangeListResult> listDependentCpfChangeRequests({
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
        'conectea_admin_list_dependent_cpf_change_requests_v1',
        params: {
          'p_filter': filter == AdminCpfChangeFilter.confirmation
              ? 'applying'
              : filter.technicalKey,
          'p_search': sanitizedSearch,
          'p_limit': sanitizedLimit,
          'p_offset': sanitizedOffset,
        },
      );

      if (response == null) {
        throw const FormatException('Retorno nulo da RPC de alteração de CPF de dependente.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response as Map,
      );
      return AdminDependentCpfChangeListResult.fromJson(data, sanitizedLimit);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Acesso negado: privilégios insuficientes.');
      }
      throw Exception('Erro ao processar listagem de solicitações.');
    } catch (_) {
      throw Exception('Erro de conexão ou comunicação com o banco.');
    }
  }

  /// Obtém os dados sensíveis de auditoria de CPF de dependente caso o administrador logado seja autorizado.
  Future<AdminDependentCpfChangeSensitiveReview> getDependentCpfChangeSensitiveReview({
    required String requestId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'conectea_admin_get_dependent_cpf_change_sensitive_review_v1',
        params: {'p_request_id': requestId},
      );
      if (response == null) {
        throw const FormatException('Retorno nulo da RPC de dados sensíveis de dependente.');
      }
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response as Map,
      );
      return AdminDependentCpfChangeSensitiveReview.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Acesso negado: privilégios insuficientes.');
      } else if (e.code == 'P0002') {
        throw Exception('Solicitação não encontrada.');
      }
      throw Exception('Erro ao processar revisão de dados sensíveis.');
    } catch (_) {
      throw Exception('Erro de conexão ou comunicação com o banco.');
    }
  }

  /// Aprova transacionalmente a alteração de CPF de dependente chamando a RPC segura.
  Future<AdminDependentCpfChangeActionResult> approveDependentCpfChangeRequest({
    required String requestId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'conectea_admin_approve_dependent_cpf_change_request_v1',
        params: {'p_request_id': requestId},
      );

      if (response == null) {
        throw const FormatException('Retorno nulo da RPC de aprovação de CPF de dependente.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response as Map,
      );

      final bool success = data['success'] as bool? ?? false;
      if (success) {
        return AdminDependentCpfChangeActionResult.fromJson(data);
      } else {
        final errorCode = data['error_code'] as String?;
        final message = _mapErrorCodeToMessage(errorCode);
        throw Exception(message);
      }
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Acesso negado: privilégios insuficientes.');
      }
      throw Exception('Não foi possível concluir a aprovação agora.');
    } catch (_) {
      throw Exception('Não foi possível concluir a aprovação agora.');
    }
  }

  String _mapErrorCodeToMessage(String? errorCode) {
    switch (errorCode) {
      case 'unauthorized':
        return 'Sua sessão expirou. Faça login novamente.';
      case 'forbidden':
        return 'Acesso negado: privilégios insuficientes.';
      case 'invalid_parameters':
        return 'Solicitação inválida.';
      case 'not_found':
        return 'Solicitação administrativa não encontrada.';
      case 'invalid_status':
        return 'Esta solicitação não está mais aguardando análise.';
      case 'expired':
        return 'Esta solicitação já expirou.';
      case 'member_not_found':
        return 'Beneficiário dependente não encontrado.';
      case 'invalid_request':
        return 'O cadastro do dependente não está apto para aprovação.';
      case 'missing_review_data':
        return 'Dados de revisão indisponíveis.';
      case 'document_unavailable':
        return 'Documento de revisão indisponível.';
      case 'invalid_cpf':
        return 'O CPF solicitado é inválido.';
      case 'member_cpf_changed':
        return 'O CPF atual do dependente mudou desde a abertura da solicitação.';
      case 'cpf_in_use':
        return 'O CPF solicitado já está em uso.';
      case 'account_cpf_conflict':
        return 'O CPF do dependente não pode ser igual ao CPF de uma conta.';
      case 'reservation_unavailable':
        return 'Reserva de CPF indisponível.';
      case 'internal_error':
        return 'Não foi possível aprovar a solicitação neste momento.';
      default:
        return 'Não foi possível concluir a aprovação agora.';
    }
  }
}
