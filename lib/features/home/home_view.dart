import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:math' as math;
import '../requests/add_member_page.dart';
import '../cards/widgets/digital_card_widget.dart';
import '../admin/scanner_view.dart';

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
  List<CardRequest> _requests = [];
  List<DigitalCard> _digitalCards = [];
  bool _isLoading = true;
  int _selectedMemberIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _requestRenewal(String requestId) async {
    setState(() => _isLoading = true);
    try {
      await _databaseService.updateCardRequestStatus(
        requestId, 
        'renewing', 
        adminNotes: 'Pedido de renovação iniciado pelo usuário.'
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido de renovação enviado com sucesso!'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao solicitar renovação: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        debugPrint('HomeView: Loading profile for $userId');
        var user = await _databaseService.getUserProfile(userId);
        
        if (user == null) {
          debugPrint('HomeView: Profile null in DB, checking metadata...');
          final email = _authService.currentUser?.email ?? '';
          final metaName = _authService.currentUser?.userMetadata?['name'] 
              ?? _authService.currentUser?.userMetadata?['full_name']
              ?? email.split('@')[0];
          
          user = AppUser(
            id: userId,
            email: email,
            name: metaName,
            role: (email == 'lucasmslima1@gmail.com') ? UserRole.admin : UserRole.user,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            cpf: '',
            phone: '',
            isActive: true,
          );
        } else if (user.name.trim().isEmpty || user.name == 'Usuário') {
          debugPrint('HomeView: Profile name empty or default, checking metadata...');
          final metaName = _authService.currentUser?.userMetadata?['name'] 
              ?? _authService.currentUser?.userMetadata?['full_name'];
          if (metaName != null && metaName.toString().trim().isNotEmpty) {
            user = user.copyWith(name: metaName.toString().trim());
          }
        }
        
        debugPrint('HomeView: User loaded: ${user.name}');

        if (mounted) {
          setState(() {
            _user = user;
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

  bool get _isProfileComplete {
    if (_user == null) return false;
    // Campos mínimos para solicitar carteirinha
    return _user!.cpf.isNotEmpty && 
           _user!.phone.isNotEmpty && 
           _user!.city.isNotEmpty && 
           _user!.state.isNotEmpty;
  }

  void _handleRequestCard() {
    if (!_isProfileComplete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('🎉 Quase lá!'),
          content: const Text(
            'Para solicitar sua carteirinha, seu perfil precisa estar completo com CPF, Telefone e Endereço.\n\nPor favor, entre em contato com o suporte ou aguarde a atualização do sistema para editar seus dados.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendi', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
      return;
    }
    context.push('/member-selection');
  }

  String get _displayName {
    // 1. Try loaded _user name
    if (_user != null) {
      final String name = (_user!.socialName != null && _user!.socialName!.isNotEmpty)
          ? _user!.socialName!
          : _user!.name;
      
      if (name.trim().isNotEmpty && name != 'Usuário') {
        return name.trim().split(' ').first;
      }
    }

    // 2. Fallback to Auth Metadata
    final metaName = _authService.currentUser?.userMetadata?['name'] 
        ?? _authService.currentUser?.userMetadata?['full_name'];
    
    if (metaName != null && metaName.toString().trim().isNotEmpty) {
      return metaName.toString().trim().split(' ').first;
    }

    // 3. Fallback to Email prefix
    final email = _authService.currentUser?.email;
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }

    return 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.id;
    if (userId == null) return const Center(child: Text('Por favor, faça login'));

    return StreamBuilder<List<Member>>(
      stream: _databaseService.membersStream(userId),
      builder: (context, memberSnapshot) {
        if (memberSnapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        
        final members = memberSnapshot.data ?? [];
        _members = members; // Update local state for selection

        return StreamBuilder<List<CardRequest>>(
          stream: _databaseService.cardRequestsStream(userId),
          builder: (context, requestSnapshot) {
            final requests = requestSnapshot.data ?? [];
            _requests = requests;

            return StreamBuilder<List<DigitalCard>>(
              stream: _databaseService.digitalCardsStream(userId),
              builder: (context, cardSnapshot) {
                final cards = cardSnapshot.data ?? [];
                _digitalCards = cards;

                return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Slate 100
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF1F5F9), // Slate 100
                    const Color(0xFFCBD5E1), // Slate 300
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
                      _buildOngoingRequestSection(requests),
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
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOngoingRequestSection(List<CardRequest> requests) {
    // Filter out approved/active requests as they are already displayed in the main card section
    final ongoingRequests = requests.where((r) {
      final s = r.status.toLowerCase();
      return s != 'active' && s != 'ativa' && s != 'approved' && s != 'aprovada';
    }).toList();

    if (ongoingRequests.isEmpty) return const SizedBox.shrink();
    
    return _buildOngoingRequest(ongoingRequests.first);
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerView()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
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
                                () {
                                  switch (member.status.toLowerCase()) {
                                    case 'active':
                                    case 'ativa':
                                      return 'Ativa';
                                    case 'waiting_approval':
                                    case 'under_review':
                                    case 'analise':
                                      return 'Em Análise';
                                    case 'waiting_docs':
                                      return 'Aguardando Docs';
                                    case 'reviewing_data':
                                      return 'Revisar Dados';
                                    case 'rejected':
                                    case 'rejeitada':
                                      return 'Reprovada';
                                    case 'suspended':
                                    case 'suspensa':
                                      return 'Suspensa';
                                    case 'expired':
                                    case 'vencida':
                                      return 'Vencida';
                                    case 'renewing':
                                      return 'Em Renovação';
                                    default:
                                      return 'Em Análise';
                                  }
                                }(),
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
                onPressed: _handleRequestCard,
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
    // Encontrar a solicitação vinculada ao membro
    CardRequest? memberRequest;
    try {
      memberRequest = _requests.firstWhere((r) => r.memberId == member.id);
    } catch (_) {
      memberRequest = null;
    }

    final String rawStatus = memberRequest?.status.toLowerCase() ?? member.status.toLowerCase();
    
    // Status translation and logic
    String statusDisplay = 'EM ANÁLISE';
    Color statusColor = const Color(0xFFF9A825); // Yellow
    IconData statusIcon = Icons.history_rounded;
    bool isActive = false;
    bool showJustification = false;
    bool isRejected = false;

    // Check for automatic expiration (365 days after last update if active)
    final lastUpdate = memberRequest?.updatedAt ?? member.updatedAt;
    final isExpired = rawStatus == 'active' && DateTime.now().difference(lastUpdate).inDays >= 365;
    final effectiveStatus = isExpired ? 'expired' : rawStatus;
    final status = effectiveStatus;

    switch (effectiveStatus) {
      case 'active':
      case 'ativa':
      case 'approved':
      case 'aprovada':
        statusDisplay = 'ATIVA';
        statusColor = AppColors.statusGreen;
        statusIcon = Icons.check_circle_rounded;
        isActive = true;
        break;
      case 'waiting_approval':
      case 'under_review':
      case 'analise':
        statusDisplay = 'EM ANÁLISE';
        statusColor = AppColors.alertOrange;
        statusIcon = Icons.history_rounded;
        break;
      case 'waiting_docs':
        statusDisplay = 'AGUARDANDO DOCS';
        statusColor = AppColors.cardBlue;
        statusIcon = Icons.file_present_rounded;
        showJustification = true;
        break;
      case 'reviewing_data':
        statusDisplay = 'REVISAR DADOS';
        statusColor = AppColors.alertOrange;
        statusIcon = Icons.edit_note_rounded;
        showJustification = true;
        break;
      case 'rejected':
      case 'rejeitada':
        statusDisplay = 'REPROVADA';
        statusColor = AppColors.errorRed;
        statusIcon = Icons.error_outline_rounded;
        showJustification = true;
        isRejected = true;
        break;
      case 'suspended':
      case 'suspensa':
        statusDisplay = 'SUSPENSA';
        statusColor = AppColors.adminBlock;
        statusIcon = Icons.block_rounded;
        showJustification = true;
        break;
      case 'expired':
      case 'vencida':
        statusDisplay = 'VENCIDA';
        statusColor = Colors.brown;
        statusIcon = Icons.event_busy_rounded;
        break;
      case 'renewing':
      case 'renovacao':
        statusDisplay = 'RENOVAÇÃO';
        statusColor = AppColors.primary;
        statusIcon = Icons.autorenew_rounded;
        break;
      default:
        statusDisplay = 'EM ANÁLISE';
        statusColor = AppColors.alertOrange;
        statusIcon = Icons.pending_actions_rounded;
    }

    final adminNotes = memberRequest?.adminNotes ?? '';

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
                    height: 130,
                    child: _Animated3DCardGroup(
                      frontCard: _buildMiniCard(isVerso: false, member: member),
                      backCard: _buildMiniCard(isVerso: true, member: member),
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
                          statusIcon, 
                          color: statusColor, 
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Carteirinha',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          statusDisplay,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                        () {
                          String? displayId;
                          if (isActive) {
                            try {
                              final card = _digitalCards.firstWhere((DigitalCard c) => c.memberId == member.id);
                              displayId = card.cardNumber;
                            } catch (_) {}
                          }
                          displayId ??= memberRequest?.protocol;

                          if (displayId == null || displayId.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                displayId,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }(),
                        const Divider(height: 20, color: AppColors.borderLight),
                        Text(
                          'Vencimento',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        ),
                        Text(
                          (memberRequest?.expiresAt != null) 
                            ? DateFormat('dd/MM/yyyy').format(memberRequest!.expiresAt!) 
                            : (isActive ? DateFormat('dd/MM/yyyy').format(lastUpdate.add(const Duration(days: 365))) : '--/--/----'),
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
            
            if (showJustification && adminNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (effectiveStatus == 'rejected' || effectiveStatus == 'suspended')
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showJustificationDialog(
                      statusDisplay, 
                      statusColor, 
                      adminNotes, 
                      isRejected: effectiveStatus == 'rejected'
                    ),
                    icon: Icon(Icons.help_outline_rounded, size: 18, color: statusColor),
                    label: Text(
                      "Ver motivo da ${effectiveStatus == 'rejected' ? 'reprovação' : 'suspensão'}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: statusColor.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: statusColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Justificativa da Equipe:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adminNotes,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),
            
            if (isRejected)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    const whatsappUrl = "https://wa.me/5511999999999"; // TODO: Substituir pelo número real do suporte
                    if (await canLaunchUrlString(whatsappUrl)) {
                      await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.support_agent_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      Text(
                        'Falar com Suporte',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isActive) {
                      widget.onNavigate(1);
                    } else if (status == 'waiting_docs' || status == 'reviewing_data') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMemberPage(
                            member: member,
                            request: memberRequest,
                          ),
                        ),
                      ).then((_) => _loadData());
                    } else if (status == 'expired' || status == 'suspended') {
                      if (memberRequest != null) {
                        _requestRenewal(memberRequest.id);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.primary : 
                                   (status == 'waiting_docs' || status == 'reviewing_data' ? AppColors.warning : 
                                   (status == 'expired' || status == 'suspended' ? Colors.purple : AppColors.borderLight)),
                    foregroundColor: isActive || status == 'waiting_docs' || status == 'reviewing_data' || status == 'expired' || status == 'suspended' ? Colors.white : AppColors.textSecondary,
                    elevation: isActive ? 4 : 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.qr_code_scanner_rounded : 
                        (status == 'expired' || status == 'suspended' ? Icons.autorenew_rounded :
                        (status == 'waiting_docs' || status == 'reviewing_data' ? Icons.edit_document : Icons.lock_outline_rounded)), 
                        size: 20
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isActive ? 'Abrir Carteira Digital' : 
                        (status == 'expired' || status == 'suspended' ? 'Solicitar Renovação' :
                        (status == 'waiting_docs' ? 'Enviar Documentos' : 
                        (status == 'reviewing_data' ? 'Revisar Dados' : 'Aguardando Aprovação'))),
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
    if (member == null) {
      // Create a dummy member
      member = Member(
        id: 'dummy',
        userId: 'dummy',
        name: _user?.socialName ?? _user?.name ?? 'Membro',
        dateOfBirth: '2000-01-01',
        cpf: '***.***.***-**',
        phone: '',
        bloodType: '',
        emergencyContact: '',
        responsibleName: '',
        cid: '',
        documentUrl: '',
        medicalReportUrl: '',
        city: '',
        state: '',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    return SizedBox(
      width: 170,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: DigitalCardWidget(
            member: member!,
            showBack: isVerso,
            card: null,
            isStatic: true,
          ),
        ),
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
                onTap: _handleRequestCard,
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


  Widget _buildOngoingRequest(CardRequest? request) {
    if (request == null) return const SizedBox.shrink();

    final String rawStatus = request.status.toLowerCase();
    String statusDisplay = 'EM ANÁLISE';
    Color statusColor = AppColors.alertOrange;
    IconData statusIcon = Icons.history_edu_rounded;
    bool isApproved = false;

    switch (rawStatus) {
      case 'active':
      case 'ativa':
      case 'approved':
      case 'aprovada':
        statusDisplay = 'ATIVA';
        statusColor = AppColors.statusGreen;
        statusIcon = Icons.check_circle_rounded;
        isApproved = true;
        break;
      case 'waiting_approval':
      case 'under_review':
      case 'analise':
        statusDisplay = 'EM ANÁLISE';
        statusColor = AppColors.alertOrange;
        statusIcon = Icons.history_rounded;
        break;
      case 'waiting_docs':
        statusDisplay = 'AGUARDANDO DOCS';
        statusColor = AppColors.cardBlue;
        statusIcon = Icons.file_present_rounded;
        break;
      case 'reviewing_data':
        statusDisplay = 'REVISAR DADOS';
        statusColor = AppColors.alertOrange;
        statusIcon = Icons.edit_note_rounded;
        break;
      case 'rejected':
      case 'rejeitada':
        statusDisplay = 'REPROVADA';
        statusColor = AppColors.errorRed;
        statusIcon = Icons.error_outline_rounded;
        break;
      case 'suspended':
      case 'suspensa':
        statusDisplay = 'SUSPENSA';
        statusColor = AppColors.adminBlock;
        statusIcon = Icons.block_rounded;
        break;
      case 'expired':
      case 'vencida':
        statusDisplay = 'VENCIDA';
        statusColor = Colors.brown;
        statusIcon = Icons.event_busy_rounded;
        break;
      default:
        statusDisplay = 'EM ANÁLISE';
        statusColor = AppColors.alertOrange;
        statusIcon = Icons.pending_actions_rounded;
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
                            request.type == 'new_card' || request.type == 'Emissão Digital' 
                                ? 'Emissão de Carteirinha' 
                                : 'Atualização de Cadastro',
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
                              'Protocolo: #${request.protocol}',
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
                        statusDisplay,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
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
          if (request.expiresAt != null && (request.status == 'waiting_docs' || request.status == 'reviewing_data'))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você tem até o dia ${request.expiresAt!.day.toString().padLeft(2, '0')}/${request.expiresAt!.month.toString().padLeft(2, '0')}/${request.expiresAt!.year} para concluir ou sua solicitação será reprovada.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
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

  void _showJustificationDialog(String status, Color color, String notes, {bool isRejected = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 8),
            Text('Motivo: $status', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notes,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
            ),
            if (isRejected) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Caso não concorde com esta decisão, entre em contato com o nosso suporte para mais informações.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
          if (isRejected)
            ElevatedButton(
              onPressed: () async {
                const whatsappUrl = "https://wa.me/5511999999999"; // Substituir pelo número real
                if (await canLaunchUrlString(whatsappUrl)) {
                  await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Falar com Suporte'),
            ),
        ],
      ),
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

class _Animated3DCardGroup extends StatefulWidget {
  final Widget frontCard;
  final Widget backCard;

  const _Animated3DCardGroup({required this.frontCard, required this.backCard});

  @override
  State<_Animated3DCardGroup> createState() => _Animated3DCardGroupState();
}

class _Animated3DCardGroupState extends State<_Animated3DCardGroup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Efeito de entrada suave — sem loop infinito (evita artefatos no Chrome)
        final double progress = Curves.easeOutCubic.transform(_controller.value);
        final double hoverOffset = (1.0 - progress) * 12;
        final double tiltX = (1.0 - progress) * 0.05;
        final double tiltY = (1.0 - progress) * 0.05;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Back card (verso)
            Positioned(
              left: 12 + (tiltY * 20), // Reduced independent movement
              bottom: -4 + hoverOffset,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-0.08)
                  ..rotateY(0.15)
                  ..rotateZ(-0.04 + tiltX * 0.5),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.7,
                  child: widget.backCard,
                ),
              ),
            ),
            // Front card (frente)
            Positioned(
              right: 12 - (tiltY * 20), // Reduced independent movement
              top: -4 - hoverOffset,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.04)
                  ..rotateY(-0.08)
                  ..rotateZ(0.04 + tiltY * 0.5),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(4, 8),
                      ),
                    ],
                  ),
                  child: widget.frontCard,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
