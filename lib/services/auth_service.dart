import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream para monitorar o estado de autenticação
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Obter usuário atual
  User? get currentUser => _supabase.auth.currentUser;

  // Login com E-mail e Senha
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cadastro com E-mail e Senha
  Future<AuthResponse> signUpWithEmailPassword(String email, String password, {String? name}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
