import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';

import 'package:url_launcher/url_launcher_string.dart';

import 'package:conectea/features/account/profile/edit_profile_view.dart';
import 'package:conectea/features/account/seguranca/security_view.dart';
import 'package:conectea/features/account/institucional/about_conectea_view.dart';
import 'package:conectea/features/account/institucional/family_tea_view.dart';
import 'package:conectea/features/participar/projects_actions_view.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';

import 'package:conectea/features/home/widgets/banners/home_banners_section.dart';
import 'package:conectea/features/home/widgets/novidades/home_services_section.dart';
import 'package:conectea/features/home/widgets/informacoes/home_information_section.dart';

import 'package:conectea/features/home/widgets/header/home_greeting_header.dart';
import 'package:conectea/features/carteirinhas/solicitacao/add_member_page.dart';
import 'package:conectea/features/home/widgets/dinamico/home_dynamic_content.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/home_quick_access_section.dart';

class HomeView extends StatefulWidget {
  final AppUser? user;
  final Function(int) onNavigate;

  const HomeView({super.key, this.user, required this.onNavigate});

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

  Stream<List<Member>>? _membersStream;
  Stream<List<CardRequest>>? _cardRequestsStream;
  Stream<List<DigitalCard>>? _digitalCardsStream;

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
    _user = widget.user;
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        _user = widget.user;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        var user = widget.user;

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

        _membersStream = _databaseService.membersStream(userId);
        _cardRequestsStream = _databaseService.cardRequestsStream(userId);
        _digitalCardsStream = _databaseService.digitalCardsStream(userId);

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
    // Navegação direta para AddMemberPage em vez de MemberSelectionPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMemberPage()),
    ).then((_) => _loadData());
  }

  Future<void> _handleRenewalRequest(String requestId) async {
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
          SnackBar(
            content: const Text(
              'Não foi possível solicitar a renovação agora. Tente novamente em instantes.',
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSupportTap() async {
    const whatsappUrl = "https://wa.me/5514997728448";
    if (await canLaunchUrlString(whatsappUrl)) {
      await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
    }
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: Builder(
            builder: (context) {
              // Constantes de layout do topo para alinhar com o AppTopHeader e evitar magic numbers
              final double topSafeArea = MediaQuery.paddingOf(context).top;
              const double headerVisualHeight =
                  64.0; // Altura física do AppTopHeader (14 padding top + 38 avatar/botão + 12 padding bottom)
              const double headerClearance =
                  0.0; // Respiro visual elegante entre a borda do header e o início do conteúdo da Home
              final double topPadding =
                  topSafeArea + headerVisualHeight + headerClearance;
              final bottomInset = MediaQuery.paddingOf(context).bottom;
              // 68dp navbar + 16dp margin inferior + área segura do sistemaS
              const double navBarHeight = 68 + 16;
              final double bottomPadding = navBarHeight + bottomInset + 16;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(0, topPadding, 0, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeGreetingHeader(
                      displayName: _displayName,
                      role: _user?.role,
                      onQrTap: () => context.push('/qr-scanner'),
                    ),
                    const SizedBox(height: 28),

                    // Bloco Dinâmico Reativo
                    StreamBuilder<List<Member>>(
                      stream: _membersStream,
                      builder: (context, memberSnapshot) {
                        if (memberSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            _isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        final members = (memberSnapshot.data ?? [])
                            .whereType<Member>()
                            .toList();
                        final selectedMember = _getSelectedMember(members);

                        return StreamBuilder<List<CardRequest>>(
                          stream: _cardRequestsStream,
                          builder: (context, requestSnapshot) {
                            final requests = (requestSnapshot.data ?? [])
                                .whereType<CardRequest>()
                                .toList();

                            return StreamBuilder<List<DigitalCard>>(
                              stream: _digitalCardsStream,
                              builder: (context, cardSnapshot) {
                                final digitalCards = (cardSnapshot.data ?? [])
                                    .whereType<DigitalCard>()
                                    .toList();

                                return HomeDynamicContent(
                                  members: members,
                                  requests: requests,
                                  digitalCards: digitalCards,
                                  selectedMember: selectedMember,
                                  paletteSeed: _user?.id,
                                  onDetailsTap: () => widget.onNavigate(1),
                                  onMemberSelected: (member) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedMemberId = member.id;
                                      });
                                    }
                                  },
                                  onRequestCard: _handleRequestCard,
                                  onOpenDigitalCard: () => widget.onNavigate(1),
                                  onEditPendingRequest: (member, request) =>
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddMemberPage(
                                            member: member,
                                            request: request,
                                          ),
                                        ),
                                      ).then((_) => _loadData()),
                                  onRequestRenewal: _handleRenewalRequest,
                                  onSupportTap: _handleSupportTap,
                                  onOpenMural: () => widget.onNavigate(1),
                                  onViewAllMembers: () => widget.onNavigate(
                                    1,
                                  ), // Redireciona para aba Carteirinhas
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    HomeQuickAccessSection(
                      onRequestCard: _handleRequestCard,
                      onSupportTap: _handleSupportTap,
                    ),

                    const SizedBox(height: 24),
                    const HomeServicesSection(),
                    const SizedBox(height: 24),
                    HomeInformationSection(
                      onSupportTap: _handleSupportTap,
                      onAboutTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutConecteaView(),
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
                      onProjectsActionsTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProjectsActionsView(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const HomeBannersSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
