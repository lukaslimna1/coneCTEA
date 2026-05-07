import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _initialized = false;

  User? get user => _user;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null;

  AuthNotifier() {
    _user = _supabase.auth.currentUser;
    _initialized = true;
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      
      _user = session?.user;
      notifyListeners();
    });
  }
}
