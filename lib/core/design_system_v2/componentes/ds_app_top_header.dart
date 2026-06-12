import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **DsAppTopHeader** — Cabeçalho Superior Oficial da Design System V2 (DS V2).
///
/// Exibe a nova logo com nome (clicável), o contador de notificações e o [DsAvatar]
/// sob a estética premium Night Blue / Dark Glass.
class DsAppTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String? userInitials;
  final String? userPhotoUrl;
  final int notificationCount;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLogoTap;
  final String? paletteSeed;

  const DsAppTopHeader({
    super.key,
    this.userName,
    this.userInitials,
    this.userPhotoUrl,
    this.notificationCount = 0,
    this.hasUnreadNotifications = false,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onLogoTap,
    this.paletteSeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF061226), Color(0xFF071A33), Color(0xFF081F3D)],
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0x1A60A5FA), // rgba(96,165,250,0.10)
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Logo ConeCTEA Clicável (Aproveitamento total, sem estourar em 360dp)
              _DsScaleFeedback(
                onTap: onLogoTap,
                child: Image.asset(
                  'assets/images/conectea_logo_name.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),

              // 2. Lado Direito: Ações
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão de Notificações com Badge
                  _buildNotificationButton(),

                  const SizedBox(width: 12),

                  // Avatar Circular da DS V2
                  _buildAvatar(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _DsScaleFeedback(
          onTap: onNotificationTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xA60F172A), // Dark Glass base
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0x2E94A3B8), // Glass border sutil
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                PhosphorIcons.bell(PhosphorIconsStyle.regular),
                color: const Color(0xFFF8FAFC),
                size: 20,
              ),
            ),
          ),
        ),
        if (hasUnreadNotifications)
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF43F5E),
                      Color(0xFFE11D48),
                    ], // Ruby / Rose Premium
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF020617),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (notificationCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF43F5E),
                      Color(0xFFE11D48),
                    ], // Ruby / Rose Premium
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF020617),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    notificationCount > 99
                        ? '99+'
                        : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    final resolvedInitials =
        (userInitials != null && userInitials!.trim().isNotEmpty)
        ? userInitials!.trim()
        : _getInitials(userName);

    return _DsScaleFeedback(
      onTap: onAvatarTap,
      child: DsAvatar(
        initials: resolvedInitials,
        size: 38,
        imageUrl: userPhotoUrl,
        paletteSeed: paletteSeed,
        showGlow: true,
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty || name == 'Usuário') return '--';
    final trimmedName = name.trim();
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}

/// Widget utilitário interno para fornecer feedback visual de escala ao tocar.
class _DsScaleFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DsScaleFeedback({required this.child, this.onTap});

  @override
  State<_DsScaleFeedback> createState() => _DsScaleFeedbackState();
}

class _DsScaleFeedbackState extends State<_DsScaleFeedback> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
