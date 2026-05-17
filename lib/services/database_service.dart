import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/notification_item.dart';

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

  Future<bool> isMemberCpfRegistered(String cpf) async {
    try {
      final response = await _supabase
          .from('members')
          .select('id')
          .eq('cpf', cpf)
          .maybeSingle();
      return response != null;
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
  /// isActive é derivado de status=='active' no Dart — não depende da coluna is_active.
  Future<void> ensureDigitalCard({
    required String memberId,
    required String userId,
    required String requestId,
    required Member member,
  }) async {
    final now = DateTime.now();
    final validUntil = DateTime(now.year + 1, now.month, now.day);

    // Verificar se já existe uma carteirinha para este membro
    final existing = await _supabase
        .from('digital_cards')
        .select('id')
        .eq('member_id', memberId)
        .maybeSingle();

    if (existing != null) {
      // Reativar e renovar a validade
      await _supabase.from('digital_cards').update({
        'status': 'active',
        'valid_until': validUntil.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('member_id', memberId);
    } else {
      // Criar nova carteirinha
      final cardNumber = 'TEA-ID-${now.millisecondsSinceEpoch.toRadixString(16).toUpperCase().substring(0, 8)}';
      await _supabase.from('digital_cards').insert({
        'member_id': memberId,
        'user_id': userId,
        'card_number': cardNumber,
        'status': 'active',
        'valid_until': validUntil.toIso8601String(),
        'issued_at': now.toIso8601String(),
        'front_data': {
          'name': member.name,
          'cpf': member.cpf,
          'bloodType': member.bloodType,
          'cid': member.cid,
        },
        'back_data': {'emergencyContact': member.emergencyContact},
        'qr_validation_url': cardNumber,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
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

  Future<void> _notifyAdmins(String title, String message, String type, {String memberId = ''}) async {
    try {
      // Busca os IDs dos administradores via RPC segura.
      // Este método evita a leitura direta da tabela profiles por usuários comuns.
      final List<dynamic> adminTargets = await _supabase.rpc('get_admin_notification_targets');

      debugPrint('🔔 NOTIFY_ADMINS: Alvos obtidos via RPC (Total: ${adminTargets.length})');

      for (var target in adminTargets) {
        // A RPC retorna o campo 'admin_id'
        final String? adminId = target is Map ? target['admin_id'] : null;

        if (adminId != null) {
          await createNotification(NotificationItem(
            id: '',
            userId: adminId,
            memberId: memberId,
            title: title,
            message: message,
            type: type,
            createdAt: DateTime.now(),
            isRead: false,
            actionLabel: 'Analisar',
            actionRoute: '/home',
          ));
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
      final memberData = await _supabase.from('members').select('name').eq('id', request.memberId).single();
      if (memberData['name'] != null && (memberData['name'] as String).trim().isNotEmpty) {
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
      
      debugPrint('Admin: Solicitações de carteirinha buscadas: ${data.length} itens');
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

  Future<void> updateCardRequestStatus(String requestId, String status, {String? adminNotes, DateTime? expiresAt}) async {
    final now = DateTime.now().toIso8601String();
    final String notes = adminNotes ?? '';

    // 1. Atualizar o status da solicitação
    final updateData = <String, dynamic>{
      'status': status,
      'admin_notes': notes,
      'updated_at': now,
    };

    if (expiresAt != null) {
      updateData['expires_at'] = expiresAt.toIso8601String();
    }

    await _supabase.from('card_requests').update(updateData).eq('id', requestId);

    // 2. Buscar dados da solicitação e do membro
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

    // 3. Sincronizar status com o Membro
    // Se status for active ou approved, o membro fica ativo. Caso contrário, segue o status.
    final String memberStatus = (status == 'active' || status == 'approved') ? 'active' : status;
    await _supabase.from('members').update({
      'status': memberStatus,
      'updated_at': now,
    }).eq('id', memberId);

    // 4. Se o status for 'active' (Aprovado), garantir a existência da carteirinha digital
    if (status == 'active' || status == 'approved') {
      await ensureDigitalCard(
        memberId: memberId,
        userId: userId,
        requestId: requestId,
        member: member,
      );
    } else {
      // Se mudar para qualquer outro status (suspenso, reprovado, etc), mudar status da carteirinha
      try {
        await _supabase.from('digital_cards').update({
          'status': status,
          'updated_at': now,
        }).eq('member_id', memberId);
      } catch (_) {
        // Carteirinha pode não existir ainda
      }
    }

    final String memberName = member.name.trim().isNotEmpty
        ? member.name
        : 'beneficiário';

    // 5. Criar notificação in-app
    String title = 'Atualização de carteirinha';
    String message = 'O status da carteirinha de $memberName mudou para: ${_getStatusDisplay(status)}';
    
    switch (status.toLowerCase()) {
      case 'approved': 
      case 'active': 
        title = 'Carteirinha aprovada';
        message = 'A carteirinha digital de $memberName já está disponível para uso.';
        break;
      case 'rejected': 
      case 'rejeitada': 
        title = 'Solicitação não aprovada';
        message = 'Não conseguimos aprovar a solicitação da carteirinha de $memberName neste momento.';
        if (notes.isNotEmpty) {
          message += ' Motivo informado: $notes';
        }
        break;
      case 'suspended': 
      case 'suspensa': 
        title = 'Carteirinha suspensa';
        message = 'A carteirinha de $memberName foi suspensa temporariamente.';
        if (notes.isNotEmpty) {
          message += ' Motivo informado: $notes';
        }
        break;
      case 'waiting_docs': 
        title = 'Documentos pendentes';
        message = 'Precisamos de alguns documentos para continuar a solicitação de $memberName.';
        if (notes.isNotEmpty) {
          message += ' Pendência: $notes';
        }
        break;
      case 'reviewing_data': 
        title = 'Revisão de dados necessária';
        message = 'Alguns dados da solicitação de $memberName precisam de revisão.';
        if (notes.isNotEmpty) {
          message += ' Correção necessária: $notes';
        }
        break;
      case 'expired': 
        title = 'Carteirinha vencida';
        message = 'A carteirinha de $memberName venceu. Solicite a renovação para continuar usando o documento digital.';
        break;
      default:
        if (notes.isNotEmpty && !notes.contains('Pendência:')) {
          message += ' Motivo: ${notes.length > 50 ? "${notes.substring(0, 47)}..." : notes}';
        }
    }

    // 5. Criar notificação in-app para o usuário
    await createNotification(NotificationItem(
      id: '',
      userId: userId,
      memberId: memberId,
      title: title,
      message: message,
      type: 'status_update:${status.toLowerCase()}',
      createdAt: DateTime.now(),
      isRead: false,
      actionLabel: 'Ver',
      actionRoute: '/requests',
    ));

    // 6. Disparar Push Notification via OneSignal
    await _sendPushNotification(
      userId: userId,
      title: title,
      message: message,
    );
  }

  Future<void> updateCardRequest(CardRequest request) async {
    final data = request.toJson();
    await _supabase.from('card_requests').update(data).eq('id', request.id);

    // Se o usuário reenviou os dados ou documentos, o status volta para waiting_approval
    if (request.status == 'waiting_approval' || request.status == 'renewing') {
      String memberName = 'membro';
      try {
        final memberData = await _supabase.from('members').select('name').eq('id', request.memberId).single();
        if (memberData['name'] != null && (memberData['name'] as String).trim().isNotEmpty) {
          memberName = memberData['name'];
        }
      } catch (_) {}

      String holderName = 'O titular';
      try {
        final profileData = await _supabase.from('profiles').select('name').eq('id', request.userId).single();
        if (profileData['name'] != null && (profileData['name'] as String).trim().isNotEmpty) {
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

  /// Método neutralizado no cliente por segurança.
  /// O disparo de Push Notifications via OneSignal REST API deve ser realizado
  /// exclusivamente através de backend ou Supabase Edge Functions para proteger a API Key.
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    // Registro em debug para rastrear a intenção de envio
    debugPrint('🔔 PUSH_PENDING: Enviando notificação remota.');
    debugPrint('Nota: O disparo real deve ser implementado via Edge Function.');
    
    // As notificações internas (NotificationItem) continuam sendo criadas no banco
    // e lidas pelo app via Stream em tempo real.
  }

  Future<void> updateRequestFileUrl(String requestId, String field, String url) async {
    await _supabase.from('card_requests').update({
      field: url,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
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
    await _supabase.from('profiles').update({
      'role': role.dbValue
    }).eq('id', userId);
  }

  /// Permite ao ADM DEV atualizar qualquer campo de qualquer perfil
  Future<void> updateAnyUserProfile(String userId, Map<String, dynamic> data) async {
    await _supabase.from('profiles').update(data).eq('id', userId);
  }

  /// Stream com JOIN manual de memberName (Supabase stream não suporta joins nativos)
  Stream<List<CardRequest>> getAllCardRequestsStream() {
    return _supabase
        .from('card_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final requests = <CardRequest>[];
          for (final json in data) {
            try {
              final memberId = json['member_id']?.toString() ?? '';
              Map<String, dynamic> enriched = Map<String, dynamic>.from(json);
              
              // Sempre buscar o nome se não estiver presente ou estiver vazio
              if (memberId.isNotEmpty && (enriched['memberName'] == null || enriched['memberName'].toString().isEmpty)) {
                try {
                  final memberData = await _supabase
                      .from('members')
                      .select('name')
                      .eq('id', memberId)
                      .maybeSingle();
                  
                  if (memberData != null) {
                    enriched['memberName'] = memberData['name'];
                  }
                } catch (e) {
                  debugPrint('Erro ao buscar nome do membro para a stream: $e');
                }
              }
              requests.add(CardRequest.fromJson(enriched));
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
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return data.map((json) => NotificationItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createNotification(NotificationItem notification) async {
    try {
      await _supabase.from('notifications').insert(notification.toJson());
      debugPrint('✅ NOTIFICATION_CREATED: Notificação criada com sucesso no banco.');
    } catch (e) {
      debugPrint('Erro ao criar notificação: $e');
    }
  }

  Stream<List<NotificationItem>> notificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((json) => json['user_id'] == userId)
            .map((json) => NotificationItem.fromJson(json))
            .toList());
  }

  Stream<int> unreadNotificationsCountStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['user_id'] == userId && json['is_read'] == false)
            .length);
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
    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId);
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'waiting_approval': return '🟡 Aguardando Aprovação';
      case 'waiting_docs': return '🔵 Aguardando Documentação';
      case 'reviewing_data': return '🟠 Revisão de Dados';
      case 'active': return '🟢 Ativa';
      case 'rejected': return '🔴 Reprovada';
      case 'suspended': return '⚫ Suspensa';
      case 'expired': return '🟤 Vencida';
      case 'renewing': return '🟣 Aguardando Renovação';
      default: return status;
    }
  }
}
