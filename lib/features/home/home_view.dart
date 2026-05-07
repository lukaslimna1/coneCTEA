import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';

class HomeView extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeView({super.key, required this.onNavigate});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  AppUser? _user;
  List<Member> _members = [];
  CardRequest? _ongoingRequest;
  bool _isLoading = true;
  int _selectedMemberIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        var user = await _databaseService.getUserProfile(userId);
        
        // Removida lógica de auto-healing para permitir registro limpo
        if (user == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final members = await _databaseService.getMembers(userId);
        final requests = await _databaseService.getCardRequests(userId);
        
        // Encontrar a solicitação mais relevante (pendente ou em análise)
        CardRequest? ongoing;
        if (requests.isNotEmpty) {
          try {
            ongoing = requests.firstWhere(
              (r) => r.status.toLowerCase() == 'under_review' || 
                     r.status.toLowerCase() == 'pending' ||
                     r.status.toLowerCase() == 'em análise' ||
                     r.status.toLowerCase() == 'pendente'
            );
          } catch (_) {
            // Se não houver pendente, pega a última criada
            ongoing = requests.first;
          }
        }
        
        if (mounted) {
          setState(() {
            _user = user;
            _members = members;
            _ongoingRequest = ongoing;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _displayName {
    if (_user == null) return 'Usuário';
    final name = _user!.socialName ?? _user!.name;
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF1F5F9), // Slate 100
            const Color(0xFFCBD5E1), // Slate 300 - Darkened further for maximum card pop
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 32),
              _buildMembersSection(),
              const SizedBox(height: 36),
              _buildCarteirinhaSection(),
              const SizedBox(height: 36),
              _buildQuickAccessGrid(),
              const SizedBox(height: 36),
              _buildOngoingRequest(),
              const SizedBox(height: 36),
              _buildOtherServices(),
              const SizedBox(height: 40),
              _buildInstitutionalBanner(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final isAdmin = _user?.role == UserRole.admin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Olá, $_displayName!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      _buildAdminBadge(),
                    ],
                  ],
                ),
                Text(
                  'Que bom te ver por aqui.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return GestureDetector(
      onTap: () => context.push('/admin-dashboard'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 14),
            const SizedBox(width: 6),
            Text(
              'ADMIN',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_members.length} membros vinculados',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Selecione um membro para visualizar.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/member-selection'),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(_members.length, (index) {
              final isSelected = index == _selectedMemberIndex;
              final member = _members[index];
              final initials = member.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

              return GestureDetector(
                onTap: () => setState(() => _selectedMemberIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderLight.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.shadowColor.withValues(alpha: 0.08),
                        blurRadius: isSelected ? 20 : 12,
                        offset: Offset(0, isSelected ? 8 : 4),
                      ),
                      if (!isSelected)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 1,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.purpleLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name.split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: member.status.toLowerCase() == 'ativa' || member.status.toLowerCase() == 'active' 
                                      ? AppColors.statusGreen 
                                      : AppColors.alertOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                member.status,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: member.status.toLowerCase() == 'ativa' || member.status.toLowerCase() == 'active' 
                                      ? AppColors.statusGreen 
                                      : AppColors.alertOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCarteirinhaSection() {
    if (_members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.badge_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Você ainda não possui uma carteirinha.',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre um membro para solicitar a carteirinha de identificação.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/member-selection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Solicitar Carteirinha',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    final member = _members[_selectedMemberIndex];
    final String status = member.status.isNotEmpty ? member.status : 'PENDENTE';
    final bool isActive = status.toLowerCase() == 'ativa' || status.toLowerCase() == 'active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 1.0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              // Stacked Cards Preview
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 120,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Back Card
                      Positioned(
                        right: 0,
                        top: 15,
                        child: Transform.rotate(
                          angle: 0.1,
                          child: _buildMiniCard(isVerso: true, member: member),
                        ),
                      ),
                      // Front Card
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform.rotate(
                          angle: -0.05,
                          child: _buildMiniCard(isVerso: false, member: member),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Status Card
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.verified_user_rounded : Icons.pending_actions_rounded, 
                        color: isActive ? AppColors.statusGreen : AppColors.alertOrange, 
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Carteirinha',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isActive ? AppColors.statusGreen : AppColors.alertOrange,
                        ),
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      Text(
                        'Vencimento',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                      Text(
                        isActive ? '12/04/2026' : '--/--/----',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActive ? () => widget.onNavigate(1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppColors.primary : AppColors.borderLight,
                foregroundColor: isActive ? Colors.white : AppColors.textSecondary,
                elevation: isActive ? 4 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isActive ? Icons.qr_code_scanner_rounded : Icons.lock_outline_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isActive ? 'Abrir Carteira Digital' : 'Indisponível',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMiniCard({required bool isVerso, Member? member}) {
    final String name = member?.name ?? (_user?.socialName ?? _user?.name ?? 'Membro');
    final String cpf = member?.cpf ?? '***.***.***-**';
    
    return Container(
      width: 150,
      height: 95,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerso 
              ? [AppColors.darkBlue, AppColors.darkBlue.withValues(alpha: 0.85)] 
              : [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              Icons.all_inclusive_rounded, 
              color: Colors.white.withValues(alpha: 0.08), 
              size: 70
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'ConeCTEA',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const Spacer(),
                if (!isVerso) ...[
                  Text(
                    name.split(' ').first.toUpperCase(),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'CPF: $cpf',
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 7, fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Acesso rápido',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Deslize',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swipe_left_rounded, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 230, // Aumentado para acomodar cards maiores e evitar cortes no Pixel 4 e outros dispositivos
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            clipBehavior: Clip.none,
            children: [
              _buildQuickCard(
                icon: Icons.badge_outlined,
                title: 'Ver carteirinha',
                subtitle: 'Acesse sua carteirinha digital',
                color: AppColors.primary,
                onTap: () {
                  if (_members.isNotEmpty && 
                      (_members[_selectedMemberIndex].status.toLowerCase() == 'ativa' || 
                       _members[_selectedMemberIndex].status.toLowerCase() == 'active')) {
                    widget.onNavigate(1);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _members.isEmpty 
                              ? 'Você ainda não possui uma carteirinha.' 
                              : 'Sua carteirinha ainda não está ativa.',
                        ),
                        backgroundColor: AppColors.alertOrange,
                      ),
                    );
                  }
                },
              ),
              _buildQuickCard(
                icon: Icons.add_card_outlined,
                title: 'Solicitar',
                subtitle: 'Nova via ou atualização',
                color: AppColors.teal,
                onTap: () => context.push('/member-selection'),
              ),
              _buildQuickCard(
                icon: Icons.assignment_outlined,
                title: 'Meu mural',
                subtitle: 'Status das solicitações',
                color: AppColors.alertOrange,
                onTap: () => widget.onNavigate(2),
              ),
              _buildQuickCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notificações',
                subtitle: 'Avisos e atualizações',
                color: AppColors.cardBlue,
                onTap: () => widget.onNavigate(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        width: 165, // Aumentado para melhor legibilidade e presença visual
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 1.0), // Mais visível
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            splashColor: color.withValues(alpha: 0.1),
            highlightColor: color.withValues(alpha: 0.05),
            child: Stack(
              children: [
                // Ícone de fundo decorativo refinado
                Positioned(
                  right: -15,
                  top: -15,
                  child: Icon(
                    icon,
                    color: color.withValues(alpha: 0.03),
                    size: 100,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14), // Reduzido ligeiramente
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 30), // Reduzido ligeiramente
                      ),
                      const SizedBox(height: 16), // Reduzido de 20 para 16
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // Reduzido de 8 para 6
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12), // Reduzido de 16 para 12
                      // Indicador visual de clique (Botão estilizado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Mais compacto
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ACESSAR',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: color,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildOngoingRequest() {
    if (_ongoingRequest == null) return const SizedBox.shrink();

    final status = _ongoingRequest!.status.toUpperCase();
    final bool isApproved = status == 'APROVADO' || status == 'APPROVED';
    
    Color statusColor = AppColors.alertOrange;
    IconData statusIcon = Icons.history_edu_rounded;

    if (isApproved) {
      statusColor = AppColors.statusGreen;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'REJEITADO' || status == 'REJECTED') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Solicitação em andamento',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
              ),
              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ongoingRequest!.type == 'new_card' ? 'Nova Carteira Digital' : 'Atualização de Cadastro',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Protocolo: #${_ongoingRequest!.protocol}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.borderLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproved ? 'Solicitação concluída' : 'Previsão de conclusão',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isApproved ? 'Já disponível na carteira' : 'Em até 5 dias úteis',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onNavigate(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detalhes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Outros serviços',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            clipBehavior: Clip.none,
            children: [
              _buildServiceCard(
                icon: Icons.person_outline_rounded,
                title: 'Meus dados',
                subtitle: 'Atualize seu perfil',
                onTap: () => widget.onNavigate(4),
              ),
              _buildServiceCard(
                icon: Icons.help_outline_rounded,
                title: 'Suporte',
                subtitle: 'Precisa de ajuda?',
                onTap: () {
                  // Link para suporte (ex: WhatsApp ou página de suporte)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Suporte em breve!')),
                  );
                },
              ),
              _buildServiceCard(
                icon: Icons.info_outline_rounded,
                title: 'Sobre',
                subtitle: 'Nossa missão',
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Página Sobre em breve!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 200, // Card mais largo para o carousel de serviços
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 1.0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14, 
                            fontWeight: FontWeight.w800, 
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 10, 
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary.withValues(alpha: 0.5), size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.darkBlue,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inclusão que conecta.\nDireitos que transformam.',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ConeCTEA: conectando famílias, direitos\ne oportunidades.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conheça mais sobre o ConeCTEA em nosso site oficial.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Saiba mais', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
