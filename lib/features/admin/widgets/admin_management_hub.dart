import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_module_card.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';

class AdminManagementHub extends StatelessWidget {
  final AppUser? currentUser;
  final Function(String) onSelectModule;
  final VoidCallback onShowMaintenance;

  const AdminManagementHub({
    super.key,
    required this.currentUser,
    required this.onSelectModule,
    required this.onShowMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final role = currentUser?.role ?? UserRole.user;

    // Definição de permissões de entrada nos módulos reais
    final bool canAccessCards = role == UserRole.admin || role == UserRole.adminMaster || role == UserRole.adminDev;
    final bool canAccessUsers = role == UserRole.adminMaster || role == UserRole.adminDev;
    final bool canAccessMaintenance = role == UserRole.adminDev;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Módulo 1: Gestão de Carteirinhas
            AdminModuleCard(
              title: 'Gestão de Carteirinhas',
              description: 'Solicitações, revisões, documentos, renovações e status das carteirinhas.',
              icon: PhosphorIconsRegular.identificationCard,
              status: AdminModuleStatus.active,
              token: ConecteaVisualTokens.gestaoCarteirinhas,
              onTap: () {
                if (canAccessCards) {
                  onSelectModule('requests');
                } else {
                  _showToast(context, 'Acesso restrito à equipe de gestão.');
                }
              },
            ),

            // Módulo 2: Projetos, Programas e Eventos
            AdminModuleCard(
              title: 'Projetos, Programas e Eventos',
              description: 'Palestras, oficinas, ações sociais, inscrições e programas da Família TEA Bauru.',
              icon: PhosphorIconsRegular.calendar,
              status: AdminModuleStatus.comingSoon,
              token: ConecteaVisualTokens.emBreve,
              onTap: () => _showToast(context, 'Módulo em breve.'),
            ),

            // Módulo 3: Consultas com Profissionais
            AdminModuleCard(
              title: 'Consultas com Profissionais',
              description: 'Agendamentos iniciais com dentistas, médicos, advogados e outros profissionais parceiros.',
              icon: PhosphorIconsRegular.stethoscope,
              status: AdminModuleStatus.comingSoon,
              token: ConecteaVisualTokens.emBreve,
              onTap: () => _showToast(context, 'Módulo em breve.'),
            ),

            // Módulo 4: Usuários e Permissões
            AdminModuleCard(
              title: 'Usuários e Permissões',
              description: 'Contas, cargos e acessos administrativos.',
              icon: PhosphorIconsRegular.usersThree,
              status: canAccessUsers ? AdminModuleStatus.active : AdminModuleStatus.restricted,
              token: canAccessUsers 
                  ? ConecteaVisualTokens.usuariosPermissoes 
                  : ConecteaVisualTokens.restricao,
              onTap: () {
                if (canAccessUsers) {
                  onSelectModule('users');
                } else {
                  _showToast(context, 'Acesso restrito ao administrador master.');
                }
              },
            ),

            // Módulo 5: Manutenção Técnica
            AdminModuleCard(
              title: 'Manutenção Técnica',
              description: 'Ferramentas internas e rotinas restritas de desenvolvimento.',
              icon: PhosphorIconsRegular.wrench,
              status: canAccessMaintenance ? AdminModuleStatus.devOnly : AdminModuleStatus.restricted,
              token: canAccessMaintenance 
                  ? ConecteaVisualTokens.manutencaoTecnica 
                  : ConecteaVisualTokens.restricao,
              onTap: () {
                if (canAccessMaintenance) {
                  onShowMaintenance();
                } else {
                  _showToast(context, 'Acesso restrito ao administrador de desenvolvimento.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.cardBackground,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
    );
  }
}
