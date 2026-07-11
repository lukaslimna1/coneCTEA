import 'dart:convert';
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

  /// Aprova transacionalmente a alteração de CPF de dependente chamando a Edge Function de descarte direto.
  Future<AdminDependentCpfChangeActionResult> approveDependentCpfChangeRequest({
    required String requestId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'approve-dependent-cpf-change-request',
        body: {'request_id': requestId},
      );

      final responseData = response.data;
      if (responseData == null || responseData is! Map) {
        throw const FormatException('Retorno inválido ou nulo da Edge Function.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(responseData);

      final bool success = data['success'] as bool? ?? false;
      if (success) {
        return AdminDependentCpfChangeActionResult.fromJson(data);
      } else {
        final errorCode = data['error_code'] as String?;
        final message = _mapErrorCodeToMessage(errorCode);
        throw Exception(message);
      }
    } on FunctionException catch (e) {
      final safeMessage = _extractSafeErrorMessageFromException(e);
      throw Exception(safeMessage);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Acesso negado: privilégios insuficientes.');
      }
      throw Exception('Não foi possível concluir a aprovação agora.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) {
        rethrow;
      }
      throw Exception('Não foi possível concluir a aprovação agora.');
    }
  }

  /// Solicita a correção do CPF do dependente chamando a RPC conectea_admin_request_dependent_cpf_correction_v1.
  Future<AdminDependentCpfChangeActionResult> requestDependentCpfCorrection({
    required String requestId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'conectea_admin_request_dependent_cpf_correction_v1',
        params: {'p_request_id': requestId},
      );

      if (response == null) {
        throw const FormatException('Retorno nulo da RPC de solicitação de correção de CPF.');
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
      throw Exception('Não foi possível concluir a ação agora.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) {
        rethrow;
      }
      throw Exception('Não foi possível concluir a ação agora.');
    }
  }

  /// Solicita o reenvio do documento chamando a Edge Function request-dependent-cpf-document-replacement.
  Future<AdminDependentCpfChangeActionResult> requestDependentCpfDocumentReplacement({
    required String requestId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'request-dependent-cpf-document-replacement',
        body: {'request_id': requestId},
      );

      final responseData = response.data;
      if (responseData == null || responseData is! Map) {
        throw const FormatException('Retorno inválido ou nulo da Edge Function.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(responseData);

      final bool success = data['success'] as bool? ?? false;
      if (success) {
        return AdminDependentCpfChangeActionResult.fromJson(data);
      } else {
        final errorCode = data['error_code'] as String?;
        final message = _mapErrorCodeToMessage(errorCode);
        throw Exception(message);
      }
    } on FunctionException catch (e) {
      final safeMessage = _extractSafeErrorMessageFromException(e);
      throw Exception(safeMessage);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception('Acesso negado: privilégios insuficientes.');
      }
      throw Exception('Não foi possível solicitar documento agora.');
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) {
        rethrow;
      }
      throw Exception('Não foi possível solicitar documento agora.');
    }
  }

  String _mapErrorCodeToMessage(String? errorCode) {
    switch (errorCode) {
      case 'method_not_allowed':
        return 'Método de requisição não suportado.';
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
      case 'discard_not_configured':
        return 'Serviço de descarte de documentos não configurado.';
      case 'discard_timeout':
        return 'O descarte no Google Drive excedeu o tempo limite.';
      case 'discard_auth_failed':
        return 'Falha de autenticação com o provedor de descarte.';
      case 'discard_failed':
        return 'Não foi possível remover o documento no Google Drive.';
      case 'rollback_failed':
        return 'Erro crítico ao reverter a trava operacional.';
      case 'commit_failed':
        return 'Não foi possível consolidar a aprovação da alteração de CPF.';
      case 'commit_after_discard_failed':
        return 'Documento removido, mas a consolidação do CPF falhou. Avise o suporte técnico antes de tentar novamente.';
      case 'internal_error':
        return 'Não foi possível aprovar a solicitação neste momento.';
      default:
        return 'Não foi possível concluir a aprovação agora.';
    }
  }

  String _extractSafeErrorMessageFromException(FunctionException e) {
    final details = e.details;
    Map<dynamic, dynamic>? errorMap;

    if (details is Map) {
      errorMap = details;
    } else if (details is String && details.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) {
          errorMap = decoded;
        }
      } catch (_) {
        // Ignora erros de parse
      }
    }

    if (errorMap != null) {
      final errorCode = errorMap['error_code']?.toString() ??
                        errorMap['error']?.toString();

      if (errorCode != null && errorCode.trim().isNotEmpty) {
        final mappedMessage = _mapErrorCodeToMessage(errorCode.trim());
        if (mappedMessage != 'Não foi possível concluir a aprovação agora.') {
          return mappedMessage;
        }
      }

      final message = errorMap['message']?.toString();
      if (message != null && _isMessageSafe(message)) {
        return message;
      }
    }

    return 'Não foi possível concluir a aprovação agora.';
  }

  bool _isMessageSafe(String msg) {
    if (msg.trim().isEmpty) return false;

    final lower = msg.toLowerCase();

    if (RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}').hasMatch(msg)) return false;

    if (lower.contains('fileid') ||
        lower.contains('file_id') ||
        lower.contains('document_file_id') ||
        lower.contains('documentfileid')) {
      return false;
    }

    if (lower.contains('http://') || lower.contains('https://') || lower.contains('www.')) {
      return false;
    }

    if (lower.contains('postgrestexception') ||
        lower.contains('functionexception') ||
        lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('stack trace') ||
        lower.contains('sql') ||
        lower.contains('jwt') ||
        lower.contains('bearer') ||
        lower.contains('token') ||
        lower.contains('payload') ||
        lower.contains('response.data')) {
      return false;
    }

    return true;
  }
}
