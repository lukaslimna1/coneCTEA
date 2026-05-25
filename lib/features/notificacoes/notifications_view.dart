import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  StreamSubscription<List<NotificationItem>>? _subscription;
  final Set<String> _readNotificationsLocally = {};
  bool _isLoading = true;

  bool get _hasUnread {
    return _notifications.any((item) {
      final key = item.id.isNotEmpty
          ? item.id
          : '${item.createdAt.toIso8601String()}_${item.title}';
      return !item.isRead && !_readNotificationsLocally.contains(key);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      if (mounted) {
        setState(() {
          for (var item in _notifications) {
            if (!item.isRead) {
              final key = item.id.isNotEmpty
                  ? item.id
                  : '${item.createdAt.toIso8601String()}_${item.title}';
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
      _subscription?.cancel();

      final stream = _databaseService.notificationsStream(userId);
      _subscription = stream.listen((data) {
        if (mounted) {
          setState(() {
            _notifications = data;
            _isLoading = false;
          });
        }
      });

      try {
        await stream.first.timeout(const Duration(seconds: 3));
      } catch (_) {}
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding =
        topSafeArea + headerVisualHeight + headerClearance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          color: DsCores.conta.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.onBack != null) ...[
                      DsBotaoVoltar(onPressed: widget.onBack),
                      const SizedBox(height: DsEspacamentos.md),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notificações',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DsTipografia.pageTitle,
                              ),
                              const SizedBox(height: DsEspacamentos.xs),
                              Text(
                                'Mantenha-se informado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DsTipografia.pageSubtitle,
                              ),
                            ],
                          ),
                        ),
                        if (_notifications.isNotEmpty) ...[
                          const SizedBox(width: DsEspacamentos.sm),
                          _buildClearButton(),
                        ],
                      ],
                    ),
                    if (_notifications.isNotEmpty && _hasUnread) ...[
                      const SizedBox(height: DsEspacamentos.md),
                      _buildMarkAllReadButton(),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _isLoading && _notifications.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: DsCores.conta.accent,
                        ),
                      )
                    : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final showHeader =
                              index == 0 ||
                              !_isSameDay(
                                item.createdAt,
                                _notifications[index - 1].createdAt,
                              );

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
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAllReadButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _markAllAsRead,
        borderRadius: BorderRadius.circular(DsRaios.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            border: Border.all(
              color: DsCores.comunicacao.border.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(DsRaios.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                PhosphorIconsRegular.checkCircle,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                'Marcar lidas',
                style: DsTipografia.label.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: _showClearDialog,
      child: DsMolduraIcone(
        icon: PhosphorIconsRegular.trash,
        accentColor: DsCores.perigo.accent,
        size: 42,
        iconSize: 20,
        radius: 14,
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DsCores.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRaios.modal),
        ),
        title: Text('Limpar notificações?', style: DsTipografia.sectionTitle),
        content: Text(
          'Isso removerá permanentemente todas as suas notificações.',
          style: DsTipografia.infoBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: DsTipografia.button.copyWith(color: DsCores.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);
              try {
                await _clearNotifications();
                if (mounted) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: const Text('Notificações removidas!'),
                      backgroundColor: DsCores.sucesso.accent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffold.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Não foi possível limpar as notificações agora. Tente novamente.',
                      ),
                      backgroundColor: DsCores.perigo.accent,
                    ),
                  );
                }
              }
              navigator.pop();
            },
            child: Text(
              'LIMPAR TUDO',
              style: DsTipografia.button.copyWith(color: DsCores.perigo.accent),
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
          Container(
            padding: const EdgeInsets.all(DsEspacamentos.xl),
            decoration: const BoxDecoration(
              color: DsCores.iconFrameBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.bellSlash,
              size: DsTamanhos.iconLg,
              color: DsCores.iconMuted,
            ),
          ),
          const SizedBox(height: DsEspacamentos.lg),
          Text('Tudo limpo por aqui!', style: DsTipografia.sectionTitle),
          const SizedBox(height: DsEspacamentos.xs),
          Text(
            'Você não tem novas notificações no momento.',
            textAlign: TextAlign.center,
            style: DsTipografia.infoBody,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem item) {
    final timeFormatted = _formatNotificationTime(item.createdAt);
    final ui = _getTypeUI(item);
    final key = item.id.isNotEmpty
        ? item.id
        : '${item.createdAt.toIso8601String()}_${item.title}';
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
      return _TypeUI(
        icon: PhosphorIconsRegular.filePlus,
        status: DsTokenStatus.waitingApproval,
      );
    }
    if (type == 'request_updated') {
      return _TypeUI(
        icon: PhosphorIconsRegular.arrowsClockwise,
        status: DsTokenStatus.waitingApproval,
      );
    }

    // 3. Fallback textual ultra seguro para status_update sem sufixo (notificações antigas)
    if (type == 'status_update') {
      if (title.contains('não aprovad') ||
          title.contains('reprovad') ||
          title.contains('rejeitad') ||
          title.contains('❌')) {
        return _TypeUI(
          icon: DsTokenStatus.rejected.icon,
          status: DsTokenStatus.rejected,
        );
      }
      if (title.contains('suspens') || title.contains('⚠️')) {
        return _TypeUI(
          icon: DsTokenStatus.suspended.icon,
          status: DsTokenStatus.suspended,
        );
      }
      if (title.contains('documento') ||
          title.contains('pendente') ||
          title.contains('📄')) {
        return _TypeUI(
          icon: DsTokenStatus.waitingDocs.icon,
          status: DsTokenStatus.waitingDocs,
        );
      }
      if (title.contains('revisão') ||
          title.contains('corrigid') ||
          title.contains('✏️')) {
        return _TypeUI(
          icon: DsTokenStatus.reviewingData.icon,
          status: DsTokenStatus.reviewingData,
        );
      }
      if (title.contains('vencid') || title.contains('📅')) {
        return _TypeUI(
          icon: DsTokenStatus.expired.icon,
          status: DsTokenStatus.expired,
        );
      }
      if (title.contains('renov')) {
        return _TypeUI(
          icon: DsTokenStatus.renewing.icon,
          status: DsTokenStatus.renewing,
        );
      }
      if (title.contains('aprovad') ||
          title.contains('emitid') ||
          title.contains('🎉')) {
        return _TypeUI(
          icon: DsTokenStatus.active.icon,
          status: DsTokenStatus.active,
        );
      }
    }

    // 4. Mapeamento de retrocompatibilidade com tipos legados
    switch (type) {
      case 'card_approved':
        return _TypeUI(
          icon: DsTokenStatus.active.icon,
          status: DsTokenStatus.active,
        );
      case 'card_rejected':
        return _TypeUI(
          icon: DsTokenStatus.rejected.icon,
          status: DsTokenStatus.rejected,
        );
      case 'doc_pending':
        return _TypeUI(
          icon: DsTokenStatus.waitingDocs.icon,
          status: DsTokenStatus.waitingDocs,
        );
      case 'general_notice':
        return _TypeUI(
          icon: PhosphorIconsRegular.info,
          visual: DsCores.comunicacao,
        );
      case 'new_partner':
        return _TypeUI(
          icon: PhosphorIconsRegular.handshake,
          visual: DsCores.clube,
        );
      default:
        return _TypeUI(
          icon: PhosphorIconsRegular.bell,
          visual: DsCores.institucional,
        );
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
            style: DsTipografia.label.copyWith(
              color: DsCores.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: DsEspacamentos.sm),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DsCores.border,
                    DsCores.border.withValues(alpha: 0.0),
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
