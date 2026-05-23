import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **DsSeloCargo** — Padrão oficial da Design System V2 (DS V2).
///
/// Componente unificado para exibir as permissões e níveis de acesso (cargo/role)
/// de usuários de forma padronizada.
///
/// Substitui o ConecteaRoleBadge legado e suporta dois modos:
/// - **compacto** (apenas o ícone do cargo dentro de uma moldura circular Dark Glass premium).
/// - **completo** (selo horizontal com ícone + rótulo textual de cargo).
class DsSeloCargo extends StatelessWidget {
  final UserRole role;
  
  /// Se `true`, exibe apenas a moldura compacta com o ícone, sem texto.
  /// Padrão utilizado na Home para discrição.
  final bool compacto;

  const DsSeloCargo({
    super.key,
    required this.role,
    this.compacto = false,
  });

  /// Construtor auxiliar para visual compacto apenas com ícone (Home).
  const DsSeloCargo.compacto({
    super.key,
    required this.role,
  }) : compacto = true;

  /// Construtor auxiliar para visual completo com ícone + texto (Gestão/Admin).
  const DsSeloCargo.completo({
    super.key,
    required this.role,
  }) : compacto = false;

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.user) {
      return const SizedBox.shrink();
    }

    final DsCorVisual token;
    final IconData icon;
    final String label;

    // Lógica de mapeamento semântico cromático e ícones
    switch (role) {
      case UserRole.adminDev:
        token = DsCores.admin;
        icon = PhosphorIcons.codeSimple(PhosphorIconsStyle.bold);
        label = 'Dev';
        break;
      case UserRole.adminMaster:
        token = DsCores.restricao;
        icon = PhosphorIcons.crown(PhosphorIconsStyle.bold);
        label = 'Master';
        break;
      case UserRole.admin:
      default:
        token = DsCores.sucesso;
        icon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.bold);
        label = 'ADM';
        break;
    }

    if (compacto) {
      // Visual Dark Glass minimalista apenas com o ícone centralizado (Estética Home)
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xD90F172A), // Dark glass mais fechado e premium
          shape: BoxShape.circle,
          border: Border.all(
            color: token.border.withValues(alpha: 0.25), // Borda temática sutil
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: token.accent.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: token.accent.withValues(alpha: 0.9),
          size: 18,
          shadows: [
            Shadow(
              color: token.accent.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
      );
    }

    // Visual Completo usando o DsSelo da DS V2 (Estética Gestão/Admin)
    return DsSelo.fromCorVisual(
      label: label,
      token: token,
      icon: icon,
      compact: true,
    );
  }
}
