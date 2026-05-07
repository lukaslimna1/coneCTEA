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

  // --- Admin ---
  Future<List<CardRequest>> getAllCardRequests() async {
    try {
      final List<dynamic> data = await _supabase
          .from('card_requests')
          .select()
          .order('created_at', ascending: false);
      
      return data.map((json) => CardRequest.fromJson(json)).toList();
    } catch (e) {
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
}
