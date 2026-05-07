import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _initialized = false;
  bool _suppressRedirect = false;

  User? get user => _user;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null;
  bool get suppressRedirect => _suppressRedirect;

  void setSuppressRedirect(bool value) {
    _suppressRedirect = value;
    notifyListeners();
  }

  AuthNotifier() {
    _user = _supabase.auth.currentUser;
    _initialized = true;
    
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }
}
