import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/routes.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // IMPORTANTE: Use a 'Anon Key' (que começa com 'eyJ...') do seu Dashboard do Supabase.
    // A chave 'sb_publishable_...' é para o Auth Helpers do Web/Next.js e não funciona aqui.
    await Supabase.initialize(
      url: 'https://jyxpofhoohxdqmkdgwtu.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5eHBvZmhvb2h4ZHFta2Rnd3R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwOTc4NDUsImV4cCI6MjA5MzY3Mzg0NX0.GDk-_n8DfA8zMMT2RyoRCab0-HPuWKtKN21LwMxz0cI', 
    );
  } catch (e) {
    debugPrint("Supabase initialization error: $e");
  }
  
  runApp(const ConeCTEAApp());
}

class ConeCTEAApp extends StatelessWidget {
  const ConeCTEAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ConeCTEA',
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
