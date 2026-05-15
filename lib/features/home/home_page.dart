import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/premium/app_top_header.dart';
import '../../core/widgets/premium/app_background.dart';
import '../../core/widgets/premium/premium_bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/app_user.dart';
import '../../models/notification_item.dart';

import 'home_view.dart';
import '../cards/cards_view.dart';
import '../requests/requests_view.dart';
import '../notifications/notifications_view.dart';
import '../account/account_view.dart';
import '../admin/admin_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  AppUser? _user;
  Stream<List<NotificationItem>>? _notificationsStream;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUser = _authService.currentUser;
    final userId = currentUser?.id;
    if (userId != null) {
      var user = await _databaseService.getUserProfile(userId);

      if (user == null) {
        final email = _authService.currentUser?.email ?? '';
        final metaName =
            _authService.currentUser?.userMetadata?['name'] ??
            _authService.currentUser?.userMetadata?['full_name'] ??
            email.split('@')[0];

        user = AppUser(
          id: userId,
          email: email,
          name: metaName,
          role: UserRole.user, // Fallback local seguro
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          cpf: '',
          phone: '',
          isActive: true,
        );
      }

      _notificationsStream = _databaseService.notificationsStream(userId);

      if (mounted) {
        setState(() {
          _user = user;
        });

        _notificationsStream!.listen((list) {
          if (mounted) {
            setState(() {
              _unreadCount = list.where((n) => !n.isRead).length;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppTopHeader(
        userName: _user?.name,
        userPhotoUrl: null, // Add if available
        notificationCount: _unreadCount,
        paletteSeed: _user?.id,
        onNotificationTap: () => setState(() => _currentIndex = 3),
        onAvatarTap: () => setState(() => _currentIndex = 4),
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: _getCurrentPage(),
        ),
      ),
      bottomNavigationBar: PremiumBottomNavBar(
        currentIndex: _getNavIndex(),
        onTap: (index) {
          setState(() => _currentIndex = _getPageIndex(index));
        },
        items: [
          PremiumNavItem(
            activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.house(),
            label: 'Início',
          ),
          PremiumNavItem(
            activeIcon: PhosphorIcons.identificationCard(
              PhosphorIconsStyle.fill,
            ),
            inactiveIcon: PhosphorIcons.identificationCard(),
            label: 'Carteirinha',
          ),
          PremiumNavItem(
            activeIcon: PhosphorIcons.fileText(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.fileText(),
            label: 'Solicitações',
          ),
          if (_user?.role.isAdmin ?? false)
            PremiumNavItem(
              activeIcon: PhosphorIcons.bank(PhosphorIconsStyle.fill),
              inactiveIcon: PhosphorIcons.bank(),
              label: 'Gestão',
            ),
          PremiumNavItem(
            activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.user(),
            label: 'Conta',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeView(onNavigate: (index) => setState(() => _currentIndex = index));
      case 1:
        return const CardsView();
      case 2:
        return const RequestsView();
      case 3:
        return const NotificationsView();
      case 4:
        return AccountView(user: _user);
      case 5:
        return const AdminView();
      default:
        return HomeView(onNavigate: (index) => setState(() => _currentIndex = index));
    }
  }

  int _getNavIndex() {
    final isAdmin = _user?.role.isAdmin ?? false;
    if (_currentIndex == 0) return 0;
    if (_currentIndex == 1) return 1;
    if (_currentIndex == 2) return 2;
    if (_currentIndex == 5 && isAdmin) {
      return 3; // AdminView is 4th item if admin
    }
    if (_currentIndex == 4) {
      return isAdmin ? 4 : 3; // AccountView is 5th if admin, else 4th
    }
    return 0; // Default to home for notifications (3) or others
  }

  int _getPageIndex(int navIndex) {
    final isAdmin = _user?.role.isAdmin ?? false;
    if (navIndex == 0) return 0;
    if (navIndex == 1) return 1;
    if (navIndex == 2) return 2;
    if (isAdmin) {
      if (navIndex == 3) return 5; // Gestão
      if (navIndex == 4) return 4; // Conta
    } else {
      if (navIndex == 3) return 4; // Conta
    }
    return 0;
  }
}
