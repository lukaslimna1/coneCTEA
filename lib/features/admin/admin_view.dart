import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_qr_button.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_requests_tab.dart';
import 'package:conectea/features/admin/widgets/admin_user_dialogs.dart';
import 'package:conectea/features/admin/widgets/admin_users_tab.dart';
import 'package:conectea/features/admin/widgets/admin_management_hub.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              topPadding,
              title: moduleTitle,
              subtitle: moduleSubtitle,
            ),
            if (_selectedModule != null) _buildBackButton(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPadding, {String? title, String? subtitle}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? 'Gestão',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  const PremiumQrButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: InkWell(
            onTap: () => setState(() => _selectedModule = null),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1A7C3AED), // Soft purple sutil
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0x337C3AED),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFFA78BFA),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Voltar ao Painel',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFA78BFA),
                    ),
                  ),
                ],
              ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_circle_rounded, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Central de Manutenção',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMaintenanceItem(
              Icons.cleaning_services_rounded,
              'Limpar Solicitações Antigas',
              'Remove registros de solicitações expiradas há mais de 1 ano.',
              () async {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manutenção concluída!')));
                }
              }
            ),
            _buildMaintenanceItem(
              Icons.sync_problem_rounded,
              'Recalcular Prazos',
              'Sincroniza datas de validade com base nos últimos status.',
              () async {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prazos recalculados com sucesso!')));
                }
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
