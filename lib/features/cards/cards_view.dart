import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_qr_button.dart';
import 'package:conectea/features/cards/widgets/carteirinha_digital/digital_card_widget.dart';
import 'package:conectea/features/cards/full_screen_card_page.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/account/profile/edit_profile_view.dart';
import 'package:conectea/features/cards/widgets/tela_carteirinhas/cards_member_selector.dart';
import 'package:conectea/features/cards/widgets/tela_carteirinhas/cards_pending_state.dart';
import 'package:conectea/features/cards/widgets/tela_carteirinhas/cards_empty_state.dart';
import 'package:conectea/features/cards/widgets/tela_carteirinhas/cards_details_section.dart';
import 'package:conectea/features/cards/widgets/tela_carteirinhas/cards_error_state.dart';
import 'package:conectea/features/requests/add_member_page.dart';

class CardsView extends StatefulWidget {
  const CardsView({super.key});

  @override
  State<CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  int _selectedMemberIndex = 0;
  bool _showBack = false;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final user = await _databaseService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _user = user;
          });
        }
      }
    } catch (e) {
      // Falha silenciosa ou log
    }
  }

  bool get _isProfileComplete {
    if (_user == null) return false;
    return _user!.cpf.isNotEmpty &&
        _user!.phone.isNotEmpty &&
        (_user!.city?.isNotEmpty ?? false) &&
        (_user!.state?.isNotEmpty ?? false);
  }

  void _handleRequestNewCard() {
    if (!_isProfileComplete) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('🎉 Quase lá!'),
          content: const Text(
            'Para cadastrar um novo dependente, seu perfil de responsável precisa estar completo com CPF, Telefone, Cidade e Estado.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileView()),
                  );
                  if (result == true) {
                    _loadProfile();
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMemberPage()),
    ).then((_) {
      // Recarregar perfil se necessário, embora os membros sejam via stream
      _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding = topSafeArea + headerVisualHeight + headerClearance;

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      return const Center(child: Text('Por favor, faça login'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: StreamBuilder<List<Member>>(
          stream: _databaseService.membersStream(userId),
          builder: (context, memberSnap) {
            return StreamBuilder<List<DigitalCard>>(
              stream: _databaseService.digitalCardsStream(userId),
              builder: (ctx, cardSnap) {
                return StreamBuilder<List<CardRequest>>(
                  stream: _databaseService.cardRequestsStream(userId),
                  builder: (ctx2, requestSnap) {
                    // Verificação de Erros nas Streams
                    if (memberSnap.hasError || cardSnap.hasError || requestSnap.hasError) {
                      return CardsErrorState(
                        onRetry: () => setState(() {}),
                      );
                    }

                    if (memberSnap.connectionState == ConnectionState.waiting ||
                        cardSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final members = memberSnap.data ?? [];
                    final allCards = cardSnap.data ?? [];
                    final requests = requestSnap.data ?? [];

                    // Mapa: member_id → DigitalCard (somente status == 'active')
                    final Map<String, DigitalCard> activeCardsMap = {};
                    for (final card in allCards) {
                      if (card.isActive) {
                        activeCardsMap[card.memberId] = card;
                      }
                    }

                    // Membros com carteirinha ATIVA
                    final activeMembers = members
                        .where((m) => activeCardsMap.containsKey(m.id))
                        .toList();

                    // Membros SEM carteirinha ativa (pendentes)
                    final pendingMembers = members
                        .where((m) => !activeCardsMap.containsKey(m.id))
                        .toList();

                    // Corrigir índice selecionado se necessário
                    final selIdx = _selectedMemberIndex.clamp(
                      0,
                      activeMembers.isEmpty ? 0 : activeMembers.length - 1,
                    );

                    if (members.isEmpty) {
                      return CardsEmptyState(onAddMember: _handleRequestNewCard);
                    }

                    if (activeMembers.isEmpty) {
                      return CardsPendingState(
                        pendingMembers: pendingMembers,
                        requests: requests,
                        statusLabelBuilder: _getStatusLabel,
                      );
                    }

                    final selectedMember = activeMembers[selIdx];
                    final selectedCard = activeCardsMap[selectedMember.id]!;

                    return ListView(
                      padding: EdgeInsets.fromLTRB(0, topPadding, 0, 32),
                      children: [
                        // Header com Ícone QR
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Carteirinhas',
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.cardTitle,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Gerencie suas identificações e dos\nmembros da sua família.',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.cardSubtitle
                                            .withValues(alpha: 0.8),
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PremiumQrButton(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Novo Seletor Horizontal de Membros (padrão Home)
                        CardsMemberSelector(
                          members: members,
                          activeCardsMap: activeCardsMap,
                          selectedIdx: selIdx,
                          requests: requests,
                          paletteSeed: _user?.id,
                          onMemberSelected: (idx) {
                            setState(() {
                              _selectedMemberIndex = idx;
                              _showBack = false;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Título da Seção Carteirinha
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              const Icon(
                                PhosphorIconsRegular.cards,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SUA CARTEIRINHA DIGITAL',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cardMutedText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Visualização da Carteirinha
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GestureDetector(
                            onTap: () => _openFullScreen(
                              selectedMember,
                              activeMembers,
                              activeCardsMap,
                            ),
                            child: Hero(
                              tag: 'card_${selectedMember.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: DigitalCardWidget(
                                  card: selectedCard,
                                  member: selectedMember,
                                  showBack: _showBack,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Detalhes e Ações da Carteirinha
                        CardsDetailsSection(
                          validUntil: selectedCard.validUntil,
                          showBack: _showBack,
                          onToggleBack: () =>
                              setState(() => _showBack = !_showBack),
                          onOpenFullScreen: () => _openFullScreen(
                            selectedMember,
                            activeMembers,
                            activeCardsMap,
                          ),
                          onAddDependent: _handleRequestNewCard,
                        ),

                        const SizedBox(height: 40),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }




  void _openFullScreen(
    Member member,
    List<Member> activeMembers,
    Map<String, DigitalCard> cardsMap,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenCardPage(
          members: activeMembers,
          cardsByMemberId: cardsMap,
          initialMemberIndex: activeMembers.indexOf(member),
        ),
        fullscreenDialog: true,
      ),
    );
  }



  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Carteirinha ativa';
      case 'under_review':
      case 'waiting_approval':
        return 'Em análise pela equipe';
      case 'waiting_docs':
        return 'Aguardando documentação';
      case 'reviewing_data':
        return 'Revisão de dados';
      case 'rejected':
        return 'Solicitação reprovada';
      case 'suspended':
        return 'Carteirinha suspensa';
      default:
        return 'Em análise';
    }
  }
}
