import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream para monitorar o estado de autenticação
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Obter usuário atual
  User? get currentUser => _supabase.auth.currentUser;

  // Login com E-mail e Senha
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null && !kIsWeb) {
        OneSignal.login(response.user!.id);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Cadastro com E-mail e Senha
  Future<AuthResponse> signUpWithEmailPassword(String email, String password, {Map<String, dynamic>? data}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data ?? {},
      );
      if (response.user != null && !kIsWeb) {
        OneSignal.login(response.user!.id);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    if (!kIsWeb) OneSignal.logout();
    await _supabase.auth.signOut();
  }

  // Recuperação de Senha
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.conectea://login-callback',
    );
  }

  /// Inicia a solicitação de alteração de e-mail por OTP.
  Future<Map<String, dynamic>> startEmailChangeOtp({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'start-email-change-otp',
        body: {
          'new_email': newEmail.trim(),
          'current_password': currentPassword,
          'client_idempotency_key': const Uuid().v4(),
        },
      );

      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'error': 'internal_error'};
    } catch (e) {
      if (e is FunctionException) {
        try {
          final details = e.details;
          if (details is Map) {
            return Map<String, dynamic>.from(details);
          }
        } catch (_) {}
      }
      return {'error': 'connection_error'};
    }
  }

  /// Reenvia o OTP de alteração de e-mail (novo código)
  Future<Map<String, dynamic>> resendEmailChangeOtp() async {
    try {
      final response = await _supabase.functions.invoke(
        'resend-email-change-otp',
        body: {},
      );

      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'error': 'internal_error'};
    } catch (e) {
      if (e is FunctionException) {
        try {
          final details = e.details;
          if (details is Map) {
            return Map<String, dynamic>.from(details);
          }
        } catch (_) {}
      }
      return {'error': 'connection_error'};
    }
  }

  /// Confirma a alteração de e-mail por OTP.
  Future<Map<String, dynamic>> confirmEmailChangeOtp({
    required String otp,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'confirm-email-change-otp',
        body: {
          'otp': otp.trim(),
        },
      );

      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'error': 'internal_error'};
    } catch (e) {
      if (e is FunctionException) {
        try {
          final details = e.details;
          if (details is Map) {
            return Map<String, dynamic>.from(details);
          }
        } catch (_) {}
      }
      return {'error': 'connection_error'};
    }
  }

  /// Cancela o ciclo ativo de alteração de e-mail
  Future<Map<String, dynamic>> cancelEmailChange() async {
    try {
      final response = await _supabase.rpc(
        'conectea_cancel_email_change_v1',
      );

      final data = response as Map<String, dynamic>?;
      if (data != null && data['status'] == 'success') {
        return {'status': 'success'};
      } else if (data != null && data['status'] == 'no_active_cycle') {
        return {'status': 'success'}; // Se não tem ciclo, já está cancelado/limpo
      } else {
        return {
          'status': 'error',
          'error': 'unknown_error',
        };
      }
    } catch (e) {
      if (e is PostgrestException) {
        return {
          'status': 'error',
          'error': e.message,
        };
      }
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Consulta o ciclo ativo de alteração de e-mail do próprio usuário.
  Future<Map<String, dynamic>> getActiveEmailChangeCycle() async {
    try {
      final response = await _supabase.functions.invoke(
        'get-active-email-change-cycle',
        body: {},
      );

      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'error': 'internal_error'};
    } catch (e) {
      if (e is FunctionException) {
        try {
          final details = e.details;
          if (details is Map) {
            return Map<String, dynamic>.from(details);
          }
        } catch (_) {}
      }
      return {'error': 'connection_error'};
    }
  }
}
