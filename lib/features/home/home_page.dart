import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/app_user.dart';
import 'home_view.dart';
import '../cards/cards_view.dart';
import '../requests/requests_view.dart';
import '../notifications/notifications_view.dart';
import '../account/account_view.dart';
import '../admin/admin_view.dart';
import '../../models/notification_item.dart';
import '../../core/widgets/user_role_badge.dart';

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
  int _unreadCount = 0;
  Stream<List<NotificationItem>>? _notificationsStream;

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
        final metaName = _authService.currentUser?.userMetadata?['name'] 
            ?? _authService.currentUser?.userMetadata?['full_name']
            ?? email.split('@')[0];
        
        user = AppUser(
          id: userId,
          email: email,
          name: metaName,
          role: (email == 'lucasmslima1@gmail.com') ? UserRole.adminDev : UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          cpf: '',
          phone: '',
          isActive: true,
        );
      } else if (user.name.isEmpty) {
        final metaName = _authService.currentUser?.userMetadata?['name'] 
            ?? _authService.currentUser?.userMetadata?['full_name'];
        if (metaName != null) {
          user = user.copyWith(name: metaName);
        }
      }

      final notifications = await _databaseService.getNotifications(userId);
      _notificationsStream = _databaseService.notificationsStream(userId);

      if (mounted) {
        setState(() {
          _user = user;
          _unreadCount = notifications.where((n) => !n.isRead).length;
        });

        // Listen to notifications stream to update unread count
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

  String get _initials {
    if (_user == null) return 'U';
    final name = (_user!.socialName != null && _user!.socialName!.isNotEmpty)
        ? _user!.socialName!
        : _user!.name;

    if (name.trim().isEmpty) return 'U';
    
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeView(onNavigate: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const CardsView(),
      const RequestsView(),
      const NotificationsView(),
      const AccountView(),
      const AdminView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPremium,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF071022), // quase preto-azul
                Color(0xFF0D1B3E), // azul institucional profundo
                Color(0xFF111830), // tom escuro base
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Logo com tag Hero para animação de transição
                  Hero(
                    tag: 'app_logo_mini',
                    child: SvgPicture.asset(
                      'assets/images/logo_horizontal.svg',
                      width: 150,
                      height: 40,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => Text(
                        'ConeCTEA',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Badge Admin (se aplicável)
                  if (_user?.role.isAdmin ?? false) ...[
                    UserRoleBadge(
                      role: _user!.role,
                      onTap: () => setState(() => _currentIndex = 5),
                    ),
                    const SizedBox(width: 14),
                  ],
                  // Sino de notificações
                  _buildNotificationAction(),
                  const SizedBox(width: 14),
                  // Avatar
                  _buildUserAvatar(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isAdmin = _user?.role.isAdmin ?? false;
    
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Início'),
          _buildNavItem(1, Icons.badge_rounded, 'Carteirinha'),
          _buildNavItem(2, Icons.description_rounded, 'Solicitações'),
          if (isAdmin) _buildNavItem(5, Icons.admin_panel_settings_rounded, 'Gestão'),
          _buildNavItem(4, Icons.person_rounded, 'Conta'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badge = 0}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              if (badge > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationAction() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D1B3E), width: 2),
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C3AED), // roxo ConeCTEA
            Color(0xFF14B8A6), // teal ConeCTEA
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

