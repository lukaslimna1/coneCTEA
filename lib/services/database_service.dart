import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/member.dart';
import '../models/digital_card.dart';
import '../models/card_request.dart';
import '../models/notification_item.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- User Profile ---
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return AppUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUserProfile(AppUser user) async {
    await _supabase.from('profiles').insert(user.toJson());
  }

  // --- Members ---
  Future<List<Member>> getMembers(String userId) async {
    try {
      final response = await _supabase
          .from('members')
          .select()
          .eq('user_id', userId);
      
      return (response as List).map((m) => Member.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addMember(Member member) async {
    await _supabase.from('members').insert(member.toJson());
  }

  // --- Digital Cards ---
  Future<List<DigitalCard>> getDigitalCards(String userId) async {
    try {
      final response = await _supabase
          .from('digital_cards')
          .select()
          .eq('user_id', userId);
      
      return (response as List).map((c) => DigitalCard.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Card Requests ---
  Future<List<CardRequest>> getCardRequests(String userId) async {
    try {
      final response = await _supabase
          .from('card_requests')
          .select()
          .eq('user_id', userId);
      
      return (response as List).map((r) => CardRequest.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createCardRequest(CardRequest request) async {
    await _supabase.from('card_requests').insert(request.toJson());
  }

  // --- Notifications ---
  Future<List<NotificationItem>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List).map((n) => NotificationItem.fromJson(n)).toList();
    } catch (e) {
      return [];
    }
  }
}
