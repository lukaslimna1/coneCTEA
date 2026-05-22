import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/app/routes.dart';
import 'package:conectea/app/theme.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserva a splash nativa até que o app esteja pronto
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  bool keepConnected = true;
  // Verificação preventiva da preferência "Manter conectado" (Fail-Closed)
  // Realizada de forma síncrona/física ANTES da inicialização do Supabase para determinar a estratégia de storage
  try {
    final prefs = await SharedPreferences.getInstance();
    keepConnected = prefs.getBool('conectea_keep_connected') ?? true;

    if (!keepConnected) {
      // Limpeza complementar da chave física do SharedPreferences
      await prefs.remove(supabasePersistSessionKey);

      if (!kIsWeb) {
        await OneSignal.logout();
      }
    }
  } catch (e) {
    keepConnected = false; // Fail-Closed
    if (kDebugMode) {
      debugPrint("[Auth] Falha ao verificar preferência de persistência da sessão. Ativando proteção fail-closed.");
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(supabasePersistSessionKey);
      if (!kIsWeb) {
        await OneSignal.logout();
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint("[Auth] Falha crítica ao invalidar sessão no fallback de segurança.");
      }
    }
  }

  try {
    if (keepConnected) {
      // Inicialização Padrão com persistência de sessão ativada
      await Supabase.initialize(
        url: 'https://jyxpofhoohxdqmkdgwtu.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5eHBvZmhvb2h4ZHFta2Rnd3R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTc4NDUsImV4cCI6MjA5MzY3Mzg0NX0.GDk-_n8DfA8zMMT2RyoRCab0-HPuWKtKN21LwMxz0cI',
      );
    } else {
      // Inicialização com EmptyLocalStorage para desativar completamente a persistência e restauração de sessão
      await Supabase.initialize(
        url: 'https://jyxpofhoohxdqmkdgwtu.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5eHBvZmhvb2h4ZHFta2Rnd3R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTc4NDUsImV4cCI6MjA5MzY3Mzg0NX0.GDk-_n8DfA8zMMT2RyoRCab0-HPuWKtKN21LwMxz0cI',
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
        ),
      );
    }
    
    // Configuração do OneSignal para Push Notifications (apenas mobile)
    if (!kIsWeb) {
      // Evita logs excessivos em produção ajustando nível verbose para debug apenas
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      } else {
        OneSignal.Debug.setLogLevel(OSLogLevel.none);
      }
      OneSignal.initialize("e4ccd512-3add-465f-8195-eaf6f3ce86aa");
      OneSignal.Notifications.requestPermission(true);
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Init] Falha ao inicializar serviços essenciais do aplicativo.');
    }
  }
  
  // Remove a splash nativa agora que a inicialização terminou
  FlutterNativeSplash.remove();
  
  runApp(const ConeCTEAApp());
}

class ConeCTEAApp extends StatelessWidget {
  const ConeCTEAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ConeCTEA',
      theme: AppTheme.nightTheme,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
