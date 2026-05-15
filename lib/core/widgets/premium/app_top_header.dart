import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'conectea_avatar.dart';

/// Cabeçalho superior padronizado do aplicativo.
/// Exibe a logo, contador de notificações e avatar do usuário com suporte a badges de administrador.
class AppTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String? userPhotoUrl;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final String? paletteSeed;

  const AppTopHeader({
    super.key,
    this.userName,
    this.userPhotoUrl,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
    this.paletteSeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF061226),
            Color(0xFF071A33),
            Color(0xFF081F3D),
          ],
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
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo ConeCTEA
              Image.asset(
                'assets/images/conectea_logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              
              // Lado Direito: Ações
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão de Notificações
                  _buildNotificationButton(),
                  
                  const SizedBox(width: 12),

                  // Avatar Circular
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
        ScaleFeedback(
          onTap: onNotificationTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xA60F172A), // rgba(15,23,42,0.65)
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0x2E94A3B8), // rgba(148,163,184,0.18)
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
        if (notificationCount > 0)
          Positioned(
            top: -3,
            right: -3,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF071A33), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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
    return ScaleFeedback(
      onTap: onAvatarTap,
      child: ConecteaAvatar(
        initials: _getInitials(userName),
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

/// Widget utilitário para fornecer feedback visual de escala ao tocar.
class ScaleFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const ScaleFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.98,
  });

  @override
  State<ScaleFeedback> createState() => _ScaleFeedbackState();
}

class _ScaleFeedbackState extends State<ScaleFeedback> {
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
        scale: _isPressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
