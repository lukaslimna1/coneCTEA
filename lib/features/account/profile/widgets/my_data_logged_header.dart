import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class MyDataLoggedHeader extends StatelessWidget {
  const MyDataLoggedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
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
                _buildNotificationButton(context),
                const SizedBox(width: 12),
                // Avatar Circular
                _buildAvatar(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Área em construção.')),
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xA60F172A), // Dark Glass base
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0x2E94A3B8), // Glass border
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
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Área em construção.')),
        );
      },
      child: const DsAvatar(
        initials: 'US', // Placeholder visual seguro
        size: 38,
        showGlow: true,
      ),
    );
  }
}
