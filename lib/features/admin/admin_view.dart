import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_qr_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_requests_tab.dart';
import 'package:conectea/features/admin/widgets/admin_user_dialogs.dart';
import 'package:conectea/features/admin/widgets/admin_users_tab.dart';
import 'package:conectea/features/admin/widgets/admin_management_hub.dart';
import 'package:conectea/core/widgets/premium/conectea_role_badge.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<AdminUsersTabState> _usersTabKey = GlobalKey<AdminUsersTabState>();

  AppUser? _currentUser;
  String? _selectedModule; // null ou 'hub', 'requests', 'users'

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await _databaseService.getUserProfile(user.id);
      if (mounted) {
        setState(() => _currentUser = profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding = topSafeArea + headerVisualHeight + headerClearance;

    final String? moduleTitle = _selectedModule == 'requests'
        ? 'Gestão de Carteirinhas'
        : _selectedModule == 'users'
            ? 'Usuários e Permissões'
            : null;

    final String? moduleSubtitle = _selectedModule == 'requests'
        ? 'Solicitações, revisões e status das carteirinhas.'
        : _selectedModule == 'users'
            ? 'Contas, cargos e acessos administrativos.'
            : null;

    final bool hasSelectedModule = _selectedModule != null;
    final double computedHeaderTopPadding = hasSelectedModule ? 12.0 : topPadding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSelectedModule)
              _buildBackButton(topPadding),
            _buildHeader(
              computedHeaderTopPadding,
              title: moduleTitle,
              subtitle: moduleSubtitle,
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPadding, {String? title, String? subtitle}) {
    final bool showRoleBadge = _selectedModule == null && _currentUser != null;
    final bool showQrButton = _selectedModule != 'requests';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showRoleBadge) ...[
                      ConecteaRoleBadge.expanded(role: _currentUser!.role),
                      const SizedBox(height: 10), // Respiro sutil abaixo do badge
                    ],
                    Text(
                      title ?? 'Gestão',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle ?? 'Escolha uma área administrativa.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (showQrButton) ...[
                const SizedBox(width: 16),
                Padding(
                  padding: EdgeInsets.only(top: showRoleBadge ? 22.0 : 0.0),
                  child: const PremiumQrButton(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(double topPadding) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() => _selectedModule = null),
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
                  'Voltar ao Painel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xE6FFFFFF), // Branco suave
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedModule) {
      case 'requests':
        return _buildRequestsTab();
      case 'users':
        return _buildUsersTab();
      default:
        return AdminManagementHub(
          currentUser: _currentUser,
          onSelectModule: (module) {
            setState(() => _selectedModule = module);
          },
          onShowMaintenance: _showMaintenanceSheet,
        );
    }
  }

  Widget _buildRequestsTab() {
    return AdminRequestsTab(databaseService: _databaseService);
  }

  Widget _buildUsersTab() {
    return AdminUsersTab(
      key: _usersTabKey,
      databaseService: _databaseService,
      currentUserRole: _currentUser?.role,
      onToggleRole: (user, role) => AdminUserDialogs.changeUserRole(
        context: context,
        user: user,
        newRole: role,
        databaseService: _databaseService,
        onUpdateSuccess: () => _usersTabKey.currentState?.refreshUsers(),
      ),
      onEditProfile: (user) => AdminUserDialogs.showEditProfileDialog(
        context: context,
        user: user,
        databaseService: _databaseService,
        onUpdateSuccess: () => _usersTabKey.currentState?.refreshUsers(),
      ),
    );
  }

  void _showMaintenanceSheet() {
    final token = ConecteaVisualTokens.manutencaoTecnica;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFB0B132B), // Fundo premium Night Blue profundo
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(
                top: BorderSide(
                  color: token.accent.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alça de arraste visual premium
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Cabeçalho da Central
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: token.softBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: token.border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.wrench,
                          color: token.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Manutenção',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: token.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: token.accent.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'ADMIN DEV',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: token.accent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Área técnica restrita para recursos internos do app.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Aviso discreto de área técnica
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.warning,
                          color: Colors.amber.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recursos desta área devem ser usados apenas para diagnóstico e controle técnico.',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Módulo 1: Controle de Recursos
                  _buildMaintenanceCard(
                    icon: PhosphorIconsRegular.sliders,
                    title: 'Controle de Recursos',
                    description: 'Ativar ou desativar temporariamente módulos e ações com problema.',
                    statusLabel: 'Planejado',
                    isFuture: false,
                  ),

                  // Módulo 2: Diagnóstico do Sistema
                  _buildMaintenanceCard(
                    icon: PhosphorIconsRegular.pulse,
                    title: 'Diagnóstico do Sistema',
                    description: 'Verificar integrações, serviços e rotinas técnicas do app.',
                    statusLabel: 'Planejado',
                    isFuture: false,
                  ),

                  // Módulo 3: Rotinas Automáticas
                  _buildMaintenanceCard(
                    icon: PhosphorIconsRegular.arrowsClockwise,
                    title: 'Rotinas Automáticas',
                    description: 'Acompanhar limpezas e validações executadas pelo sistema.',
                    statusLabel: 'Planejado',
                    isFuture: false,
                  ),

                  // Módulo 4: Auditoria Técnica
                  _buildMaintenanceCard(
                    icon: PhosphorIconsRegular.fileText,
                    title: 'Auditoria Técnica',
                    description: 'Consultar registros de ações administrativas sensíveis.',
                    statusLabel: 'Futuro',
                    isFuture: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard({
    required IconData icon,
    required String title,
    required String description,
    required String statusLabel,
    required bool isFuture,
  }) {
    final token = ConecteaVisualTokens.manutencaoTecnica;
    final statusColor = isFuture ? const Color(0xFF94A3B8) : token.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xD90F172A), // Dark glass premium
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFuture
              ? Colors.white.withValues(alpha: 0.05)
              : token.accent.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFuture
                ? Colors.black.withValues(alpha: 0.2)
                : token.accent.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFuture
                  ? Colors.white.withValues(alpha: 0.03)
                  : token.softBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFuture
                    ? Colors.white.withValues(alpha: 0.06)
                    : token.border,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isFuture ? const Color(0xFF94A3B8) : token.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
