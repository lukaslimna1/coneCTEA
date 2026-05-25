import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/premium/app_background.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/app_user.dart';

import 'home_view.dart';
import '../cards/cards_view.dart';
import '../notificacoes/notifications_view.dart';
import '../account/account_view.dart';
import '../admin/admin_view.dart';
import '../clube/partners_supporters_view.dart';
import '../participar/projects_actions_view.dart';
import '../../core/design_system_v2/design_system_v2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  AppUser? _user;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadNotificationsIndicator();
    }
  }

  Future<void> _refreshUnreadNotificationsIndicator() async {
    try {
      final hasUnread = await _databaseService.hasUnreadNotifications();
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (_) {
      // Fallback silencioso sem expor logs excessivos
    }
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

      final hasUnread = await _databaseService.hasUnreadNotifications();

      if (mounted) {
        setState(() {
          _user = user;
          _hasUnreadNotifications = hasUnread;
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
      appBar: DsAppTopHeader(
        userName: _user?.name,
        userPhotoUrl: null, // Add if available
        notificationCount: 0,
        hasUnreadNotifications: _hasUnreadNotifications,
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
          final newIndex = _getPageIndex(index);
          setState(() => _currentIndex = newIndex);
          _refreshUnreadNotificationsIndicator();
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
            activeIcon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
            inactiveIcon: PhosphorIcons.sparkle(),
            label: 'Participar',
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
        return const ProjectsActionsView();
      case 3:
        return NotificationsView(
          onBack: () async {
            setState(() => _currentIndex = 0);
            await _refreshUnreadNotificationsIndicator();
          },
          onUnreadStatusChanged: () {
            _refreshUnreadNotificationsIndicator();
          },
        );
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
