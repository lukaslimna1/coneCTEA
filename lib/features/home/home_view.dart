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
import '../account/edit_profile_view.dart';
import '../account/security_view.dart';
import 'about_conectea_view.dart';
import 'family_tea_view.dart';
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
    if (userId == null) {
      return const Center(child: Text('Por favor, faça login'));
    }

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
        _members = members.whereType<Member>().toList();

        return StreamBuilder<List<CardRequest>>(
          stream: _databaseService.cardRequestsStream(userId),
          builder: (context, requestSnapshot) {
            final requests = requestSnapshot.data ?? [];
            _requests = requests.whereType<CardRequest>().toList();

            return StreamBuilder<List<DigitalCard>>(
              stream: _databaseService.digitalCardsStream(userId),
              builder: (context, cardSnapshot) {
                final cards = cardSnapshot.data ?? [];
                _digitalCards = cards.whereType<DigitalCard>().toList();

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
                            _buildOngoingRequestSection(_requests),
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
                            _buildHighlightBanner(
                              eyebrow: 'Família TEA Bauru',
                              title: 'Acompanhe novidades e projetos',
                              subtitle:
                                  'Conheça projetos, ações e atualizações da Família TEA Bauru.',
                              ctaLabel: 'Ver Instagram',
                              eyebrowColor: const Color(0xFFA855F7),
                              illustration: Icons.volunteer_activism_rounded,
                              onTap: () async {
                                const instagramUrl =
                                    "https://www.instagram.com/familiateabauru/";
                                if (await canLaunchUrlString(instagramUrl)) {
                                  await launchUrlString(
                                    instagramUrl,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
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
      final s = (r.status ?? 'analise').toLowerCase();
      return s != 'active' &&
          s != 'ativa' &&
          s != 'approved' &&
          s != 'aprovada';
    }).toList();

    if (ongoingRequests.isEmpty) return const SizedBox.shrink();

    // Defensive check: ensure the first request is not null
    final request = ongoingRequests.isNotEmpty ? ongoingRequests.first : null;
    if (request == null) return const SizedBox.shrink();

    return _buildOngoingRequest(request);
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
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _selectedMemberIndex = index;
                    });
                  }
                },
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
                            (member.name ?? 'Membro').split(' ').first,
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
                                  color:
                                      (member.status ?? 'analise')
                                                  .toLowerCase() ==
                                              'ativa' ||
                                          (member.status ?? 'analise')
                                                  .toLowerCase() ==
                                              'active'
                                      ? AppColors.statusGreen
                                      : AppColors.alertOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                () {
                                  final status = (member.status ?? 'analise')
                                      .toLowerCase();
                                  switch (status) {
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
                                  color:
                                      (member.status ?? 'analise')
                                                  .toLowerCase() ==
                                              'ativa' ||
                                          (member.status ?? 'analise')
                                                  .toLowerCase() ==
                                              'active'
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
    
    // Busca o cartão digital real do membro
    DigitalCard? digitalCard;
    try {
      digitalCard = _digitalCards.firstWhere((c) => c.memberId == member.id);
    } catch (_) {
      digitalCard = null;
    }

    CardRequest? memberRequest;
    try {
      memberRequest = _requests.firstWhere((r) => r.memberId == member.id);
    } catch (_) {
      memberRequest = null;
    }

    final String rawStatus =
        (memberRequest?.status ?? member.status ?? 'analise').toLowerCase();

    String statusDisplay = 'EM ANÁLISE';
    Color statusColor = AppColors.alertOrange;
    IconData statusIcon = Icons.history_rounded;
    bool isActive = false;
    bool showJustification = false;
    bool isRejected = false;

    final lastUpdate = memberRequest?.updatedAt ?? member.updatedAt;
    final isExpired =
        lastUpdate != null &&
        rawStatus == 'active' &&
        DateTime.now().difference(lastUpdate).inDays >= 365;
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
                AspectRatio(
                  aspectRatio: 1.58,
                  child: Stack(
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
                          child: DigitalCardWidget(
                            card: digitalCard,
                            member: member,
                            isStatic: true,
                          ),
                        ),
                      ),

                      // Overlay de Status (quando não ativa)
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
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
                      icon: Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color: statusColor,
                      ),
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
                          await launchUrlString(
                            whatsappUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.errorRed,
                      ),
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
                        side: const BorderSide(
                          color: AppColors.errorRed,
                          width: 1.5,
                        ),
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
                        } else if (status == 'waiting_docs' ||
                            status == 'reviewing_data') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddMemberPage(
                                member: member,
                                request: memberRequest,
                              ),
                            ),
                          ).then((_) => _loadData());
                        } else if (status == 'expired' ||
                            status == 'suspended') {
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
                                  : (status == 'waiting_docs' ||
                                            status == 'reviewing_data'
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
                            : (status == 'waiting_docs' ||
                                      status == 'reviewing_data'
                                  ? AppColors.alertOrange
                                  : (status == 'expired' ||
                                            status == 'suspended'
                                        ? Colors.purple
                                        : AppColors.borderLight.withValues(
                                            alpha: 0.2,
                                          ))),
                        foregroundColor:
                            isActive ||
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

  Widget _buildHighlightBanner({
    required String eyebrow,
    required String title,
    required String subtitle,
    required String ctaLabel,
    required VoidCallback onTap,
    Color eyebrowColor = const Color(0xFFA855F7),
    IconData? illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 152,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B235A),
              Color(0xFF132D55),
              Color(0xFF0A3A57),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative Glow
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF22D3EE).withValues(alpha: 0.1),
                        const Color(0xFF22D3EE).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              // Illustration decorativa sutil
              if (illustration != null)
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    illustration,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              // Conteúdo interativo
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: eyebrowColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              eyebrow.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: eyebrowColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFD6E1F0),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '$ctaLabel →',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF22D3EE),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBlock1() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.72).clamp(280.0, 305.0);

    return _buildCarouselSection(
      title: 'Acesso Rápido',
      height: 168,
      items: [
        _buildQuickAccessCard(
          width: cardWidth,
          icon: PhosphorIcons.identificationCard(PhosphorIconsStyle.light),
          title: 'Ver carteirinha',
          subtitle: 'Acesse sua carteirinha digital.',
          ctaLabel: 'Abrir',
          accentColor: const Color(0xFF8B5CF6),
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
        _buildQuickAccessCard(
          width: cardWidth,
          icon: PhosphorIcons.filePlus(PhosphorIconsStyle.light),
          title: 'Solicitar',
          subtitle: 'Peça sua carteirinha ou atualize dados.',
          ctaLabel: 'Solicitar',
          accentColor: const Color(0xFF22D3EE),
          onTap: _handleRequestCard,
        ),
        _buildQuickAccessCard(
          width: cardWidth,
          icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.light),
          title: 'Meu mural',
          subtitle: 'Acompanhe avisos e comunicados.',
          ctaLabel: 'Acessar',
          accentColor: const Color(0xFF60A5FA),
          onTap: () => widget.onNavigate(2),
        ),
      ],
    );
  }

  Widget _buildBlock2() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.78).clamp(300.0, 340.0);

    return _buildCarouselSection(
      title: 'Outros Serviços',
      height: 185,
      items: [
        _buildEmBreveServiceCard(
          width: cardWidth,
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildBlock3() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.75).clamp(280.0, 320.0);

    return _buildCarouselSection(
      title: 'Informações',
      height: 80,
      titleSpacing: 10,
      items: [
        _buildInfoActionCard(
          width: cardWidth,
          icon: PhosphorIcons.headset(PhosphorIconsStyle.fill),
          title: 'Suporte',
          subtitle: 'Fale conosco pelo WhatsApp.',
          accentColor: const Color(0xFF34D399),
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
        _buildInfoActionCard(
          width: cardWidth,
          icon: PhosphorIcons.info(PhosphorIconsStyle.fill),
          title: 'Sobre o app',
          subtitle: 'Entenda o ConeCTEA.',
          accentColor: const Color(0xFFF59E0B),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutConecteaView()),
          ),
        ),
        _buildInfoActionCard(
          width: cardWidth,
          icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          title: 'Segurança',
          subtitle: 'Dados e privacidade.',
          accentColor: const Color(0xFF818CF8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityView()),
          ),
        ),
        _buildInfoActionCard(
          width: cardWidth,
          icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
          title: 'Família TEA',
          subtitle: 'Conheça a organização.',
          accentColor: const Color(0xFF22D3EE),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FamilyTeaView()),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselSection({
    required String title,
    required List<Widget> items,
    double height = 185,
    double titleSpacing = 16,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF8FAFC),
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: titleSpacing),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }


  Widget _buildQuickAccessCard({
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required String ctaLabel,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      height: 138,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A192F), // Tom de fundo profundo
                  Color(0xFF060D1A), // Quase preto como o background real
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0x2494A3B4), // rgba(148,163,184,0.14)
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Camada de vidro sutil
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.025),
                  ),
                ),
                // Efeito de luz sutil no canto (Glow)
                Positioned(
                  bottom: -40,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.12),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Borda superior colorida (seguindo o radius)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bloco Superior: Ícone + Textos
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Moldura do ícone (Dark Glass Tint - Ultra Dark)
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFF020617).withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.50),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Tinta interna (Color Tint)
                                Container(
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    icon,
                                    color: const Color(0xFFF8FAFC),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF8FAFC),
                                    height: 1.05,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFB8C2D6),
                                    height: 1.26,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // CTA Button
                      Container(
                        height: 40,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F234B).withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.65),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ctaLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: accentColor,
                              size: 16,
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

  Widget _buildEmBreveServiceCard({
    required double width,
    required Color accentColor,
  }) {
    return SizedBox(
      width: width,
      height: 170,
      child: Material(
        color: Colors.transparent,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0B1D3A), // Fundo azul profundo
                Color(0xFF060D1A), // Centro quase preto
                Color(0xFF0A192F), // Tom escuro navy
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0x2494A3B4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Camada de vidro sutil
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),

              // --- ILUSTRAÇÃO VIVA (Lado Direito) ---

              // 1. Glow de Fundo (Acento Roxo)
              Positioned(
                right: -50,
                top: -20,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.18),
                        accentColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Glow de Fundo (Acento Ciano)
              Positioned(
                right: 20,
                bottom: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF22D3EE).withValues(alpha: 0.15),
                        const Color(0xFF22D3EE).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Estrelas/Dots (Profundidade)
              ...List.generate(6, (index) {
                final positions = [
                  const Offset(0.45, 0.25),
                  const Offset(0.55, 0.45),
                  const Offset(0.40, 0.60),
                  const Offset(0.65, 0.20),
                  const Offset(0.75, 0.50),
                  const Offset(0.85, 0.30),
                ];
                final sizes = [3.0, 2.0, 4.0, 2.5, 3.5, 2.0];
                final opacities = [0.15, 0.10, 0.20, 0.12, 0.18, 0.10];
                
                return Positioned(
                  left: width * positions[index].dx,
                  top: 170 * positions[index].dy,
                  child: Container(
                    width: sizes[index],
                    height: sizes[index],
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacities[index]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (sizes[index] > 3)
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              // 4. PNG Illustration (O Foguete Premium)
              Positioned(
                right: -10,
                bottom: -15,
                child: Opacity(
                  opacity: 0.65, // Opacidade controlada para integrar ao dark mode
                  child: Image.asset(
                    'assets/images/coming_soon.png',
                    width: 165,
                    height: 165,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // 5. Brilho extra sobre a imagem
              Positioned(
                right: 30,
                bottom: 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.08),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),

              // --- CONTEÚDO E ESTRUTURA ---

              // Borda superior colorida
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        const Color(0xFF22D3EE),
                        const Color(0xFF60A5FA),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Moldura do ícone (Dark Glass Fumé)
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF020617).withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.15),
                                blurRadius: 10,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Icon(
                            PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Em breve',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: accentColor.withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      'NOVO',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Novas ferramentas\nchegando para você.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // CTA Estilo Rodapé (Mesmo padrão)
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            'Aguardar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 12,
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
                                color: AppColors.cardSubtitle.withValues(
                                  alpha: 0.7,
                                ),
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
                        request.expiresAt != null
                            ? 'Você tem até o dia ${request.expiresAt!.day.toString().padLeft(2, '0')}/${request.expiresAt!.month.toString().padLeft(2, '0')}/${request.expiresAt!.year} para concluir ou sua solicitação será reprovada.'
                            : 'Sua solicitação está sendo analisada.',
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
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
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
                border: Border.all(color: color.withValues(alpha: 0.1)),
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
  Widget _buildInfoActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    double? width,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

