import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<AppUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(query) || 
             user.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Nota: No Supabase, listar todos os usuários da tabela 'profiles'
      // Se RLS estiver habilitado, o admin precisa de permissão para ler todos.
      final users = await _databaseService.getAllProfiles();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRole(AppUser user) async {
    final newRole = user.role == UserRole.admin ? UserRole.user : UserRole.admin;
    
    try {
      await _databaseService.updateUserProfileRole(user.id, newRole);
      
      // Atualizar lista local
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = AppUser(
            id: user.id,
            name: user.name,
            email: user.email,
            socialName: user.socialName,
            cpf: user.cpf,
            phone: user.phone,
            role: newRole,
            createdAt: user.createdAt,
            updatedAt: DateTime.now(),
            isActive: user.isActive,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role de ${user.name} atualizado para ${newRole.name}'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar role: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPremium,
      appBar: AppBar(
        title: Text(
          'Painel Administrativo',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar usuário...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final initials = user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
                        final isAdmin = user.role == UserRole.admin;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isAdmin ? AppColors.primary.withValues(alpha: 0.1) : AppColors.purpleLight,
                                child: Text(
                                  initials,
                                  style: GoogleFonts.inter(
                                    color: isAdmin ? AppColors.primary : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      user.email,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? AppColors.primary.withValues(alpha: 0.1) : AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isAdmin ? 'ADMIN' : 'USUÁRIO',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isAdmin ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _toggleRole(user),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      isAdmin ? 'Remover Admin' : 'Tornar Admin',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isAdmin ? AppColors.errorRed : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
