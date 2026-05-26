import 'package:go_router/go_router.dart';
import 'package:conectea/features/acesso/login/login_page.dart';
import 'package:conectea/features/acesso/cadastro/register_page.dart';
import 'package:conectea/features/acesso/recuperacao/forgot_password_page.dart';
import 'package:conectea/features/acesso/recuperacao/forgot_email_page.dart';
import 'package:conectea/features/home/home_page.dart';
import 'package:conectea/features/carteirinhas/solicitacao/add_member_page.dart';
import 'package:conectea/features/admin/admin_dashboard_page.dart';
import 'package:conectea/features/admin/scanner_view.dart';
import 'package:conectea/core/notifiers/auth_notifier.dart';
import 'package:conectea/core/widgets/device_auth_guard.dart';

/// Definição centralizada das rotas de navegação do aplicativo utilizando GoRouter.
/// Gerencia redirecionamentos baseados no estado de autenticação.
class AppRoutes {
  static final authNotifier = AuthNotifier();

  static final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final location = state.matchedLocation;

      if (authNotifier.suppressRedirect) return null;

      final isLoggingIn = location.startsWith('/login');
      final isRegistering = location.startsWith('/register');
      final isForgotPassword = location.startsWith('/forgot-password');
      final isForgotEmail = location.startsWith('/forgot-email');

      if (!isAuthenticated) {
        if (isLoggingIn || isRegistering || isForgotPassword || isForgotEmail) {
          return null;
        }
        return '/login';
      }

      if (isLoggingIn || isRegistering || location == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const DeviceAuthGuard(child: HomePage()),
      ),
      GoRoute(
        path: '/add-member',
        builder: (context, state) => const AddMemberPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/forgot-email',
        builder: (context, state) => const ForgotEmailPage(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const ScannerView(),
      ),
    ],
  );
}
