import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/home/home_page.dart';
import '../features/requests/add_member_page.dart';
import '../features/requests/member_selection_page.dart';
import '../features/admin/admin_dashboard_page.dart';
import '../models/member.dart';
import '../core/notifiers/auth_notifier.dart';

class AppRoutes {
  static final authNotifier = AuthNotifier();

  static final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (authNotifier.suppressRedirect) {
        return null;
      }

      if (!isAuthenticated) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      if (isLoggingIn || isRegistering) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/add-member',
        builder: (context, state) => const AddMemberPage(),
      ),
      GoRoute(
        path: '/member-selection',
        builder: (context, state) => const MemberSelectionPage(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
}

