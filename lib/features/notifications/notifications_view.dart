import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/notification_item.dart';
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
  bool _isLoading = true;

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
    setState(() => _isLoading = true);
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      _notificationsStream = _databaseService.notificationsStream(userId);
      final notifications = await _databaseService.getNotifications(userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Limpar notificações?'),
                          content: const Text('Iso removerá permanentemente todas as suas notificações.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                            TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final scaffold = ScaffoldMessenger.of(context);
                      
                      try {
                        await _clearNotifications();
                        if (mounted) {
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text('Notificações removidas com sucesso!'),
                              backgroundColor: AppColors.statusGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text('Erro ao limpar notificações: $e'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      }
                      navigator.pop();
                    },
                              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                              child: const Text('Limpar Tudo'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 20),
                    label: const Text('Limpar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
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
                
                // Update local list to show/hide clear button correctly
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Tudo limpo por aqui!',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você não tem novas notificações no momento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    final dateFormatted = DateFormat('dd/MM HH:mm').format(item.createdAt);
    final ui = _getTypeUI(item.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: !item.isRead ? Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ui.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(ui.icon, color: ui.color, size: 22),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
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
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dateFormatted,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
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
        return _TypeUI(Icons.verified_rounded, AppColors.statusGreen);
      case 'card_rejected':
        return _TypeUI(Icons.error_rounded, AppColors.errorRed);
      case 'doc_pending':
        return _TypeUI(Icons.warning_rounded, AppColors.alertOrange);
      case 'general_notice':
        return _TypeUI(Icons.info_rounded, AppColors.primary);
      case 'new_partner':
        return _TypeUI(Icons.handshake_rounded, AppColors.cyan);
      default:
        return _TypeUI(Icons.notifications_rounded, AppColors.primary);
    }
  }
}

class _TypeUI {
  final IconData icon;
  final Color color;

  _TypeUI(this.icon, this.color);
}

