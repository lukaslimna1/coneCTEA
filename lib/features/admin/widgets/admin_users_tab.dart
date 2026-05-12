import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/loading_shimmer.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/admin/widgets/admin_user_card.dart';

class AdminUsersTab extends StatefulWidget {
  final DatabaseService databaseService;
  final UserRole? currentUserRole;
  final Function(AppUser, UserRole) onToggleRole;
  final Function(AppUser) onEditProfile;

  const AdminUsersTab({
    super.key,
    required this.databaseService,
    this.currentUserRole,
    required this.onToggleRole,
    required this.onEditProfile,
  });

  @override
  State<AdminUsersTab> createState() => AdminUsersTabState();
}

class AdminUsersTabState extends State<AdminUsersTab> {
  bool _isLoadingUsers = true;
  List<AppUser> _allUsers = [];
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  void refreshUsers() {
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await widget.databaseService.getAllProfiles();
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
                  currentUserRole: widget.currentUserRole,
                  onToggleRole: (newRole) => widget.onToggleRole(user, newRole),
                  onEditProfile: () => widget.onEditProfile(user),
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
}
