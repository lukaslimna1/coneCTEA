import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:conectea/features/carteirinhas/widgets/digital/digital_card_widget.dart';
import 'package:conectea/features/carteirinhas/full_screen_card_page.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/conta/perfil/legado/edit_profile_view.dart';
import 'package:conectea/features/carteirinhas/widgets/tela/cards_member_selector.dart';
import 'package:conectea/features/carteirinhas/widgets/tela/cards_empty_state.dart';
import 'package:conectea/features/carteirinhas/widgets/tela/cards_details_section.dart';
import 'package:conectea/features/carteirinhas/widgets/tela/cards_error_state.dart';
import 'package:conectea/features/carteirinhas/solicitacao/add_member_page.dart';
import 'package:conectea/features/carteirinhas/solicitacao/requests_view.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_beneficiary_choice_sheet.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/features/conta/suporte/support_view.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';

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
  bool _showHistory = false;

  Stream<List<Member>>? _membersStream;
  Stream<List<DigitalCard>>? _digitalCardsStream;
  Stream<List<CardRequest>>? _cardRequestsStream;

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
        _membersStream = _databaseService.membersStream(userId);
        _digitalCardsStream = _databaseService.digitalCardsStream(userId);
        _cardRequestsStream = _databaseService.cardRequestsStream(userId);

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

  void _handleRequestNewCard() async {
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

    final isForTitular = await RequestBeneficiaryChoiceSheet.show(context);
    if (isForTitular == null) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberPage(prefillForTitular: isForTitular),
      ),
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
    final double topPadding =
        topSafeArea + headerVisualHeight + headerClearance;

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      return const Center(child: Text('Por favor, faça login'));
    }

    if (_showHistory) {
      return RequestsView(onBack: () => setState(() => _showHistory = false));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: StreamBuilder<List<Member>>(
          stream: _membersStream,
          builder: (context, memberSnap) {
            return StreamBuilder<List<DigitalCard>>(
              stream: _digitalCardsStream,
              builder: (ctx, cardSnap) {
                return StreamBuilder<List<CardRequest>>(
                  stream: _cardRequestsStream,
                  builder: (ctx2, requestSnap) {
                    // Verificação de Erros nas Streams
                    if (memberSnap.hasError ||
                        cardSnap.hasError ||
                        requestSnap.hasError) {
                      return CardsErrorState(onRetry: _loadProfile);
                    }

                    if (memberSnap.connectionState == ConnectionState.waiting ||
                        cardSnap.connectionState == ConnectionState.waiting ||
                        requestSnap.connectionState ==
                            ConnectionState.waiting) {
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

                    // Membros com carteirinha ATIVA (necessário para a FullScreenCardPage e navegação em carrossel)
                    final activeMembers = members
                        .where((m) => activeCardsMap.containsKey(m.id))
                        .toList();

                    if (members.isEmpty) {
                      return CardsEmptyState(
                        onAddMember: _handleRequestNewCard,
                      );
                    }

                    // Corrigir índice selecionado com base no tamanho global de members
                    final selIdx = _selectedMemberIndex.clamp(
                      0,
                      members.isEmpty ? 0 : members.length - 1,
                    );

                    final selectedMember = members[selIdx];

                    // Obter primeiro cartão (ativo ou não) associado ao membro selecionado para o preview
                    DigitalCard? selectedCard;
                    try {
                      selectedCard = allCards.firstWhere(
                        (c) => c.memberId == selectedMember.id,
                      );
                    } catch (_) {
                      selectedCard = null;
                    }

                    // Obter request mais relevante (mais recente) para o membro selecionado
                    final memberRequests =
                        requests
                            .where((r) => r.memberId == selectedMember.id)
                            .toList()
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final selectedRequest = memberRequests.isNotEmpty
                        ? memberRequests.first
                        : null;

                    // Obter informações estritas de status usando o HomeStatusHelper
                    final selectedStatusInfo =
                        HomeStatusHelper.digitalCardStatus(
                          selectedMember.status,
                          memberRequest: selectedRequest,
                        );

                    // Obter o status efetivo do preview do cartão (normalizado via DsTokenStatus)
                    final rawEffectiveStatus =
                        HomeStatusHelper.getEffectiveStatus(
                          memberStatus: selectedMember.status,
                          memberRequest: selectedRequest,
                        );
                    final effectiveStatus = DsTokenStatus.fromStatus(
                      rawEffectiveStatus,
                    ).statusKey;

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

                        // CTAs Superiores lado a lado
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: DsBotao(
                                  label: 'Solicitar',
                                  variante: DsBotaoVariante.acao,
                                  token: DsCores.solicitacao,
                                  icon: PhosphorIconsRegular.userPlus,
                                  onPressed: _handleRequestNewCard,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DsBotao(
                                  label: 'Histórico',
                                  variante: DsBotaoVariante.secundario,
                                  icon: PhosphorIconsRegular.listDashes,
                                  onPressed: () {
                                    setState(() => _showHistory = true);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

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
                          child: DsMiniCarteiraPreview(
                            status: effectiveStatus,
                            isPending: !selectedStatusInfo.isActive,
                            showStatusSeal: !selectedStatusInfo.isActive,
                            dimWhenPending: !selectedStatusInfo.isActive,
                            statusSealLabelOverride:
                                effectiveStatus == 'waiting_docs'
                                ? 'Aguardando documentos'
                                : null,
                            onTap: null,
                            cardWidget: Hero(
                              tag: 'card_${selectedMember.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: DigitalCardWidget(
                                  card: selectedCard,
                                  member: selectedMember,
                                  showBack: _showBack,
                                  statusOverride: effectiveStatus,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Detalhes e Ações da Carteirinha para Membro Ativo
                        if (selectedStatusInfo.isActive && selectedCard != null)
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
                          ),

                        // Detalhes e Ações para Membro Pendente/Não-Ativo (Layout Refinado Premium)
                        if (!selectedStatusInfo.isActive) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Builder(
                              builder: (context) {
                                final status = effectiveStatus;
                                final adminNotes =
                                    selectedRequest?.adminNotes ?? '';
                                final protocol =
                                    selectedRequest?.protocol ?? '----';
                                final dateStr =
                                    selectedRequest?.expiresAt != null
                                    ? ConecteaDateTimeHelper.formatProjectDateShort(
                                        selectedRequest!.expiresAt!,
                                      )
                                    : 'Sob análise';

                                final statusColor = DsTokenStatus.fromStatus(
                                  status,
                                ).primary;

                                String block1Label = 'Requerimento';
                                String block1Value = protocol;
                                IconData block1Icon = PhosphorIconsRegular.copy;

                                String block2Label = 'Prazo estimado';
                                String block2Value = '5 dias úteis';
                                IconData block2Icon =
                                    PhosphorIconsRegular.clock;

                                Widget? primaryButton;
                                Widget? secondaryButton;

                                switch (status) {
                                  case 'waiting_docs':
                                    block2Label = 'Data limite';
                                    block2Value = dateStr;
                                    block2Icon = PhosphorIconsRegular.calendar;

                                    secondaryButton =
                                        _buildStatusSecondaryButton(
                                          context: context,
                                          label: 'Ver documentos solicitados',
                                          icon: Icons.help_outline_rounded,
                                          statusColor: selectedStatusInfo.color,
                                          onTap: () => DsStatusDialog.show(
                                            context,
                                            statusInfo: selectedStatusInfo,
                                            notes: adminNotes,
                                          ),
                                        );

                                    primaryButton = _buildStatusPrimaryButton(
                                      context: context,
                                      label: 'Enviar Documentos',
                                      icon: Icons.edit_document,
                                      statusColor: selectedStatusInfo.color,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddMemberPage(
                                              member: selectedMember,
                                              request: selectedRequest,
                                            ),
                                          ),
                                        ).then((_) => _loadProfile());
                                      },
                                    );
                                    break;

                                  case 'reviewing_data':
                                    block2Label = 'Data limite';
                                    block2Value = dateStr;
                                    block2Icon = PhosphorIconsRegular.calendar;

                                    secondaryButton =
                                        _buildStatusSecondaryButton(
                                          context: context,
                                          label: 'Ver dados para revisão',
                                          icon: Icons.help_outline_rounded,
                                          statusColor: selectedStatusInfo.color,
                                          onTap: () => DsStatusDialog.show(
                                            context,
                                            statusInfo: selectedStatusInfo,
                                            notes: adminNotes,
                                          ),
                                        );

                                    primaryButton = _buildStatusPrimaryButton(
                                      context: context,
                                      label: 'Revisar Dados',
                                      icon: Icons.edit_document,
                                      statusColor: selectedStatusInfo.color,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddMemberPage(
                                              member: selectedMember,
                                              request: selectedRequest,
                                            ),
                                          ),
                                        ).then((_) => _loadProfile());
                                      },
                                    );
                                    break;

                                  case 'waiting_approval':
                                  case 'under_review':
                                  case 'pending':
                                  case 'renewing':
                                    if (status == 'renewing') {
                                      block2Label = 'Prazo de renovação';
                                      block2Value = '5 a 10 dias úteis';

                                      secondaryButton =
                                          _buildStatusSecondaryButton(
                                            context: context,
                                            label: 'Ver prazo de renovação',
                                            icon: Icons.help_outline_rounded,
                                            statusColor:
                                                selectedStatusInfo.color,
                                            onTap: () => DsStatusDialog.show(
                                              context,
                                              statusInfo: selectedStatusInfo,
                                              notes: adminNotes,
                                            ),
                                          );
                                    } else {
                                      secondaryButton =
                                          _buildStatusSecondaryButton(
                                            context: context,
                                            label: 'Ver prazo de aprovação',
                                            icon: Icons.help_outline_rounded,
                                            statusColor:
                                                selectedStatusInfo.color,
                                            onTap: () => DsStatusDialog.show(
                                              context,
                                              statusInfo: selectedStatusInfo,
                                              notes: adminNotes,
                                            ),
                                          );
                                    }
                                    break;

                                  case 'expired':
                                    block2Label = 'Situação';
                                    block2Value = 'EXPIRADA';
                                    block2Icon =
                                        PhosphorIconsRegular.shieldWarning;

                                    if (selectedRequest != null) {
                                      primaryButton = _buildStatusPrimaryButton(
                                        context: context,
                                        label: 'Solicitar Renovação',
                                        icon: Icons.autorenew_rounded,
                                        statusColor: selectedStatusInfo.color,
                                        onTap: () => _handleRenewalRequest(
                                          selectedRequest.id,
                                        ),
                                      );
                                    }
                                    break;

                                  case 'rejected':
                                  case 'suspended':
                                    block2Label = 'Situação';
                                    block2Value = status == 'suspended'
                                        ? 'SUSPENSA'
                                        : 'REPROVADA';
                                    block2Icon =
                                        PhosphorIconsRegular.shieldWarning;

                                    secondaryButton =
                                        _buildStatusSecondaryButton(
                                          context: context,
                                          label: status == 'suspended'
                                              ? 'Ver motivo da suspensão'
                                              : 'Ver justificativa',
                                          icon: Icons.help_outline_rounded,
                                          statusColor: selectedStatusInfo.color,
                                          onTap: () => DsStatusDialog.show(
                                            context,
                                            statusInfo: selectedStatusInfo,
                                            notes: adminNotes,
                                          ),
                                        );

                                    primaryButton = _buildStatusPrimaryButton(
                                      context: context,
                                      label: status == 'suspended'
                                          ? 'PEDIR REVISÃO'
                                          : 'FALAR COM SUPORTE',
                                      icon: Icons.support_agent_rounded,
                                      statusColor: status == 'suspended'
                                          ? selectedStatusInfo.color
                                          : AppColors.errorRed,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SupportView(),
                                          ),
                                        );
                                      },
                                    );
                                    break;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Blocos em linha (Grade horizontal estruturada)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              final cleanProtocol = protocol
                                                  .trim();
                                              final hasProtocol =
                                                  cleanProtocol.isNotEmpty &&
                                                  cleanProtocol != '----' &&
                                                  cleanProtocol !=
                                                      'Não informado' &&
                                                  cleanProtocol != '—';
                                              if (hasProtocol) {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: cleanProtocol,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Requerimento copiado',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            behavior: HitTestBehavior.opaque,
                                            child: PremiumCard(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    block1Icon,
                                                    color: statusColor,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          block1Label,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 10.5,
                                                                color: AppColors
                                                                    .cardSubtitle,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        Text(
                                                          block1Value,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: AppColors
                                                                    .cardTitle,
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
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: PremiumCard(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  block2Icon,
                                                  color: statusColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        block2Label,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 10.5,
                                                              color: AppColors
                                                                  .cardSubtitle,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      Text(
                                                        block2Value,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              block2Label ==
                                                                  'Situação'
                                                              ? statusColor
                                                              : AppColors
                                                                    .cardTitle,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Botões de Ação
                                    if (secondaryButton != null) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: secondaryButton,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (primaryButton != null) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: primaryButton,
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ],

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

  Future<void> _handleRenewalRequest(String requestId) async {
    try {
      await _databaseService.updateCardRequestStatus(
        requestId,
        'renewing',
        adminNotes: 'Pedido de renovação iniciado pelo usuário.',
      );
      await _loadProfile();
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
    }
  }

  Widget _buildStatusSecondaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: statusColor),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17.33),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color statusColor,
    Color? customContentColor,
    required VoidCallback onTap,
  }) {
    final contentColor = customContentColor ?? statusColor;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: contentColor),
        label: Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: contentColor,
            letterSpacing: 1.1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: const Color(0xFF020617).withValues(alpha: 0.85),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17.33),
          ),
        ),
      ),
    );
  }
}
