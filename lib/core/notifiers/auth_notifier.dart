import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notificador responsável por gerenciar o estado de autenticação do usuário.
/// Mantém o usuário atualizado via streams do Supabase e controla redirecionamentos.
class AuthNotifier extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _initialized = false;
  bool _suppressRedirect = false;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  bool get initialized => _initialized;
  bool get isAuthenticated => _user != null;
  bool get suppressRedirect => _suppressRedirect;

  /// Controla se o redirecionamento automático deve ser suprimido.
  /// Útil durante processos de onboarding ou fluxos específicos.
  void setSuppressRedirect(bool value) {
    if (_suppressRedirect == value) return;
    _suppressRedirect = value;
    notifyListeners();
  }

  AuthNotifier() {
    _user = _supabase.auth.currentUser;
    _initialized = true;
    
    // Escuta mudanças no estado de autenticação (login, logout, token refresh)
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
