import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/notification_item.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_params.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_result.dart';
import 'package:conectea/models/account_change_request.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // Removido _validationUrlPrefix não utilizado

  // --- Perfil ---

  /// Recupera o e-mail de forma segura via Edge Function.
  /// Retorna um mapa com: found, maskedEmail, emailSent e error.
  Future<Map<String, dynamic>> recoverEmailByCpf(String cpf) async {
    try {
      final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

      final response = await _supabase.functions.invoke(
        'recover-email-by-cpf',
        body: {'cpf': cleanCpf},
      );

      final data = response.data as Map<String, dynamic>;

      return {
        'found': data['found'] ?? false,
        'maskedEmail': data['masked_email'],
        'emailSent': data['email_sent'] ?? false,
        'error': null,
      };
    } catch (e) {
      // Log genérico sem expor dados sensíveis ou detalhes técnicos para o frontend
      return {
        'found': false,
        'maskedEmail': null,
        'emailSent': false,
        'error': true,
      };
    }
  }

  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUserProfile(AppUser user) async {
    await _supabase.from('profiles').upsert(user.toJson());
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isCpfRegistered(String cpf) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('cpf', cpf)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Atualiza os campos cadastrais comuns permitidos do próprio perfil do titular.
  ///
  /// A identidade do usuário (UUID) é obtida de forma segura no servidor via auth.uid().
  /// A sincronização com a tabela de membros e carteirinhas do titular ocorre server-side.
  Future<Map<String, dynamic>> updateOwnProfile({
    required Map<String, dynamic> changes,
  }) async {
    const allowedFields = <String>{
      'name',
      'social_name',
      'date_of_birth',
      'phone',
      'state',
      'city',
      'gender',
      'race',
      'institution',
    };

    if (changes.isEmpty) {
      throw ArgumentError('O conjunto de alterações não pode estar vazio.');
    }

    final safeChanges = <String, dynamic>{};

    for (final entry in changes.entries) {
      final key = entry.key;
      final value = entry.value;

      if (!allowedFields.contains(key)) {
        throw ArgumentError('Campo não autorizado para alteração: $key');
      }

      if (value is String) {
        safeChanges[key] = value.trim();
      } else {
        safeChanges[key] = value;
      }
    }

    final response = await _supabase.rpc(
      'conectea_update_own_profile_v1',
      params: {'p_changes': safeChanges},
    );

    if (response == null) {
      throw Exception('A resposta do servidor foi nula.');
    }

    final List<dynamic> list;
    if (response is List) {
      list = response;
    } else {
      throw Exception('A resposta do servidor possui formato inesperado.');
    }

    if (list.isEmpty) {
      throw Exception('Nenhum dado retornado do servidor.');
    }

    if (list.length != 1) {
      throw Exception('Número inesperado de linhas retornadas do servidor.');
    }

    final rawLine = list.first;
    if (rawLine is! Map) {
      throw Exception('A linha retornada pelo servidor não é um mapa válido.');
    }

    final data = Map<String, dynamic>.from(rawLine);

    return <String, dynamic>{
      'name': data['out_name'],
      'social_name': data['out_social_name'],
      'date_of_birth': data['out_date_of_birth'],
      'phone': data['out_phone'],
      'state': data['out_state'],
      'city': data['out_city'],
      'gender': data['out_gender'],
      'race': data['out_race'],
      'institution': data['out_institution'],
      'updated_at': data['out_updated_at'],
    };
  }

  Future<bool> isMemberCpfRegistered(String cpf, {String? memberId}) async {
    try {
      final response = await _supabase.rpc(
        'is_member_cpf_registered',
        params: {'p_cpf': cpf, 'p_member_id': memberId},
      );
      if (response is bool) {
        return response;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- Membros ---
  Future<List<Member>> getMembers(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('members')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => Member.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<Member>> membersStream(String userId) {
    return _supabase
        .from('members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Member.fromJson(json)).toList());
  }

  Future<void> addMember(Member member) async {
    final data = member.toJson();
    await _supabase.from('members').upsert(data);
  }

  Future<void> updateMember(Member member) async {
    final data = member.toJson();
    await _supabase.from('members').update(data).eq('id', member.id);
  }

  /// Campos que podem ser atualizados individualmente via [updateMemberFields].
  static const _allowedMemberFields = <String>{
    'name',
    'cpf',
    'city',
    'state',
    'phone',
    'responsible_person_name',
    'responsible_phone',
    'emergency_person_name',
    'emergency_phone',
    'birth_date',
    'blood_type',
    'cid',
    'gender',
    'raca_cor',
    'social_name',
    'tea_relation_type',
  };

  /// Campos que nunca devem ser alterados por update parcial.
  static const _forbiddenMemberFields = <String>{
    'id',
    'user_id',
    'status',
    'created_at',
    'updated_at',
    'document_url',
    'medical_report_url',
    'responsible_name',
    'emergency_contact',
  };

  /// Campos que podem receber valor null intencionalmente.
  static const _nullableMemberFields = <String>{'social_name'};

  @visibleForTesting
  static void validatePartialUpdateFields(
    String memberId,
    Map<String, dynamic> fields,
  ) {
    if (memberId.trim().isEmpty) {
      throw ArgumentError('ID do membro não pode ser vazio.');
    }
    if (fields.isEmpty) {
      throw ArgumentError('Nenhum campo fornecido para atualização.');
    }
    for (final entry in fields.entries) {
      final key = entry.key;
      final value = entry.value;

      if (_forbiddenMemberFields.contains(key)) {
        throw ArgumentError('Campo proibido para atualização parcial.');
      }
      if (!_allowedMemberFields.contains(key)) {
        throw ArgumentError('Campo não autorizado para atualização parcial.');
      }
      if (value == null && !_nullableMemberFields.contains(key)) {
        throw ArgumentError('O campo $key não pode receber valor nulo.');
      }
    }
  }

  /// Atualiza apenas os campos especificados de um membro.
  ///
  /// Aceita somente campos presentes na allowlist.
  /// Rejeita Map vazio e campos proibidos.
  /// Valores null no Map significam limpeza intencional do campo (se permitido).
  /// Campos omitidos do Map não são alterados no banco.
  Future<void> updateMemberFields(
    String memberId,
    Map<String, dynamic> fields,
  ) async {
    validatePartialUpdateFields(memberId, fields);
    final safeFields = Map<String, dynamic>.from(fields);
    await _supabase
        .from('members')
        .update(safeFields)
        .eq('id', memberId.trim());
  }

  Future<Member?> getMember(String memberId) async {
    try {
      final data = await _supabase
          .from('members')
          .select()
          .eq('id', memberId)
          .maybeSingle();
      if (data == null) return null;
      return Member.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<DigitalCard?> getCardByNumber(String cardNumber) async {
    try {
      debugPrint('DatabaseService: Procurando por carteirinha pelo número.');
      final data = await _supabase
          .from('digital_cards')
          .select('*, members(*)')
          .ilike('card_number', cardNumber.trim())
          .maybeSingle();

      if (data == null) {
        debugPrint('DatabaseService: Nenhuma carteirinha encontrada.');
        return null;
      }
      debugPrint('DatabaseService: Carteirinha encontrada com sucesso.');
      return DigitalCard.fromJson(data);
    } catch (e) {
      debugPrint('Erro no DatabaseService: $e');
      return null;
    }
  }

  // --- Carteirinhas Digitais ---

  Future<List<DigitalCard>> getDigitalCards(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('digital_cards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => DigitalCard.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<DigitalCard>> digitalCardsStream(String userId) {
    return _supabase
        .from('digital_cards')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => DigitalCard.fromJson(json)).toList());
  }

  Future<void> createDigitalCard(DigitalCard card) async {
    final json = card.toJson();
    // Remove id vazio para que o Supabase gere automaticamente um UUID
    if ((json['id'] as String?)?.isEmpty ?? true) json.remove('id');
    await _supabase.from('digital_cards').upsert(json);
  }

  /// Cria ou reativa a carteirinha digital ao aprovar uma solicitação.
  /// Obtém a validade civil diretamente do servidor (Postgres) no fuso America/Sao_Paulo (1 ano).
  Future<void> ensureDigitalCard({
    required String memberId,
    required String userId,
    required String requestId,
    required Member member,
  }) async {
    // Obter as datas civis oficiais direto do Postgres (fuso de Bauru/SP)
    final response = await _supabase.rpc(
      'conectea_digital_card_validity_window',
    );

    final String issuedAtStr;
    final String validUntilStr;

    if (response is List && response.isNotEmpty) {
      final map = response.first as Map<String, dynamic>;
      issuedAtStr = map['issued_at'] as String;
      validUntilStr = map['valid_until'] as String;
    } else if (response is Map) {
      issuedAtStr = response['issued_at'] as String;
      validUntilStr = response['valid_until'] as String;
    } else {
      throw Exception(
        'Formato de resposta inválido ao calcular validade no servidor.',
      );
    }

    // Verificar se já existe uma carteirinha para este membro
    final existing = await _supabase
        .from('digital_cards')
        .select('id')
        .eq('member_id', memberId)
        .maybeSingle();

    if (existing != null) {
      // Reativar e renovar a validade usando o timestamp do Postgres
      await _supabase
          .from('digital_cards')
          .update({
            'status': 'active',
            'valid_until': validUntilStr,
            'updated_at': issuedAtStr,
          })
          .eq('member_id', memberId);
    } else {
      // Criar nova carteirinha usando os timestamps do Postgres e garantindo unicidade via UUID
      final uniqueSegment = memberId
          .replaceAll('-', '')
          .toUpperCase()
          .substring(0, 8);
      final cardNumber = 'TEA-ID-$uniqueSegment';
      await _supabase.from('digital_cards').insert({
        'member_id': memberId,
        'user_id': userId,
        'card_number': cardNumber,
        'status': 'active',
        'valid_until': validUntilStr,
        'issued_at': issuedAtStr,
        'front_data': {
          'name': member.name,
          'cpf': member.cpf,
          'bloodType': member.bloodType,
          'cid': member.cid,
        },
        'back_data': {
          'emergencyPersonName': member.emergencyPersonName,
          'emergencyPhone': member.emergencyPhone,
        },
        'qr_validation_url': cardNumber,
        'created_at': issuedAtStr,
        'updated_at': issuedAtStr,
      });
    }
  }

  /// Valida o vencimento da carteirinha no lado do servidor (Postgres) baseado na data civil do projeto.
  Future<bool> isDigitalCardExpiredServer(DateTime validUntil) async {
    try {
      final response = await _supabase.rpc(
        'conectea_is_digital_card_expired',
        params: {'p_valid_until': validUntil.toIso8601String()},
      );
      if (response is bool) {
        return response;
      }
      throw Exception(
        'Retorno inesperado da verificação de expiração: $response',
      );
    } catch (e) {
      debugPrint('Erro na validação de expiração server-side: $e');
      rethrow;
    }
  }

  /// Obtém o prazo administrativo server-side baseado em dias úteis operacionais.
  Future<DateTime> getAdminDeadlineFromServer(int businessDays) async {
    try {
      final response = await _supabase.rpc(
        'conectea_admin_deadline',
        params: {'p_business_days': businessDays},
      );
      if (response is String) {
        return DateTime.parse(response).toUtc();
      }
      throw Exception(
        'Formato de resposta inesperado do prazo do servidor: $response',
      );
    } catch (e) {
      debugPrint('Erro ao obter prazo administrativo server-side: $e');
      rethrow;
    }
  }

  // --- Solicitações de Carteirinha ---
  Future<List<CardRequest>> getCardRequests(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('card_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => CardRequest.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _notifyAdmins(
    String title,
    String message,
    String type, {
    String memberId = '',
  }) async {
    try {
      // Busca os IDs dos administradores via RPC segura.
      // Este método evita a leitura direta da tabela profiles por usuários comuns.
      final List<dynamic> adminTargets = await _supabase.rpc(
        'get_admin_notification_targets',
      );

      debugPrint(
        '🔔 NOTIFY_ADMINS: Alvos obtidos via RPC (Total: ${adminTargets.length})',
      );

      for (var target in adminTargets) {
        // A RPC retorna o campo 'admin_id'
        final String? adminId = target is Map ? target['admin_id'] : null;

        if (adminId != null) {
          await createNotification(
            NotificationItem(
              id: '',
              userId: adminId,
              memberId: memberId,
              title: title,
              message: message,
              type: type,
              createdAt: DateTime.now().toUtc(),
              isRead: false,
              actionLabel: 'Analisar',
              actionRoute: '/home',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao notificar administradores via RPC: $e');
    }
  }

  Future<void> createCardRequest(CardRequest request) async {
    await _supabase.from('card_requests').upsert(request.toJson());

    // Tentar pegar o nome do membro com tratamento robusto e fallback
    String memberName = 'membro';
    try {
      final memberData = await _supabase
          .from('members')
          .select('name')
          .eq('id', request.memberId)
          .single();
      if (memberData['name'] != null &&
          (memberData['name'] as String).trim().isNotEmpty) {
        memberName = memberData['name'];
      }
    } catch (_) {}

    await _notifyAdmins(
      'Nova solicitação recebida',
      'Nova solicitação recebida para a carteirinha de $memberName. Protocolo: ${request.protocol}',
      'new_request',
      memberId: request.memberId,
    );
  }

  Stream<List<CardRequest>> cardRequestsStream(String userId) {
    return _supabase
        .from('card_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => CardRequest.fromJson(json)).toList());
  }

  // --- Administrativo ---
  Future<List<CardRequest>> getAllCardRequests() async {
    try {
      final List<dynamic> data = await _supabase
          .from('card_requests')
          .select('*, members(name)')
          .order('created_at', ascending: false);

      debugPrint(
        'Admin: Solicitações de carteirinha buscadas: ${data.length} itens',
      );
      return data.map((json) {
        try {
          return CardRequest.fromJson(json);
        } catch (e) {
          debugPrint('Erro ao processar CardRequest: $e \n JSON: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro em getAllCardRequests: $e');
      return [];
    }
  }

  Future<void> updateCardRequestStatus(
    String requestId,
    String status, {
    String? adminNotes,
    DateTime? expiresAt,
  }) async {
    final now = DateTime.now().toIso8601String();
    final String notes = adminNotes ?? '';

    // 1. Buscar dados da solicitação e do membro (precisamos desses dados antes para a carteirinha)
    final requestData = await _supabase
        .from('card_requests')
        .select('user_id, member_id')
        .eq('id', requestId)
        .single();

    final String userId = requestData['user_id'];
    final String memberId = requestData['member_id'];

    // Buscar dados do membro na tabela de membros
    final memberData = await _supabase
        .from('members')
        .select()
        .eq('id', memberId)
        .single();

    final Member member = Member.fromJson(memberData);

    // 2. Se o status for 'active' (Aprovado), garantir a existência da carteirinha digital antes das atualizações de status
    if (status == 'active' || status == 'approved') {
      await ensureDigitalCard(
        memberId: memberId,
        userId: userId,
        requestId: requestId,
        member: member,
      );
    }

    // 3. Atualizar o status da solicitação
    final updateData = <String, dynamic>{
      'status': status,
      'admin_notes': notes,
      'updated_at': now,
    };

    if (expiresAt != null) {
      updateData['expires_at'] = expiresAt.toUtc().toIso8601String();
    }

    await _supabase
        .from('card_requests')
        .update(updateData)
        .eq('id', requestId);

    // 4. Sincronizar status com o Membro
    final String memberStatus = (status == 'active' || status == 'approved')
        ? 'active'
        : status;
    await _supabase
        .from('members')
        .update({'status': memberStatus, 'updated_at': now})
        .eq('id', memberId);

    // 5. Se mudar para qualquer outro status (suspenso, reprovado, etc), mudar status da carteirinha existente
    if (status != 'active' && status != 'approved') {
      try {
        await _supabase
            .from('digital_cards')
            .update({'status': status, 'updated_at': now})
            .eq('member_id', memberId);
      } catch (_) {
        // Carteirinha pode não existir ainda
      }
    }

    final String memberName = member.name.trim().isNotEmpty
        ? member.name
        : 'beneficiário';

    // 5. Criar notificação in-app
    String title = 'Atualização de carteirinha';
    String message =
        'O status da carteirinha de $memberName mudou para: ${_getStatusDisplay(status)}';

    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        title = 'Carteirinha aprovada';
        message =
            'A carteirinha digital de $memberName já está disponível para uso.';
        break;
      case 'rejected':
      case 'rejeitada':
        title = 'Solicitação reprovada';
        final cleanNotes = _cleanAdminNotes(notes);
        if (cleanNotes.isNotEmpty) {
          message =
              'Não foi possível aprovar a carteirinha de $memberName neste momento. Motivo: $cleanNotes.';
        } else {
          message =
              'Não foi possível aprovar a carteirinha de $memberName neste momento.';
        }
        break;
      case 'suspended':
      case 'suspensa':
        title = 'Carteirinha suspensa';
        final cleanNotes = _cleanAdminNotes(notes);
        if (cleanNotes.isNotEmpty) {
          message =
              'A carteirinha de $memberName está temporariamente suspensa. Motivo: $cleanNotes.';
        } else {
          message =
              'A carteirinha de $memberName está temporariamente suspensa.';
        }
        break;
      case 'waiting_docs':
        title = 'Documentos pendentes';
        final cleanNotes = _cleanAdminNotes(notes);
        if (cleanNotes.isNotEmpty) {
          message =
              'Para continuar a carteirinha de $memberName, precisamos de alguns documentos. Falta enviar: $cleanNotes.';
        } else {
          message =
              'Para continuar a carteirinha de $memberName, precisamos de alguns documentos.';
        }
        break;
      case 'reviewing_data':
        title = 'Revisão de dados necessária';
        final cleanNotes = _cleanAdminNotes(notes);
        if (cleanNotes.isNotEmpty) {
          message =
              'Algumas informações da carteirinha de $memberName precisam de ajuste antes da análise continuar. Revise: $cleanNotes.';
        } else {
          message =
              'Algumas informações da carteirinha de $memberName precisam de ajuste antes da análise continuar.';
        }
        break;
      case 'expired':
        title = 'Carteirinha vencida';
        message =
            'A carteirinha de $memberName venceu. Solicite a renovação para continuar usando o documento digital.';
        break;
      default:
        final cleanNotes = _cleanAdminNotes(notes);
        if (cleanNotes.isNotEmpty) {
          message +=
              ' Motivo: ${cleanNotes.length > 50 ? "${cleanNotes.substring(0, 47)}..." : cleanNotes}';
        }
    }

    // 5. Criar notificação in-app para o usuário
    await createNotification(
      NotificationItem(
        id: '',
        userId: userId,
        memberId: memberId,
        title: title,
        message: message,
        type: 'status_update:${status.toLowerCase()}',
        createdAt: DateTime.now().toUtc(),
        isRead: false,
        actionLabel: 'Ver',
        actionRoute: '/requests',
      ),
    );
  }

  Future<void> updateCardRequest(CardRequest request) async {
    final data = request.toJson();
    await _supabase.from('card_requests').update(data).eq('id', request.id);

    // Se o usuário reenviou os dados ou documentos, o status volta para waiting_approval
    if (request.status == 'waiting_approval' || request.status == 'renewing') {
      String memberName = 'membro';
      try {
        final memberData = await _supabase
            .from('members')
            .select('name')
            .eq('id', request.memberId)
            .single();
        if (memberData['name'] != null &&
            (memberData['name'] as String).trim().isNotEmpty) {
          memberName = memberData['name'];
        }
      } catch (_) {}

      String holderName = 'O titular';
      try {
        final profileData = await _supabase
            .from('profiles')
            .select('name')
            .eq('id', request.userId)
            .single();
        if (profileData['name'] != null &&
            (profileData['name'] as String).trim().isNotEmpty) {
          holderName = profileData['name'];
        }
      } catch (_) {}

      final String messageText = holderName != 'O titular'
          ? '$holderName atualizou a solicitação da carteirinha de $memberName. Protocolo: ${request.protocol}'
          : 'O titular atualizou a solicitação da carteirinha de $memberName. Protocolo: ${request.protocol}';

      await _notifyAdmins(
        'Solicitação atualizada',
        messageText,
        'request_updated',
        memberId: request.memberId,
      );
    }
  }

  Future<void> updateRequestFileUrl(
    String requestId,
    String field,
    String url,
  ) async {
    await _supabase
        .from('card_requests')
        .update({field: url, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId);
  }

  Future<void> clearRequestDocumentUrls({
    required String requestId,
    required String memberId,
    bool clearDocument = false,
    bool clearMedicalReport = false,
  }) async {
    final now = DateTime.now().toIso8601String();

    // 1. Atualizar card_requests se necessário
    final requestUpdates = <String, dynamic>{};
    if (clearDocument) {
      requestUpdates['document_url'] = '';
    }
    if (clearMedicalReport) {
      requestUpdates['medical_report_url'] = '';
    }

    if (requestUpdates.isNotEmpty) {
      requestUpdates['updated_at'] = now;
      await _supabase
          .from('card_requests')
          .update(requestUpdates)
          .eq('id', requestId);
    }

    // 2. Sincronizar com a tabela members
    final memberUpdates = <String, dynamic>{};
    if (clearDocument) {
      memberUpdates['document_url'] = '';
    }
    if (clearMedicalReport) {
      memberUpdates['medical_report_url'] = '';
    }

    if (memberUpdates.isNotEmpty) {
      memberUpdates['updated_at'] = now;
      await _supabase.from('members').update(memberUpdates).eq('id', memberId);
    }
  }

  Future<List<AppUser>> getAllProfiles() async {
    try {
      final List<dynamic> data = await _supabase
          .from('profiles')
          .select()
          .order('name', ascending: true);

      return data.map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateUserProfileRole(String userId, UserRole role) async {
    await _supabase
        .from('profiles')
        .update({'role': role.dbValue})
        .eq('id', userId);
  }

  /// Permite ao ADM DEV atualizar qualquer campo de qualquer perfil
  Future<void> updateAnyUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _supabase.from('profiles').update(data).eq('id', userId);
  }

  /// Stream de solicitações de carteirinha para o painel administrativo
  Stream<List<CardRequest>> getAllCardRequestsStream() {
    return _supabase
        .from('card_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          final requests = <CardRequest>[];
          for (final json in data) {
            try {
              requests.add(CardRequest.fromJson(json));
            } catch (e) {
              debugPrint('Erro ao processar solicitação na stream: $e');
            }
          }
          return requests;
        });
  }

  Future<Member?> getMemberById(String memberId) async {
    try {
      final data = await _supabase
          .from('members')
          .select()
          .eq('id', memberId)
          .maybeSingle();

      if (data == null) return null;
      return Member.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // --- Notificações ---
  Future<List<NotificationItem>> getNotifications(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('notifications')
          .select('id, title, message, type, is_read, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return data.map((json) => NotificationItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createNotification(NotificationItem notification) async {
    try {
      final json = notification.toJson();
      json.remove(
        'created_at',
      ); // Permite que o Supabase/Postgres gere automaticamente via DEFAULT now()
      await _supabase.from('notifications').insert(json);
      debugPrint(
        '✅ NOTIFICATION_CREATED: Notificação criada com sucesso no banco.',
      );
    } catch (e) {
      debugPrint('Erro ao criar notificação: $e');
    }
  }

  Stream<List<NotificationItem>> notificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map(
          (data) =>
              data.map((json) => NotificationItem.fromJson(json)).toList(),
        );
  }

  Stream<int> unreadNotificationsCountStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((json) => json['is_read'] == false).length);
  }

  Future<bool> hasUnreadNotifications() async {
    try {
      final response = await _supabase.rpc('has_unread_notifications');
      if (response is bool) {
        return response;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao verificar notificações não lidas: $e');
      return false;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> clearAllNotifications(String userId) async {
    await _supabase.from('notifications').delete().eq('user_id', userId);
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'waiting_approval':
        return '🟡 Aguardando Aprovação';
      case 'waiting_docs':
        return '🔵 Aguardando Documentação';
      case 'reviewing_data':
        return '🟠 Revisão de Dados';
      case 'active':
        return '🟢 Ativa';
      case 'rejected':
        return '🔴 Reprovada';
      case 'suspended':
        return '⚫ Suspensa';
      case 'expired':
        return '🟤 Vencida';
      case 'renewing':
        return '🟣 Aguardando Renovação';
      default:
        return status;
    }
  }

  String _cleanAdminNotes(String notes) {
    String cleaned = notes.trim();
    if (cleaned.isEmpty) return '';

    final regexes = [
      RegExp(
        r'^(pendência|pendências|observação|observações|motivo|motivo informado|correção necessária|documento|documentos)\s*:\s*',
        caseSensitive: false,
      ),
    ];

    bool cleanedAny = true;
    while (cleanedAny) {
      cleanedAny = false;
      for (final regex in regexes) {
        if (regex.hasMatch(cleaned)) {
          cleaned = cleaned.replaceFirst(regex, '').trim();
          cleanedAny = true;
        }
      }
    }
    return cleaned;
  }

  /// Preenche de forma atômica os campos opcionais vazios de um membro.
  Future<FillEmptyMemberOptionalFieldsResult> fillEmptyMemberOptionalFields(
    FillEmptyMemberOptionalFieldsParams params,
  ) async {
    try {
      final response = await _supabase.rpc(
        'conectea_fill_empty_member_optional_fields_v2',
        params: params.toRpcParams(),
      );

      if (response == null) {
        throw Exception('A resposta do servidor foi nula.');
      }

      final List<dynamic> list;
      if (response is List) {
        list = response;
      } else {
        throw Exception('A resposta do servidor possui formato inesperado.');
      }

      if (list.isEmpty) {
        throw Exception('Nenhum dado retornado do servidor.');
      }

      if (list.length != 1) {
        throw Exception('Número inesperado de linhas retornadas do servidor.');
      }

      final rawLine = list.first;
      if (rawLine is! Map) {
        throw Exception(
          'A linha retornada pelo servidor não é um mapa válido.',
        );
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(rawLine);
      return FillEmptyMemberOptionalFieldsResult.fromJson(data);
    } on PostgrestException {
      if (kDebugMode) {
        debugPrint('Falha ao preencher campos opcionais do membro.');
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  // --- Alterações de Conta ---

  /// Lista de forma paginada e segura as solicitações de alteração de conta do titular logado.
  Future<List<AccountChangeRequest>> listMyAccountChanges({
    int limit = 10,
    int offset = 0,
  }) async {
    // Validação defensiva no Dart
    if (limit < 1 || limit > 20) {
      throw ArgumentError('O limite de listagem deve estar entre 1 e 20.');
    }
    if (offset < 0) {
      throw ArgumentError('O offset de listagem não pode ser negativo.');
    }

    final response = await _supabase.rpc(
      'conectea_list_my_account_changes_v1',
      params: {'p_limit': limit, 'p_offset': offset},
    );

    if (response == null) {
      return const <AccountChangeRequest>[];
    }

    if (response is! List) {
      throw const FormatException(
        'Formato de resposta inesperado do servidor.',
      );
    }

    final parsedList = <AccountChangeRequest>[];
    for (final item in response) {
      if (item is! Map) {
        throw const FormatException(
          'Elemento de resposta inválido retornado pelo servidor.',
        );
      }
      final rawMap = Map<String, dynamic>.from(item);
      parsedList.add(AccountChangeRequest.fromJson(rawMap));
    }

    return parsedList;
  }

  /// Obtém detalhes de um protocolo de alteração de conta específico do titular logado.
  Future<AccountChangeRequest?> getMyAccountChange({
    required String requestId,
  }) async {
    final cleanId = requestId.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError('O ID da requisição não pode ser vazio.');
    }

    final response = await _supabase.rpc(
      'conectea_get_my_account_change_v1',
      params: {'p_request_id': cleanId},
    );

    if (response == null) {
      return null;
    }

    if (response is! List) {
      throw const FormatException(
        'Formato de resposta inesperado do servidor.',
      );
    }

    if (response.isEmpty) {
      return null;
    }

    if (response.length > 1) {
      throw const FormatException(
        'Mais de um registro retornado pelo servidor.',
      );
    }

    final firstItem = response.first;
    if (firstItem is! Map) {
      throw const FormatException(
        'Formato de registro inválido retornado pelo servidor.',
      );
    }

    final rawMap = Map<String, dynamic>.from(firstItem);
    return AccountChangeRequest.fromJson(rawMap);
  }

  /// Consulta a solicitação ativa de alteração de CPF do titular autenticado.
  Future<AccountChangeRequest?> getMyActiveCpfAccountChange() async {
    final response = await _supabase.rpc(
      'conectea_get_my_active_cpf_account_change_v1',
    );

    if (response == null) {
      return null;
    }

    if (response is! List) {
      throw const FormatException(
        'Formato de resposta inesperado do servidor.',
      );
    }

    if (response.isEmpty) {
      return null;
    }

    if (response.length > 1) {
      throw const FormatException(
        'Mais de um registro retornado pelo servidor.',
      );
    }

    final firstItem = response.first;
    if (firstItem is! Map) {
      throw const FormatException(
        'Formato de registro inválido retornado pelo servidor.',
      );
    }

    final rawMap = Map<String, dynamic>.from(firstItem);
    return AccountChangeRequest.fromJson(rawMap);
  }

  /// Consulta o ciclo ativo de alteração de e-mail usando RPC segura.
  Future<Map<String, dynamic>?> getActiveEmailChangeCycle() async {
    try {
      final response = await _supabase.rpc(
        'conectea_get_active_email_change_cycle_v1',
      );

      if (response == null) return null;

      if (response is Map) {
        final data = Map<String, dynamic>.from(response);
        if (data['has_active_cycle'] == true &&
            data['destination_email_masked'] != null) {
          return {
            'destination_masked': data['destination_email_masked'],
            'expires_at': data['otp_expires_at'],
          };
        }
      }

      return null;
    } catch (e) {
      // Falha silenciosa para evitar travar o app na Home
      return null;
    }
  }

  String _sanitizeCpfChangeError(Object? value) {
    final error = value?.toString();
    switch (error) {
      case 'active_request_exists':
      case 'invalid_request':
      case 'temporarily_unavailable':
      case 'unavailable':
        return error!;
      default:
        return 'temporarily_unavailable';
    }
  }

  /// Solicita a alteração do CPF do titular da conta principal enviando o novo CPF
  /// e o ID do documento de comprovação que foi enviado para o Google Drive.
  Future<Map<String, dynamic>> createCpfChangeRequest({
    required String newCpf,
    required String fileId,
    String? justification,
  }) async {
    try {
      final cleanCpf = newCpf.replaceAll(RegExp(r'[^0-9]'), '');

      final response = await _supabase.functions.invoke(
        'create-cpf-change-request',
        body: {
          'new_cpf': cleanCpf,
          'file_id': fileId,
          'justification': justification?.trim() ?? '',
        },
      );

      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true;
        if (success) {
          return {
            'success': true,
            'request_id': data['request_id'],
            'protocol_number': data['protocol_number'],
          };
        } else {
          final errorRaw = data['error'] ?? data['message'];
          final shouldCleanup = data['should_cleanup_upload'] is bool
              ? data['should_cleanup_upload'] as bool
              : true;
          return {
            'success': false,
            'error': _sanitizeCpfChangeError(errorRaw),
            'should_cleanup_upload': shouldCleanup,
          };
        }
      }

      return {
        'success': false,
        'error': 'temporarily_unavailable',
        'should_cleanup_upload': true,
      };
    } catch (e) {
      if (e is FunctionException) {
        try {
          final details = e.details;
          if (details is Map) {
            final errorRaw = details['error'] ?? details['message'];
            final shouldCleanup = details['should_cleanup_upload'] is bool
                ? details['should_cleanup_upload'] as bool
                : true;
            return {
              'success': false,
              'error': _sanitizeCpfChangeError(errorRaw),
              'should_cleanup_upload': shouldCleanup,
            };
          }
        } catch (_) {}
      }
      return {
        'success': false,
        'error': 'temporarily_unavailable',
        'should_cleanup_upload': true,
      };
    }
  }

  String _sanitizeCpfCancelError(Object? value) {
    final error = value?.toString();
    switch (error) {
      case 'not_found':
      case 'invalid_status':
      case 'not_found_or_not_cancelable':
      case 'unavailable':
      case 'temporarily_unavailable':
        return error!;
      default:
        return 'unavailable';
    }
  }

  /// Cancela uma solicitação ativa de alteração de CPF enviando o requestId para
  /// a Edge Function correspondente, que também agenda o descarte do documento.
  Future<Map<String, dynamic>> cancelCpfChangeRequest({
    required String requestId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'cancel-cpf-change-request',
        body: {'request_id': requestId},
      );

      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true;
        if (success) {
          return {'success': true};
        } else {
          final errorRaw = data['error'] ?? data['message'];
          return {'success': false, 'error': _sanitizeCpfCancelError(errorRaw)};
        }
      }

      return {'success': false, 'error': 'unavailable'};
    } catch (e) {
      if (e is FunctionException) {
        try {
          final details = e.details;
          if (details is Map) {
            final errorRaw = details['error'] ?? details['message'];
            return {
              'success': false,
              'error': _sanitizeCpfCancelError(errorRaw),
            };
          }
        } catch (_) {}
      }
      return {'success': false, 'error': 'unavailable'};
    }
  }
}
