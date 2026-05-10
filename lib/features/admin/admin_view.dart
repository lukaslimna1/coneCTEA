import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';

import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/widgets/loading_shimmer.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_request_card.dart';
import 'package:conectea/features/admin/widgets/admin_user_card.dart';
import 'package:conectea/features/admin/widgets/admin_request_details_sheet.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  bool _isLoadingUsers = true;

  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  String _userSearchQuery = '';
  
  // 0 = Ativas, 1 = Concluídas, 2 = Restritas
  int _requestFilterIndex = 0;

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
    await _loadAllUsers();
  }

  Future<void> _loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await _databaseService.getUserProfile(user.id);
      if (mounted) {
        final dbRole = profile?.role.dbValue ?? 'desconhecido';
        debugPrint('🛡️ ADMIN_VIEW: Usuário logado com ID: ${user.id}');
        debugPrint('🛡️ ADMIN_VIEW: Cargo lido do Banco: $dbRole');
        debugPrint('🛡️ ADMIN_VIEW: Permissão isAdmin: ${profile?.role.isAdmin}');
        
        setState(() => _currentUser = profile);
      }
    }
  }

  Future<void> _loadAllUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _databaseService.getAllProfiles();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allUsers = [];
          _isLoadingUsers = false;
        });
      }
    }
  }

  List<AppUser> get _filteredUsers {
    if (_userSearchQuery.isEmpty) return _allUsers;
    final query = _userSearchQuery.toLowerCase();
    return _allUsers.where((u) => 
      u.name.toLowerCase().contains(query) || 
      u.email.toLowerCase().contains(query)
    ).toList();
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
    return StreamBuilder<List<CardRequest>>(
      stream: _databaseService.getAllCardRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        // Filtrar nulos e garantir segurança de tipos
        final List<CardRequest> requests = (snapshot.data ?? []).whereType<CardRequest>().toList();
        
        if (requests.isEmpty) {
          return _buildEmptyState('Nenhuma solicitação encontrada', Icons.inbox_rounded);
        }

        // Sort: pendentes primeiro, depois por data
        final sortedRequests = List<CardRequest>.from(requests)
          ..sort((a, b) {
            final aStatus = a.status;
            final bStatus = b.status;
            if (aStatus == 'waiting_approval' && bStatus != 'waiting_approval') return -1;
            if (aStatus != 'waiting_approval' && bStatus == 'waiting_approval') return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

        final pendingCount = requests.where((r) => ['waiting_approval', 'reviewing_data', 'waiting_docs', 'renewing'].contains(r.status)).length;
        final approvedCount = requests.where((r) => ['active', 'approved'].contains(r.status)).length;
        final restrictedCount = requests.where((r) => ['rejected', 'suspended', 'expired'].contains(r.status)).length;

        // Filtrar a lista com base no _requestFilterIndex
        final filteredRequests = sortedRequests.where((r) {
          if (_requestFilterIndex == 0) {
            return ['waiting_approval', 'reviewing_data', 'waiting_docs', 'renewing'].contains(r.status);
          } else if (_requestFilterIndex == 1) {
            return ['active', 'approved'].contains(r.status);
          } else {
            return ['rejected', 'suspended', 'expired'].contains(r.status);
          }
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildStatsRow(pendingCount, approvedCount, restrictedCount),
            ),
            SliverToBoxAdapter(
              child: _buildRequestFilter(),
            ),
            if (filteredRequests.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: _buildEmptyState(
                    _requestFilterIndex == 0 ? 'Nenhuma solicitação ativa' :
                    _requestFilterIndex == 1 ? 'Nenhuma solicitação concluída' : 'Nenhuma solicitação restrita',
                    Icons.inbox_rounded,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final request = filteredRequests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdminRequestCard(
                        request: request,
                        onTap: () => _showRequestDetails(request),
                      ),
                    );
                  },
                  childCount: filteredRequests.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestFilter() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: PremiumCard(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildFilterButton(0, 'Ativas'),
                _buildFilterButton(1, 'Concluídas'),
                _buildFilterButton(2, 'Restritas'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(int index, String label) {
    final isSelected = _requestFilterIndex == index;
    final IconData icon;
    // Removida variável 'color' não utilizada
    
    switch (index) {
      case 0:
        icon = PhosphorIconsRegular.clock;
        break;
      case 1:
        icon = PhosphorIconsRegular.checkCircle;
        break;
      default:
        icon = PhosphorIconsRegular.shieldWarning;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _requestFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C3AED).withValues(alpha: 0.2) : Colors.transparent, 
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isSelected ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(int pending, int approved, int restricted) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Ativas', pending.toString(), AppColors.alertOrange, Icons.pending_actions_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Concluídas', approved.toString(), AppColors.statusGreen, Icons.check_circle_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Restritas', restricted.toString(), AppColors.adminDanger, Icons.block_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return PremiumCard(
      width: 140,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return _buildShimmerList();
    }

    if (_allUsers.isEmpty) {
      return _buildEmptyState('Nenhum usuário encontrado', Icons.people_rounded);
    }

    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      color: AppColors.primary,
      child: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return AdminUserCard(
                  user: user,
                  currentUserRole: _currentUser?.role,
                  onToggleRole: (newRole) => _changeUserRole(user, newRole),
                  onEditProfile: () => _showEditProfileDialog(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        onChanged: (value) => setState(() => _userSearchQuery = value),
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou e-mail...',
          hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C3AED)),
          filled: true,
          fillColor: const Color(0xA60F172A),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const LoadingShimmer(width: 50, height: 50, borderRadius: 25),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(width: MediaQuery.of(context).size.width * 0.5, height: 16),
                  const SizedBox(height: 8),
                  LoadingShimmer(width: MediaQuery.of(context).size.width * 0.3, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              Icon(
                PhosphorIconsRegular.tray, 
                size: 48, 
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arraste para baixo para atualizar',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(PhosphorIconsRegular.caretDoubleDown, color: Color(0xFF1B3D71), size: 24),
        ],
      ),
    );
  }

  void _showRequestDetails(CardRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminRequestDetailsSheet(
        request: request,
        databaseService: _databaseService,
        onStatusChanged: () {}, // Não é mais necessário pois o StreamBuilder atualiza automaticamente
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
                _loadAllUsers();
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
      _loadAllUsers();
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
