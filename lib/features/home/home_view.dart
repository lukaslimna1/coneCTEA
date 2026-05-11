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
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/features/requests/add_member_page.dart';
import 'package:conectea/features/cards/widgets/digital_card_widget.dart';
import 'package:conectea/features/account/edit_profile_view.dart';
import 'package:conectea/features/account/security_view.dart';
import 'package:conectea/features/home/about_conectea_view.dart';
import 'package:conectea/features/home/family_tea_view.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/features/home/widgets/banners/highlight_banner.dart';
import 'package:conectea/features/home/widgets/comum/home_section_header.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/home_quick_access_section.dart';
import 'package:conectea/features/home/widgets/outros_servicos/home_services_section.dart';
import 'package:conectea/features/home/widgets/informacoes/home_information_section.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';
import 'package:conectea/features/home/widgets/header/home_greeting_header.dart';
import 'package:conectea/features/home/widgets/solicitacoes/home_ongoing_request_section.dart';

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
  bool _isLoading = true;
  DateTime? _lastResetRequest;
  String? _selectedMemberId;

  Member? _getSelectedMember(List<Member> members) {
    if (members.isEmpty) return null;
    if (_selectedMemberId == null) return members.first;
    try {
      return members.firstWhere((m) => m.id == _selectedMemberId);
    } catch (_) {
      return members.first;
    }
  }

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
            role: UserRole.user, // Fallback local seguro
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

        final members = (memberSnapshot.data ?? [])
            .whereType<Member>()
            .toList();
        final selectedMember = _getSelectedMember(members);

        return StreamBuilder<List<CardRequest>>(
          stream: _databaseService.cardRequestsStream(userId),
          builder: (context, requestSnapshot) {
            final requests = (requestSnapshot.data ?? [])
                .whereType<CardRequest>()
                .toList();

            return StreamBuilder<List<DigitalCard>>(
              stream: _databaseService.digitalCardsStream(userId),
              builder: (context, cardSnapshot) {
                final digitalCards = (cardSnapshot.data ?? [])
                    .whereType<DigitalCard>()
                    .toList();

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
                            HomeGreetingHeader(
                              displayName: _displayName,
                              onQrTap: () => context.push('/qr-scanner'),
                            ),
                            const SizedBox(height: 12),
                            HomeOngoingRequestSection(
                              requests: requests,
                              onDetailsTap: () => widget.onNavigate(2),
                            ),
                            const SizedBox(height: 12),
                            _buildMembersSection(members, selectedMember),
                            const SizedBox(height: 24),
                            _buildCarteirinhaSection(
                              members: members,
                              requests: requests,
                              digitalCards: digitalCards,
                              selectedMember: selectedMember,
                            ),
                            const SizedBox(height: 32),
                            HomeQuickAccessSection(
                              onOpenDigitalCard: () {
                                if (selectedMember != null &&
                                    (selectedMember.status.toLowerCase() ==
                                            'ativa' ||
                                        selectedMember.status.toLowerCase() ==
                                            'active')) {
                                  widget.onNavigate(1);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Carteirinha ainda não disponível.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              onRequestCard: _handleRequestCard,
                              onOpenMural: () => widget.onNavigate(2),
                            ),
                            const SizedBox(height: 24),
                            const HomeServicesSection(),
                            const SizedBox(height: 24),
                            HomeInformationSection(
                              onSupportTap: () async {
                                const whatsappUrl =
                                    "https://wa.me/5514997728448";
                                if (await canLaunchUrlString(whatsappUrl)) {
                                  await launchUrlString(
                                    whatsappUrl,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              onAboutTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AboutConecteaView(),
                                ),
                              ),
                              onSecurityTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SecurityView(),
                                ),
                              ),
                              onFamilyTeaTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FamilyTeaView(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            HighlightBanner(
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

  Widget _buildMembersSection(List<Member> members, Member? selectedMember) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '${members.length} membros vinculados',
          subtitle: 'Selecione um membro para visualizar.',
          actionLabel: 'Ver todos',
          onActionTap: () => context.push('/member-selection'),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(members.length, (index) {
              final member = members[index];
              final isSelected = member.id == selectedMember?.id;
              final initials = member.initials;
              final statusInfo = HomeStatusHelper.memberStatus(member.status);

              return GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _selectedMemberId = member.id;
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
                                  color: statusInfo.isActive
                                      ? AppColors.statusGreen
                                      : AppColors.alertOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusInfo.shortLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusInfo.isActive
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

  Widget _buildCarteirinhaSection({
    required List<Member> members,
    required List<CardRequest> requests,
    required List<DigitalCard> digitalCards,
    required Member? selectedMember,
  }) {
    if (members.isEmpty) {
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

    if (selectedMember == null) {
      return const SizedBox.shrink();
    }

    final member = selectedMember;

    DigitalCard? digitalCard;
    try {
      digitalCard = digitalCards.firstWhere((c) => c.memberId == member.id);
    } catch (_) {
      digitalCard = null;
    }

    CardRequest? memberRequest;
    try {
      memberRequest = requests.firstWhere((r) => r.memberId == member.id);
    } catch (_) {
      memberRequest = null;
    }

    final String rawStatus = (memberRequest?.status ?? member.status)
        .toLowerCase();

    final lastUpdate = memberRequest?.updatedAt ?? member.updatedAt;
    final isExpired =
        rawStatus == 'active' &&
        DateTime.now().difference(lastUpdate).inDays >= 365;
    final statusInfo = HomeStatusHelper.digitalCardStatus(
      rawStatus,
      isExpired: isExpired,
    );
    final status = isExpired ? 'expired' : rawStatus;
    final effectiveStatus = status;

    final String statusDisplay = statusInfo.fullLabel;
    final Color statusColor = statusInfo.color;
    final IconData statusIcon = statusInfo.icon;
    final bool isActive = statusInfo.isActive;
    final bool showJustification = statusInfo.showJustification;
    final bool isRejected = statusInfo.isRejected;

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
}
