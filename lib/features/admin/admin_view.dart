import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_requests_tab.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            _buildHeader(),
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

  Widget _buildHeader() {
    final bool isDev = _currentUser?.role.canRunMaintenance ?? false;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                  GestureDetector(
                    onTap: () => context.push('/qr-scanner'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        PhosphorIconsBold.qrCode,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                  ),
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
      onToggleRole: _changeUserRole,
      onEditProfile: _showEditProfileDialog,
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

  void _showEditProfileDialog(AppUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final cpfController = TextEditingController(text: user.cpf);
    final cityController = TextEditingController(text: user.city ?? '');
    final stateController = TextEditingController(text: user.state ?? '');
    String? selectedGenero = user.gender;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar Cadastro: ${user.name}', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                TextField(
                  controller: cpfController,
                  decoration: const InputDecoration(labelText: 'CPF'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: [
                    'Feminino',
                    'Masculino',
                    'Não binário',
                    'Outro',
                    'Prefiro não informar',
                  ].contains(selectedGenero) ? selectedGenero : null,
                  decoration: const InputDecoration(labelText: 'Gênero'),
                  hint: const Text('Selecione o gênero'),
                  items: [
                    'Feminino',
                    'Masculino',
                    'Não binário',
                    'Outro',
                    'Prefiro não informar',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => selectedGenero = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'cpf': cpfController.text,
                  'city': cityController.text,
                  'state': stateController.text,
                  'gender': selectedGenero,
                };
                await _databaseService.updateAnyUserProfile(user.id, data);
              if (context.mounted) {
                Navigator.pop(context);
                _usersTabKey.currentState?.refreshUsers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _changeUserRole(AppUser user, UserRole newRole) async {
    if (user.role == newRole) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirmar Alteração',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente mudar o cargo de ${user.name} para ${newRole.name}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _databaseService.updateUserProfileRole(user.id, newRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Cargo atualizado com sucesso!'),
            ],
          ),
          backgroundColor: AppColors.statusGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _usersTabKey.currentState?.refreshUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar cargo: $e'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
