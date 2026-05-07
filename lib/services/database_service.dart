import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/member.dart';
import '../models/card_request.dart';
import '../models/digital_card.dart';
import '../models/notification_item.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // --- Profile ---
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

  // --- Members ---
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

  Future<void> addMember(Member member) async {
    final data = member.toJson();
    await _supabase.from('members').upsert(data);
  }

  Future<void> updateMember(Member member) async {
    final data = member.toJson();
    await _supabase.from('members').update(data).eq('id', member.id);
  }

  // --- Digital Cards ---
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

  Future<void> createDigitalCard(DigitalCard card) async {
    await _supabase.from('digital_cards').upsert(card.toJson());
  }

  // --- Card Requests ---
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

  Future<void> createCardRequest(CardRequest request) async {
    await _supabase.from('card_requests').upsert(request.toJson());
  }

  Stream<List<CardRequest>> cardRequestsStream(String userId) {
    return _supabase
        .from('card_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => CardRequest.fromJson(json)).toList());
  }

  // --- Admin ---
  Future<List<CardRequest>> getAllCardRequests() async {
    try {
      final List<dynamic> data = await _supabase
          .from('card_requests')
          .select()
          .order('created_at', ascending: false);
      
      debugPrint('Admin Fetched Card Requests: \${data.length} items');
      return data.map((json) {
        try {
          return CardRequest.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing CardRequest: $e \\n JSON: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error in getAllCardRequests: $e');
      return [];
    }
  }

  Future<void> updateCardRequestStatus(String requestId, String status, {String? adminNotes}) async {
    final Map<String, dynamic> updates = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (adminNotes != null) {
      updates['admin_notes'] = adminNotes;
    }
    await _supabase.from('card_requests').update(updates).eq('id', requestId);
  }

  Future<void> updateCardRequest(CardRequest request) async {
    final data = request.toJson();
    await _supabase.from('card_requests').update(data).eq('id', request.id);
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
      'role': role == UserRole.admin ? 'admin' : 'user'
    }).eq('id', userId);
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

  // --- Notifications ---
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
    await _supabase.from('notifications').insert(notification.toJson());
  }

  Stream<List<NotificationItem>> notificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationItem.fromJson(json)).toList());
  }

  Future<void> updateCardStatus(String requestId, String status, String notes) async {
    final now = DateTime.now().toIso8601String();

    // 1. Atualizar o status da solicitação
    await _supabase.from('card_requests').update({
      'status': status,
      'admin_notes': notes,
      'updated_at': now,
    }).eq('id', requestId);

    // 2. Buscar dados da solicitação e do membro
    final requestData = await _supabase
        .from('card_requests')
        .select('user_id, member_id')
        .eq('id', requestId)
        .single();
    
    final String userId = requestData['user_id'];
    final String memberId = requestData['member_id'];

    // Buscar o nome do membro na tabela de membros
    final memberData = await _supabase
        .from('members')
        .select('name')
        .eq('id', memberId)
        .single();
    
    final String memberName = memberData['name'];

    // 3. Sincronizar status com o Membro
    await _supabase.from('members').update({
      'status': status,
      'updated_at': now,
    }).eq('id', memberId);

    // 4. Criar notificação in-app
    String message = 'O status da carteirinha de $memberName mudou para: ${_getStatusDisplay(status)}';
    if (notes.isNotEmpty && !notes.contains('Pendência:')) {
      message += '\nMotivo: ${notes.length > 50 ? notes.substring(0, 47) + "..." : notes}';
    }

    await createNotification(NotificationItem(
      id: '', // UUID gerado pelo banco
      userId: userId,
      memberId: memberId,
      title: 'Atualização de Carteirinha',
      message: message,
      type: 'status_change',
      createdAt: DateTime.now(),
      isRead: false,
      actionLabel: 'Ver Detalhes',
      actionRoute: '/home',
    ));
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
