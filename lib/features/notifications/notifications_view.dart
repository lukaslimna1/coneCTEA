import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/notification_item.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';


class NotificationsView extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationsView({super.key, this.onBack});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  List<NotificationItem> _notifications = [];
  Stream<List<NotificationItem>>? _notificationsStream;
  final Set<String> _expandedNotifications = {};

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
                          const SizedBox(width: 16),
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
    final isExpanded = _expandedNotifications.contains(key);
    final isLongMessage = item.message.length > 90;

    return PremiumCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      hasGradient: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linha de acento lateral discreta e elegante
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: ui.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone com gradiente suave (Premium Glassmorphism)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ui.color.withValues(alpha: 0.25),
                            ui.color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ui.color.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(ui.icon, color: ui.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.cardTitle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!item.isRead)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cyan.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            maxLines: isLongMessage && !isExpanded ? 2 : null,
                            overflow: isLongMessage && !isExpanded ? TextOverflow.ellipsis : null,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.cardSubtitle,
                              height: 1.5,
                            ),
                          ),
                          if (isLongMessage) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedNotifications.remove(key);
                                  } else {
                                    _expandedNotifications.add(key);
                                  }
                                });
                              },
                              child: Text(
                                isExpanded ? 'Ver menos' : 'Ver mais',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(PhosphorIconsRegular.clock, size: 14, color: AppColors.cardMutedText),
                              const SizedBox(width: 6),
                              Text(
                                timeFormatted,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TypeUI _getTypeUI(NotificationItem item) {
    final type = item.type.toLowerCase();
    final title = item.title.toLowerCase();

    // 1. Suporte nativo a status_update com sufixo (novas notificações humanizadas vinculadas)
    if (type.startsWith('status_update:')) {
      final statusKey = type.substring('status_update:'.length).trim();
      final tokens = StatusVisualTokens.fromStatus(statusKey);
      return _TypeUI(tokens.icon, tokens.primary);
    }

    // 2. Tipos estruturados de reenvio/solicitação
    if (type == 'new_request') {
      final tokens = StatusVisualTokens.fromStatus('waiting_approval');
      return _TypeUI(PhosphorIconsRegular.filePlus, tokens.primary);
    }
    if (type == 'request_updated') {
      final tokens = StatusVisualTokens.fromStatus('under_review');
      return _TypeUI(PhosphorIconsRegular.arrowsClockwise, tokens.primary);
    }

    // 3. Fallback textual ultra seguro para status_update sem sufixo (notificações antigas)
    if (type == 'status_update') {
      // Prioridade máxima para termos negativos/reprovação (evita que "não aprovada" caia em "aprovada")
      if (title.contains('não aprovad') ||
          title.contains('reprovad') ||
          title.contains('rejeitad') ||
          title.contains('❌')) {
        final tokens = StatusVisualTokens.fromStatus('rejected');
        return _TypeUI(tokens.icon, tokens.primary);
      }

      if (title.contains('suspens') || title.contains('⚠️')) {
        final tokens = StatusVisualTokens.fromStatus('suspended');
        return _TypeUI(tokens.icon, tokens.primary);
      }

      if (title.contains('documento') ||
          title.contains('pendente') ||
          title.contains('📄')) {
        final tokens = StatusVisualTokens.fromStatus('waiting_docs');
        return _TypeUI(tokens.icon, tokens.primary);
      }

      if (title.contains('revisão') ||
          title.contains('corrigid') ||
          title.contains('✏️')) {
        final tokens = StatusVisualTokens.fromStatus('reviewing_data');
        return _TypeUI(tokens.icon, tokens.primary);
      }

      if (title.contains('vencid') || title.contains('📅')) {
        final tokens = StatusVisualTokens.fromStatus('expired');
        return _TypeUI(tokens.icon, tokens.primary);
      }

      if (title.contains('renov')) {
        final tokens = StatusVisualTokens.fromStatus('renewing');
        return _TypeUI(tokens.icon, tokens.primary);
      }

      // Verificado por último após descartar termos negativos
      if (title.contains('aprovad') ||
          title.contains('emitid') ||
          title.contains('🎉')) {
        final tokens = StatusVisualTokens.fromStatus('active');
        return _TypeUI(tokens.icon, tokens.primary);
      }
    }

    // 4. Mapeamento de retrocompatibilidade com tipos legados
    switch (type) {
      case 'card_approved':
        final tokens = StatusVisualTokens.fromStatus('active');
        return _TypeUI(tokens.icon, tokens.primary);
      case 'card_rejected':
        final tokens = StatusVisualTokens.fromStatus('rejected');
        return _TypeUI(tokens.icon, tokens.primary);
      case 'doc_pending':
        final tokens = StatusVisualTokens.fromStatus('waiting_docs');
        return _TypeUI(tokens.icon, tokens.primary);
      case 'general_notice':
        return _TypeUI(PhosphorIconsRegular.info, AppColors.primary);
      case 'new_partner':
        return _TypeUI(PhosphorIconsRegular.handshake, AppColors.cyan);
      default:
        return _TypeUI(PhosphorIconsRegular.bell, AppColors.primary);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  String _formatNotificationDay(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (compareDate == today) {
      return 'Hoje';
    } else if (compareDate == yesterday) {
      return 'Ontem';
    }

    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];

    return '${localDate.day} de ${months[localDate.month - 1]}';
  }

  String _formatNotificationTime(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
}

class _TypeUI {
  final IconData icon;
  final Color color;

  _TypeUI(this.icon, this.color);
}
