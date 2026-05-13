import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/notification_item.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:intl/intl.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  List<NotificationItem> _notifications = [];
  Stream<List<NotificationItem>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      await _databaseService.markAllNotificationsAsRead(userId);
    }
  }

  Future<void> _clearNotifications() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      await _databaseService.clearAllNotifications(userId);
    }
  }

  Future<void> _loadNotifications() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      _notificationsStream = _databaseService.notificationsStream(userId);
      final notifications = await _databaseService.getNotifications(userId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cardTitle,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mantenha-se informado sobre sua conta.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.cardSubtitle,
                          ),
                        ),
                      ],
                    ),
                    if (_notifications.isNotEmpty)
                      _buildClearButton(),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<NotificationItem>>(
                  stream: _notificationsStream,
                  initialData: _notifications,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    
                    final notifications = snapshot.data ?? [];
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _notifications.length != notifications.length) {
                        setState(() {
                          _notifications = notifications;
                        });
                      }
                    });

                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildNotificationItem(notifications[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () => _showClearDialog(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xA60F172A), // Dark Glass base
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x2E94A3B8), // Glass border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            PhosphorIconsRegular.trash,
            color: Color(0xFFFF5555), // Refined premium red
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Limpar notificações?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.cardTitle),
        ),
        content: Text(
          'Isso removerá permanentemente todas as suas notificações.',
          style: GoogleFonts.inter(color: AppColors.cardSubtitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.cardMutedText)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);
              try {
                await _clearNotifications();
                if (mounted) {
                  scaffold.showSnackBar(
                    const SnackBar(content: Text('Notificações removidas!'), backgroundColor: AppColors.statusGreen),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('Não foi possível limpar as notificações agora. Tente novamente.'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
              navigator.pop();
            },
            child: Text('LIMPAR TUDO', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.bellSlash, size: 64, color: AppColors.cardMutedText),
          ),
          const SizedBox(height: 24),
          Text(
            'Tudo limpo por aqui!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você não tem novas notificações no momento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.cardSubtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    final dateFormatted = DateFormat('dd MMM, HH:mm').format(item.createdAt);
    final ui = _getTypeUI(item.type);

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      hasGradient: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone com gradiente suave (Premium)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ui.color.withValues(alpha: 0.3), // Clearer/Lighter at top
                  ui.color.withValues(alpha: 0.05), // Darker at base
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ui.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(ui.icon, color: ui.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.cardTitle,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.cardSubtitle,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.clock, size: 14, color: AppColors.cardMutedText),
                    const SizedBox(width: 6),
                    Text(
                      dateFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cardMutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TypeUI _getTypeUI(String type) {
    switch (type) {
      case 'card_approved':
        return _TypeUI(PhosphorIconsRegular.checkCircle, AppColors.statusGreen);
      case 'card_rejected':
        return _TypeUI(PhosphorIconsRegular.xCircle, AppColors.errorRed);
      case 'doc_pending':
        return _TypeUI(PhosphorIconsRegular.warningCircle, AppColors.alertOrange);
      case 'general_notice':
        return _TypeUI(PhosphorIconsRegular.info, AppColors.primary);
      case 'new_partner':
        return _TypeUI(PhosphorIconsRegular.handshake, AppColors.cyan);
      default:
        return _TypeUI(PhosphorIconsRegular.bell, AppColors.primary);
    }
  }
}

class _TypeUI {
  final IconData icon;
  final Color color;

  _TypeUI(this.icon, this.color);
}
