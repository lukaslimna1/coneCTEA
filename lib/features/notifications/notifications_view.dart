import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/notification_item.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';


class NotificationsView extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onUnreadStatusChanged;

  const NotificationsView({super.key, this.onBack, this.onUnreadStatusChanged});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  List<NotificationItem> _notifications = [];
  Stream<List<NotificationItem>>? _notificationsStream;
  final Set<String> _readNotificationsLocally = {};

  bool get _hasUnread {
    return _notifications.any((item) {
      final key = item.id.isNotEmpty ? item.id : '${item.createdAt.toIso8601String()}_${item.title}';
      return !item.isRead && !_readNotificationsLocally.contains(key);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      if (mounted) {
        setState(() {
          for (var item in _notifications) {
            if (!item.isRead) {
              final key = item.id.isNotEmpty ? item.id : '${item.createdAt.toIso8601String()}_${item.title}';
              _readNotificationsLocally.add(key);
            }
          }
        });
      }
      try {
        await _databaseService.markAllNotificationsAsRead(userId);
        if (mounted) {
          widget.onUnreadStatusChanged?.call();
        }
      } catch (e) {
        debugPrint('Erro ao marcar todas como lidas: $e');
      }
    }
  }

  Future<void> _clearNotifications() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      await _databaseService.clearAllNotifications(userId);
      if (mounted) {
        widget.onUnreadStatusChanged?.call();
      }
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
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding = topSafeArea + headerVisualHeight + headerClearance;

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
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.onBack != null) ...[
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xA60F172A), // Dark Glass base
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0x2E94A3B8), // Glass border
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  PhosphorIconsRegular.caretLeft,
                                  color: AppColors.cyan,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Voltar',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xE6FFFFFF), // Branco suave
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notificações',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cardTitle,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mantenha-se informado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.cardSubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_notifications.isNotEmpty) ...[
                          if (_hasUnread) ...[
                            _buildMarkAllReadButton(),
                            const SizedBox(width: 8),
                          ],
                          _buildClearButton(),
                        ],
                      ],
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
                        final item = notifications[index];
                        final showHeader = index == 0 || !_isSameDay(item.createdAt, notifications[index - 1].createdAt);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader) _buildDateHeader(item.createdAt),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildNotificationItem(item),
                            ),
                          ],
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

  Widget _buildMarkAllReadButton() {
    return GestureDetector(
      onTap: () {
        _markAllAsRead();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
        child: Center(
          child: Text(
            'Marcar lidas',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
            ),
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
    final timeFormatted = _formatNotificationTime(item.createdAt);
    final ui = _getTypeUI(item);
    final key = item.id.isNotEmpty ? item.id : '${item.createdAt.toIso8601String()}_${item.title}';
    final isRead = item.isRead || _readNotificationsLocally.contains(key);

    return DsCardNotificacao(
      titulo: item.title,
      mensagem: item.message,
      dataTexto: timeFormatted,
      icone: ui.icon,
      status: ui.status,
      visual: ui.visual,
      lida: isRead,
      onTap: () => _markSingleAsRead(item, key),
      expansivel: true,
      maxLinhasMensagem: 2,
    );
  }

  _TypeUI _getTypeUI(NotificationItem item) {
    final type = item.type.toLowerCase();
    final title = item.title.toLowerCase();

    // 1. Suporte nativo a status_update com sufixo (novas notificações humanizadas vinculadas)
    if (type.startsWith('status_update:')) {
      final statusKey = type.substring('status_update:'.length).trim();
      final statusToken = DsTokenStatus.fromStatus(statusKey);
      return _TypeUI(icon: statusToken.icon, status: statusToken);
    }

    // 2. Tipos estruturados de reenvio/solicitação
    if (type == 'new_request') {
      return _TypeUI(icon: PhosphorIconsRegular.filePlus, status: DsTokenStatus.waitingApproval);
    }
    if (type == 'request_updated') {
      return _TypeUI(icon: PhosphorIconsRegular.arrowsClockwise, status: DsTokenStatus.waitingApproval);
    }

    // 3. Fallback textual ultra seguro para status_update sem sufixo (notificações antigas)
    if (type == 'status_update') {
      if (title.contains('não aprovad') ||
          title.contains('reprovad') ||
          title.contains('rejeitad') ||
          title.contains('❌')) {
        return _TypeUI(icon: DsTokenStatus.rejected.icon, status: DsTokenStatus.rejected);
      }
      if (title.contains('suspens') || title.contains('⚠️')) {
        return _TypeUI(icon: DsTokenStatus.suspended.icon, status: DsTokenStatus.suspended);
      }
      if (title.contains('documento') ||
          title.contains('pendente') ||
          title.contains('📄')) {
        return _TypeUI(icon: DsTokenStatus.waitingDocs.icon, status: DsTokenStatus.waitingDocs);
      }
      if (title.contains('revisão') ||
          title.contains('corrigid') ||
          title.contains('✏️')) {
        return _TypeUI(icon: DsTokenStatus.reviewingData.icon, status: DsTokenStatus.reviewingData);
      }
      if (title.contains('vencid') || title.contains('📅')) {
        return _TypeUI(icon: DsTokenStatus.expired.icon, status: DsTokenStatus.expired);
      }
      if (title.contains('renov')) {
        return _TypeUI(icon: DsTokenStatus.renewing.icon, status: DsTokenStatus.renewing);
      }
      if (title.contains('aprovad') ||
          title.contains('emitid') ||
          title.contains('🎉')) {
        return _TypeUI(icon: DsTokenStatus.active.icon, status: DsTokenStatus.active);
      }
    }

    // 4. Mapeamento de retrocompatibilidade com tipos legados
    switch (type) {
      case 'card_approved':
        return _TypeUI(icon: DsTokenStatus.active.icon, status: DsTokenStatus.active);
      case 'card_rejected':
        return _TypeUI(icon: DsTokenStatus.rejected.icon, status: DsTokenStatus.rejected);
      case 'doc_pending':
        return _TypeUI(icon: DsTokenStatus.waitingDocs.icon, status: DsTokenStatus.waitingDocs);
      case 'general_notice':
        return _TypeUI(icon: PhosphorIconsRegular.info, visual: DsCores.comunicacao);
      case 'new_partner':
        return _TypeUI(icon: PhosphorIconsRegular.handshake, visual: DsCores.clube);
      default:
        return _TypeUI(icon: PhosphorIconsRegular.bell, visual: DsCores.institucional);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return ConecteaDateTimeHelper.isSameProjectDay(a, b);
  }

  // Frente 26H.1-FIX.1: Exibe a data absoluta no fuso do projeto, eliminando o risco de distorção de "Hoje/Ontem" do dispositivo local
  String _formatNotificationDay(DateTime date) {
    return ConecteaDateTimeHelper.formatProjectDateHeader(date);
  }

  String _formatNotificationTime(DateTime date) {
    return ConecteaDateTimeHelper.formatProjectTime(date);
  }

  Widget _buildDateHeader(DateTime date) {
    final dateStr = _formatNotificationDay(date);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.cardTitle.withValues(alpha: 0.85),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.25),
                    AppColors.cyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markSingleAsRead(NotificationItem item, String key) async {
    final isRead = item.isRead || _readNotificationsLocally.contains(key);
    if (!isRead) {
      setState(() {
        _readNotificationsLocally.add(key);
      });
      try {
        await _databaseService.markNotificationAsRead(item.id);
        if (mounted) {
          widget.onUnreadStatusChanged?.call();
        }
      } catch (e) {
        debugPrint('Erro ao marcar notificação como lida: $e');
      }
    }
  }
}

class _TypeUI {
  final IconData icon;
  final DsTokenStatus? status;
  final DsCorVisual? visual;

  _TypeUI({required this.icon, this.status, this.visual});
}
