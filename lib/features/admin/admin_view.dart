import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_qr_button.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_requests_tab.dart';
import 'package:conectea/features/admin/widgets/admin_user_dialogs.dart';
import 'package:conectea/features/admin/widgets/admin_users_tab.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  final GlobalKey<AdminUsersTabState> _usersTabKey = GlobalKey<AdminUsersTabState>();

  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await _databaseService.getUserProfile(user.id);
      if (mounted) {
        // Logs de auditoria interna removidos por segurança na Fase 18B
        
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(topPadding),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsTab(),
                  _buildUsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    final bool isDev = _currentUser?.role.canRunMaintenance ?? false;

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
                          'Painel de Gestão',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerenciamento institucional ConeCTEA',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDev)
                    IconButton(
                      onPressed: _showMaintenanceSheet,
                      icon: Container(
                        padding: const EdgeInsets.all(12),
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
                        child: const Icon(PhosphorIconsRegular.wrench, color: Color(0xFF7C3AED)), // Soft Purple
                      ),
                      tooltip: 'Rodar Manutenções',
                    ),
                  const SizedBox(width: 8),
                  const PremiumQrButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: PremiumCard(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary.withValues(alpha: 0.5),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.clipboardText, size: 20),
                    SizedBox(width: 8),
                    Text('Solicitações'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.user, size: 20),
                    SizedBox(width: 8),
                    Text('Usuários'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                // Lógica de exemplo por enquanto
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
