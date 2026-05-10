import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/colors.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import '../../models/card_request.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../core/widgets/premium/premium_button.dart';
import '../../core/widgets/premium/premium_card.dart';
import '../../core/widgets/premium/app_background.dart';
import 'package:go_router/go_router.dart';
import 'widgets/digital_card_widget.dart';
import 'full_screen_card_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.id;
    if (userId == null) return const Center(child: Text('Por favor, faça login'));

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
                    if (memberSnap.connectionState == ConnectionState.waiting ||
                        cardSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
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
                      return _buildEmptyState();
                    }

                    if (activeMembers.isEmpty) {
                      return _buildPendingState(pendingMembers, requests);
                    }

                    final selectedMember = activeMembers[selIdx];
                    final selectedCard = activeCardsMap[selectedMember.id]!;

                    return RefreshIndicator(
                      onRefresh: () async {},
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 100, 0, 32),
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
                                          color: AppColors.cardSubtitle.withValues(alpha: 0.8),
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/qr-scanner'),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.all(16), // Increased from 14
                                    decoration: BoxDecoration(
                                      color: const Color(0xA60F172A), // Dark Glass
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0x3D94A3B8), // Glass border
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      PhosphorIconsRegular.qrCode,
                                      color: Color(0xFFF8FAFC),
                                      size: 28,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                          const SizedBox(height: 16),
                          
                          // Novo Seletor Horizontal de Membros (Padão Home)
                          _buildMembersSelector(members, activeCardsMap, selIdx, requests),

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
                                  selectedMember, activeMembers, activeCardsMap),
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

                          // Datas e Status
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildInfoBlock(
                                    icon: PhosphorIconsRegular.calendarCheck,
                                    label: 'Válida até',
                                    value: DateFormat('dd/MM/yyyy').format(selectedCard.validUntil),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoBlock(
                                    icon: PhosphorIconsRegular.checkCircle,
                                    label: 'Situação',
                                    value: 'ATIVA',
                                    isStatus: true,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Botões de Ação
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: PremiumButton(
                                    text: 'Ver carteirinha',
                                    variant: PremiumButtonVariant.primary,
                                    icon: PhosphorIconsRegular.identificationCard,
                                    onPressed: () => _openFullScreen(
                                        selectedMember, activeMembers, activeCardsMap),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PremiumButton(
                                    text: _showBack ? 'Ver frente' : 'Ver verso',
                                    variant: PremiumButtonVariant.outline,
                                    textColor: Colors.white,
                                    icon: PhosphorIconsRegular.arrowsClockwise,
                                    onPressed: () => setState(() => _showBack = !_showBack),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildMembersSelector(
    List<Member> members,
    Map<String, DigitalCard> activeCardsMap,
    int selectedIdx,
    List<CardRequest> requests,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${members.length} MEMBROS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cardMutedText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/member-selection'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Increased from 16/10
                      decoration: BoxDecoration(
                        color: const Color(0x2E22D3EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsRegular.plusCircle,
                            size: 16,
                            color: Color(0xFF22D3EE),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Solicitar Nova',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(members.length, (index) {
                  final member = members[index];
                  final hasActiveCard = activeCardsMap.containsKey(member.id);
                  final request = requests.where((r) => r.memberId == member.id).firstOrNull;
                  
                  final activeMembers = members.where((m) => activeCardsMap.containsKey(m.id)).toList();
                  final isSelected = hasActiveCard && activeMembers.indexOf(member) == selectedIdx;

                  return GestureDetector(
                    onTap: () {
                      if (hasActiveCard) {
                        final idx = activeMembers.indexOf(member);
                        setState(() {
                          _selectedMemberIndex = idx;
                          _showBack = false;
                        });
                      } else {
                        String message = '${member.name} não possui carteirinha ativa.';
                        if (request != null) {
                          message = 'Carteirinha de ${member.name} está em análise.';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: AppColors.alertOrange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Increased padding
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : const Color(0xA60F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : const Color(0x2E94A3B8),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  blurRadius: 0,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.premiumGradient : null,
                              color: isSelected ? null : const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1) : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              member.initials,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                member.name.split(' ').first,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.cardSubtitle,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  height: 2,
                                  width: 12,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusGreen,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                )
                              else if (request != null && !hasActiveCard)
                                Text(
                                  'Em análise',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.alertOrange,
                                  ),
                                ),
                            ],
                          ),
                          if (hasActiveCard && !isSelected)
                             Padding(
                               padding: const EdgeInsets.only(left: 8),
                               child: Icon(
                                 PhosphorIconsFill.checkCircle,
                                 size: 14,
                                 color: AppColors.statusGreen.withValues(alpha: 0.5),
                                ),
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

  Widget _buildInfoBlock({
    required IconData icon,
    required String label,
    required String value,
    bool isStatus = false,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isStatus ? AppColors.statusGreen : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.cardSubtitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isStatus ? AppColors.statusGreen : AppColors.cardTitle,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildPendingState(List<Member> pending, List<CardRequest> requests) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Carteirinhas',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gerencie as carteirinhas vinculadas à sua conta.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.cardSubtitle),
          ),
          const SizedBox(height: 48),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.alertOrange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.clockClockwise,
                  size: 72, color: AppColors.alertOrange),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Solicitação em Andamento',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua solicitação está sendo verificada.\nEm breve sua carteirinha aparecerá aqui!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.cardSubtitle,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Solicitações em Andamento',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 12),
          ...pending.map((m) {
            final req = requests.firstWhere(
              (r) => r.memberId == m.id,
              orElse: () => CardRequest(
                id: '', userId: '', memberId: m.id, type: '', status: 'waiting_approval',
                protocol: '', adminNotes: '', driveFolderUrl: '', documentUrl: '',
                medicalReportUrl: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
              ),
            );
            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.alertOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m.initials,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.cardTitle,
                          ),
                        ),
                        Text(
                          _getStatusLabel(req.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.cardSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(PhosphorIconsRegular.clock,
                      color: AppColors.alertOrange, size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.identificationCard, size: 72, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma carteira emitida',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cadastre um membro e envie a documentação\npara receber sua identificação digital.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.cardSubtitle,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active': return 'Carteirinha ativa';
      case 'waiting_approval': return 'Em análise pela equipe';
      case 'waiting_docs': return 'Aguardando documentação';
      case 'reviewing_data': return 'Revisão de dados';
      case 'rejected': return 'Solicitação reprovada';
      case 'suspended': return 'Carteirinha suspensa';
      default: return 'Em análise';
    }
  }
}


