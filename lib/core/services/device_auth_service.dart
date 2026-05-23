import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável pela autenticação local do dispositivo (biometria ou PIN/padrão/senha).
/// 
/// Realiza a ponte com o pacote `local_auth` e gerencia a preferência do usuário localmente,
/// garantindo que nenhum dado sensível de autenticação seja transmitido ou persistido no app.
class DeviceAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _unlockKey = 'conectea_device_unlock_enabled';

  // Construtor privado e instância estática para padrão Singleton.
  static final DeviceAuthService _instance = DeviceAuthService._internal();
  factory DeviceAuthService() => _instance;
  DeviceAuthService._internal();

  /// Verifica se o dispositivo possui capacidade física e suporte de SO para autenticação local.
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      return supported;
    } catch (_) {
      // Fallback resiliente para emuladores e dispositivos Android:
      // Todo aparelho Android possui suporte nativo do SO para segurança (PIN, padrão, senha).
      return true;
    }
  }

  /// Verifica se o dispositivo possui hardware de biometria disponível.
  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Solicita a autenticação nativa do dispositivo.
  /// 
  /// Oferece biometria (digital ou facial) e permite fallback nativo do aparelho
  /// (como PIN, padrão de desenho ou senha do Android) caso a biometria não esteja cadastrada.
  Future<bool> authenticate() async {
    if (kIsWeb) return true; // Web ignora o bloqueio com sucesso
    
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para acessar o ConeCTEA.',
        biometricOnly: false, // Permite fallback nativo para PIN, padrão ou senha
        persistAcrossBackgrounding: true, // Garante que a autenticação continue ativa se o app for para segundo plano
      );
    } on PlatformException catch (_) {
      // Retorna false de forma segura em caso de erros de plataforma (ex: indisponibilidade temporária)
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Recupera se o desbloqueio do aparelho está ativo para o ConeCTEA.
  /// 
  /// Default: `false`.
  Future<bool> isDeviceUnlockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_unlockKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Define a preferência de desbloqueio do aparelho para o ConeCTEA.
  Future<bool> setDeviceUnlockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_unlockKey, enabled);
    } catch (_) {
      return false;
    }
  }
}
