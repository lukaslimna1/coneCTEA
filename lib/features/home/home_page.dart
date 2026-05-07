import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/app_user.dart';
import 'home_view.dart';
import '../cards/cards_view.dart';
import '../requests/requests_view.dart';
import '../notifications/notifications_view.dart';
import '../account/account_view.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      final user = await _databaseService.getUserProfile(userId);
      final notifications = await _databaseService.getNotifications(userId);
      if (mounted) {
        setState(() {
          _user = user;
          _unreadCount = notifications.where((n) => !n.isRead).length;
        });
      }
    }
  }

  String get _initials {
    if (_user == null) return 'U';
    final name = _user!.socialName ?? _user!.name;
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
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
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Hero(
            tag: 'app_logo_mini',
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              height: 54, // Slightly larger for better legibility
              placeholderBuilder: (context) => const Text(
                'ConeCTEA',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          _buildNotificationAction(),
          const SizedBox(width: 8),
          _buildUserAvatar(),
          const SizedBox(width: 20),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildNotificationAction() {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 28),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
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
      onPressed: () {
        setState(() {
          _currentIndex = 3; // Go to notifications
        });
      },
    );
  }

  Widget _buildUserAvatar() {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
        child: Center(
          child: Text(
            _initials,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

