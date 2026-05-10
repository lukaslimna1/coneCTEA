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
import '../requests/add_member_page.dart';
import '../cards/widgets/digital_card_widget.dart';
import '../admin/scanner_view.dart';
import '../account/edit_profile_view.dart';
import '../legal/terms_of_use_page.dart';
import '../account/security_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/widgets/premium/app_background.dart';
import '../../core/widgets/premium/premium_card.dart';
import '../../core/constants/design_tokens.dart';

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
  DateTime? _lastResetRequest;
  int _selectedMemberIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _requestRenewal(String requestId) async {
    if (_lastResetRequest != null &&
        DateTime.now().difference(_lastResetRequest!).inMinutes < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aguarde um momento antes de solicitar novamente.'),
            backgroundColor: AppColors.alertOrange,
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    _lastResetRequest = DateTime.now();
    try {
      await _databaseService.updateCardRequestStatus(
        requestId,
        'renewing',
        adminNotes: 'Pedido de renovação iniciado pelo usuário.',
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido de renovação enviado com sucesso!'),
            backgroundColor: AppColors.primary,
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
        var user = await _databaseService.getUserProfile(userId);

        if (user == null) {
          final email = _authService.currentUser?.email ?? '';
          final metaName =
              _authService.currentUser?.userMetadata?['name'] ??
              _authService.currentUser?.userMetadata?['full_name'] ??
              email.split('@')[0];

          user = AppUser(
            id: userId,
            email: email,
            name: metaName,
            role: (email == 'lucasmslima1@gmail.com')
                ? UserRole.admin
                : UserRole.user,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            cpf: '',
            phone: '',
            isActive: true,
          );
        } else if (user.name.trim().isEmpty || user.name == 'Usuário') {
          final metaName =
              _authService.currentUser?.userMetadata?['name'] ??
              _authService.currentUser?.userMetadata?['full_name'];
          if (metaName != null && metaName.toString().trim().isNotEmpty) {
            user = user.copyWith(name: metaName.toString().trim());
          }
        }

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isProfileComplete {
    if (_user == null) return false;
    return _user!.cpf.isNotEmpty &&
        _user!.phone.isNotEmpty &&
        (_user!.city?.isNotEmpty ?? false) &&
        (_user!.state?.isNotEmpty ?? false);
  }

  void _handleRequestCard() {
    if (!_isProfileComplete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('🎉 Quase lá!'),
          content: const Text(
            'Para solicitar sua carteirinha, seu perfil precisa estar completo com CPF, Telefone, Cidade e Estado.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    this.context,
                    MaterialPageRoute(builder: (_) => const EditProfileView()),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text(
                  'Completar Dados',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Voltar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
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
    if (_user != null) {
      final String name =
          (_user!.socialName != null && _user!.socialName!.isNotEmpty)
          ? _user!.socialName!
          : _user!.name;

      if (name.trim().isNotEmpty && name != 'Usuário') {
        return name.trim().split(' ').first;
      }
    }

    final metaName =
        _authService.currentUser?.userMetadata?['name'] ??
        _authService.currentUser?.userMetadata?['full_name'];

    if (metaName != null && metaName.toString().trim().isNotEmpty) {
      return metaName.toString().trim().split(' ').first;
    }

    final email = _authService.currentUser?.email;
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }

    return 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.id;
    if (userId == null)
      return const Center(child: Text('Por favor, faça login'));

    return StreamBuilder<List<Member>>(
      stream: _databaseService.membersStream(userId),
      builder: (context, memberSnapshot) {
        if (memberSnapshot.connectionState == ConnectionState.waiting &&
            _isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final members = memberSnapshot.data ?? [];
        _members = members;

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

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  extendBodyBehindAppBar: true,
                  body: AppBackground(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 100, 0, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGreeting(),
                            const SizedBox(height: 12),
                            _buildMembersSection(),
                            const SizedBox(height: 24),
                            _buildCarteirinhaSection(),
                            const SizedBox(height: 32),
                            _buildBlock1(),
                            const SizedBox(height: 24),
                            _buildBlock2(),
                            const SizedBox(height: 24),
                            _buildBlock3(),
                            const SizedBox(height: 24),
                            _buildInstitutionalBanner(),
                            const SizedBox(height: 40),
                          ],
                        ),
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
    final ongoingRequests = requests.where((r) {
      final s = r.status.toLowerCase();
      return s != 'active' &&
          s != 'ativa' &&
          s != 'approved' &&
          s != 'aprovada';
    }).toList();

    if (ongoingRequests.isEmpty) return const SizedBox.shrink();

    return _buildOngoingRequest(ongoingRequests.first);
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $_displayName!',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cardTitle,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Que bom te ver por aqui.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cardSubtitle,
                  ),
                ),
              ],
            ),
          ),
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
                color: AppColors.cardTitle,
                size: 28,
              ),
            ),
          ),
        ],
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
                      color: AppColors.cardTitle,
                    ),
                  ),
                  Text(
                    'Selecione um membro para visualizar.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.cardSubtitle,
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
              final initials = member.initials;

              return GestureDetector(
                onTap: () => setState(() => _selectedMemberIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.premiumGradient
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: member.status.toLowerCase() == 'ativa' ||
                                          member.status.toLowerCase() == 'active'
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
                                  fontWeight: FontWeight.w700,
                                  color: member.status.toLowerCase() == 'ativa' ||
                                          member.status.toLowerCase() == 'active'
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
        child: PremiumCard(
          padding: const EdgeInsets.all(24),
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Você ainda não possui uma carteirinha.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Cadastre um membro para solicitar a carteirinha de identificação premium do projeto.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cardSubtitle.withValues(alpha: 0.8),
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Solicitar Carteirinha',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
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

    if (_members.isEmpty || _selectedMemberIndex >= _members.length) {
      return const SizedBox.shrink();
    }

    final member = _members[_selectedMemberIndex];
    CardRequest? memberRequest;
    try {
      memberRequest = _requests.firstWhere((r) => r.memberId == member.id);
    } catch (_) {
      memberRequest = null;
    }

    final String rawStatus = memberRequest?.status.toLowerCase() ?? member.status.toLowerCase();

    String statusDisplay = 'EM ANÁLISE';
    Color statusColor = AppColors.alertOrange;
    IconData statusIcon = Icons.history_rounded;
    bool isActive = false;
    bool showJustification = false;
    bool isRejected = false;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Documento Digital',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.cardTitle,
              ),
            ),
          ),
          PremiumCard(
            padding: const EdgeInsets.all(24),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Frente da carteirinha
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.6,
                        child: _buildMiniCard(isVerso: false, member: member),
                      ),
                    ),
                    
                    // Overlay de Status (quando não ativa)
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              statusDisplay,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (showJustification && adminNotes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showJustificationDialog(
                        statusDisplay,
                        statusColor,
                        adminNotes,
                        isRejected: effectiveStatus == 'rejected',
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (isRejected)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        const whatsappUrl = "https://wa.me/5514997728448";
                        if (await canLaunchUrlString(whatsappUrl)) {
                          await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.support_agent_rounded, color: AppColors.errorRed),
                      label: Text(
                        'Falar com Suporte',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.errorRed,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.errorRed, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                      icon: Icon(
                        isActive
                            ? Icons.qr_code_scanner_rounded
                            : (status == 'expired' || status == 'suspended'
                                ? Icons.autorenew_rounded
                                : (status == 'waiting_docs' || status == 'reviewing_data'
                                    ? Icons.edit_document
                                    : Icons.lock_outline_rounded)),
                        size: 20,
                      ),
                      label: Text(
                        isActive
                            ? 'Abrir Carteira Digital'
                            : (status == 'expired' || status == 'suspended'
                                ? 'Solicitar Renovação'
                                : (status == 'waiting_docs'
                                    ? 'Enviar Documentos'
                                    : (status == 'reviewing_data'
                                        ? 'Revisar Dados'
                                        : 'Aguardando Aprovação'))),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? AppColors.primary
                            : (status == 'waiting_docs' || status == 'reviewing_data'
                                ? AppColors.alertOrange
                                : (status == 'expired' || status == 'suspended'
                                    ? Colors.purple
                                    : AppColors.borderLight.withValues(alpha: 0.2))),
                        foregroundColor: isActive ||
                                status == 'waiting_docs' ||
                                status == 'reviewing_data' ||
                                status == 'expired' ||
                                status == 'suspended'
                            ? Colors.white
                            : AppColors.textSecondary,
                        elevation: isActive ? 4 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.cyan.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Família TEA Bauru',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Conectando e Apoiando',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cardTitle,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O ConeCTEA é mais que um app, é uma rede de suporte para nossa comunidade.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.cardSubtitle,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          // TODO: Abrir site ou mais info
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Saiba mais sobre o projeto',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_right_alt_rounded,
                              color: AppColors.cyan,
                              size: 20,
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

  Widget _buildMiniCard({required bool isVerso, Member? member}) {
    member ??= Member(
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

    return RepaintBoundary(
      child: IgnorePointer(
        child: DigitalCardWidget(
          member: member,
          showBack: isVerso,
          card: null,
          isStatic: true,
        ),
      ),
    );
  }

  Widget _buildBlock1() {
    return _buildCarouselSection(
      title: 'Acesso Rápido',
      items: [
        _buildQuickCard(
          icon: Icons.badge_outlined,
          title: 'Ver carteirinha',
          subtitle: 'Acesse seu documento',
          color: AppColors.primary,
          onTap: () {
            if (_members.isNotEmpty &&
                _selectedMemberIndex < _members.length &&
                (_members[_selectedMemberIndex].status.toLowerCase() ==
                        'ativa' ||
                    _members[_selectedMemberIndex].status.toLowerCase() ==
                        'active')) {
              widget.onNavigate(1);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carteirinha ainda não disponível.'),
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
      ],
    );
  }

  Widget _buildBlock2() {
    return _buildCarouselSection(
      title: 'Outros Serviços',
      items: [
        _buildQuickCard(
          icon: Icons.construction_rounded,
          title: 'Em breve',
          subtitle: 'Novas ferramentas vindo aí',
          color: AppColors.cardMutedText,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBlock3() {
    return _buildCarouselSection(
      title: 'Informações',
      items: [
        _buildQuickCard(
          icon: Icons.security_rounded,
          title: 'Segurança',
          subtitle: 'Sua conta protegida',
          color: const Color(0xFF6366F1), // Indigo Premium
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityView()),
          ),
        ),
        _buildQuickCard(
          icon: Icons.help_outline_rounded,
          title: 'Suporte',
          subtitle: 'Fale conosco no WhatsApp',
          color: AppColors.statusGreen,
          onTap: () async {
            const whatsappUrl = "https://wa.me/5514997728448";
            if (await canLaunchUrlString(whatsappUrl)) {
              await launchUrlString(
                whatsappUrl,
                mode: LaunchMode.externalApplication,
              );
            }
          },
        ),
        _buildQuickCard(
          icon: Icons.info_outline_rounded,
          title: 'Sobre',
          subtitle: 'Conheça o projeto',
          color: AppColors.alertOrange,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.cardBackground,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                title: Text(
                  'Sobre o ConeCTEA',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: AppColors.cardTitle,
                  ),
                ),
                content: Text(
                  'O ConeCTEA é uma iniciativa da Família TEA Bauru para facilitar a identificação e o suporte a pessoas com autismo e suas famílias.\n\nVersão 3.3.0',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.cardSubtitle,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Fechar',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCarouselSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cardTitle,
                ),
              ),
              if (items.length > 1)
                Row(
                  children: [
                    Text(
                      'Deslize',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cardSubtitle.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swipe_left_rounded,
                      color: AppColors.cardSubtitle.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 230,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            clipBehavior: Clip.none,
            children: items,
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
      padding: const EdgeInsets.only(right: 16, bottom: 8),
      child: PremiumCard(
        width: 165,
        height: 210,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashColor: color.withValues(alpha: 0.1),
            highlightColor: color.withValues(alpha: 0.05),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Icon(
                    icon,
                    color: color.withValues(alpha: 0.04),
                    size: 80,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cardTitle,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cardSubtitle,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ACESSAR',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
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
                color: AppColors.cardTitle,
              ),
            ),
          ),
          PremiumCard(
            padding: const EdgeInsets.all(24),
            margin: EdgeInsets.zero,
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
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.type == 'new_card' ||
                                    request.type == 'Emissão Digital'
                                ? 'Emissão de Carteirinha'
                                : 'Atualização de Cadastro',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Protocolo: #${request.protocol}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cardSubtitle.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                  color: Colors.white.withValues(alpha: 0.05),
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
                            isApproved
                                ? 'Solicitação concluída'
                                : 'Previsão de conclusão',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.cardSubtitle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isApproved
                                ? 'Já disponível na carteira'
                                : 'Em até 5 dias úteis',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
          if (request.expiresAt != null &&
              (request.status == 'waiting_docs' ||
                  request.status == 'reviewing_data'))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
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

  void _showJustificationDialog(
    String status,
    Color color,
    String notes, {
    bool isRejected = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Motivo: $status',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                notes,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.cardTitle,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isRejected) ...[
              const SizedBox(height: 20),
              Text(
                'Caso não concorde com esta decisão, entre em contato com o nosso suporte para mais informações.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.cardSubtitle.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: GoogleFonts.inter(
                color: AppColors.cardSubtitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isRejected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  const whatsappUrl = "https://wa.me/5514997728448";
                  if (await canLaunchUrlString(whatsappUrl)) {
                    await launchUrlString(
                      whatsappUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Suporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
