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
import 'package:conectea/features/admin/solicitacoes_carteirinha/admin_requests_tab.dart';
import 'package:conectea/features/admin/usuarios/admin_user_dialogs.dart';
import 'package:conectea/features/admin/usuarios/admin_users_tab.dart';
import 'package:conectea/features/admin/hub/admin_management_hub.dart';
import 'package:conectea/core/widgets/premium/conectea_role_badge.dart';
import 'package:conectea/features/admin/manutencao/admin_maintenance_sheet.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<AdminUsersTabState> _usersTabKey =
      GlobalKey<AdminUsersTabState>();

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
    final double topPadding =
        topSafeArea + headerVisualHeight + headerClearance;

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
    final double computedHeaderTopPadding = hasSelectedModule
        ? 12.0
        : topPadding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSelectedModule) _buildBackButton(topPadding),
            _buildHeader(
              computedHeaderTopPadding,
              title: moduleTitle,
              subtitle: moduleSubtitle,
            ),
            Expanded(child: _buildBody()),
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
                      const SizedBox(
                        height: 10,
                      ), // Respiro sutil abaixo do badge
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
          onShowMaintenance: () => AdminMaintenanceSheet.show(context),
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
}
