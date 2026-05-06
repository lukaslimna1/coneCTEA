import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/firebase_options.dart';
import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("❌ Erro ao Inicializar Firebase: $e");
  }

  FlutterError.onError = (details) {
    debugPrint("🚨 Erro de Flutter: ${details.exception}");
    if (details.exception.toString().contains('isDisposed')) {
      debugPrint("ℹ️ Nota: Erro de disposição detectado. Comum em Hot Restart no Chrome.");
    }
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const ConeCTEAApp(),
    ),
  );
}

class ConeCTEAApp extends StatelessWidget {
  const ConeCTEAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConeCTEA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (auth.currentProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Todos entram pela HomeScreen para ver a experiência do usuário.
    // O botão de ADM aparecerá na HomeScreen se o role for admin.
    return const HomeScreen();
  }
}
