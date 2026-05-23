import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/premium/app_background.dart';
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
import '../account/institutional/partners_supporters_view.dart';
import '../../core/design_system_v2/design_system_v2.dart';

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
  StreamSubscription<List<NotificationItem>>? _notificationsSubscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
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

      await _notificationsSubscription?.cancel();

      if (mounted) {
        setState(() {
          _user = user;
        });
      }

      _notificationsSubscription = _databaseService.notificationsStream(userId).listen((list) {
        if (mounted) {
          setState(() {
            _unreadCount = list.where((n) => !n.isRead).length;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: DsAppTopHeader(
        userName: _user?.name,
        userPhotoUrl: null, // Add if available
        notificationCount: _unreadCount,
        paletteSeed: _user?.id,
        onNotificationTap: () => setState(() => _currentIndex = 3),
        onAvatarTap: () => setState(() => _currentIndex = 4),
        onLogoTap: () => setState(() => _currentIndex = 0),
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: _getCurrentPage(),
        ),
      ),
      bottomNavigationBar: DsBottomNavBar(
        currentIndex: _getNavIndex(),
        onTap: (index) {
          setState(() => _currentIndex = _getPageIndex(index));
        },
        items: [
          DsBottomNavItem(
            activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.house(),
            label: 'Início',
            token: DsCores.comunicacao,
          ),
          DsBottomNavItem(
            activeIcon: PhosphorIcons.identificationCard(
              PhosphorIconsStyle.fill,
            ),
            inactiveIcon: PhosphorIcons.identificationCard(),
            label: 'Carteirinha',
            token: DsCores.carteirinha,
          ),
          DsBottomNavItem(
            activeIcon: PhosphorIcons.handshake(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.handshake(),
            label: 'Clube',
            token: DsCores.suporte,
          ),
          DsBottomNavItem(
            activeIcon: PhosphorIcons.fileText(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.fileText(),
            label: 'Solicitações',
            token: DsCores.solicitacao,
          ),
          DsBottomNavItem(
            activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.user(),
            label: 'Conta',
            token: DsCores.conta,
          ),
          if (_user?.role.isAdmin ?? false)
            DsBottomNavItem(
              activeIcon: PhosphorIcons.bank(PhosphorIconsStyle.fill),
              inactiveIcon: PhosphorIcons.bank(),
              label: 'Gestão',
              token: DsCores.admin,
            ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeView(
          user: _user,
          onNavigate: (index) => setState(() => _currentIndex = index),
        );
      case 1:
        return const CardsView();
      case 2:
        return const RequestsView();
      case 3:
        return NotificationsView(onBack: () => setState(() => _currentIndex = 0));
      case 4:
        return AccountView(user: _user);
      case 5:
        return const AdminView();
      case 6:
        return const PartnersSupportersView(isTab: true);
      default:
        return HomeView(
          user: _user,
          onNavigate: (index) => setState(() => _currentIndex = index),
        );
    }
  }

  int _getNavIndex() {
    final isAdmin = _user?.role.isAdmin ?? false;
    if (_currentIndex == 0) return 0; // Início
    if (_currentIndex == 1) return 1; // Cartão
    if (_currentIndex == 6) return 2; // Clube
    if (_currentIndex == 2) return 3; // Pedido
    if (_currentIndex == 4) return 4; // Conta
    if (_currentIndex == 5 && isAdmin) {
      return 5; // Gestão
    }
    return 0; // Default para notificações (3) or outros
  }

  int _getPageIndex(int navIndex) {
    final isAdmin = _user?.role.isAdmin ?? false;
    if (navIndex == 0) return 0; // Início
    if (navIndex == 1) return 1; // Cartão
    if (navIndex == 2) return 6; // Clube
    if (navIndex == 3) return 2; // Pedido
    if (navIndex == 4) return 4; // Conta
    if (navIndex == 5 && isAdmin) return 5; // Gestão
    return 0;
  }
}
