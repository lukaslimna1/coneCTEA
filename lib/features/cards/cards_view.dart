import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import '../../models/card_request.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
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

    return StreamBuilder<List<Member>>(
      stream: _databaseService.membersStream(userId),
      builder: (context, memberSnap) {
        return StreamBuilder<List<DigitalCard>>(
          stream: _databaseService.digitalCardsStream(userId),
          builder: (context, cardSnap) {
            return StreamBuilder<List<CardRequest>>(
              stream: _databaseService.cardRequestsStream(userId),
              builder: (context, requestSnap) {
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
                    padding: const EdgeInsets.all(0),
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Carteirinhas',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkBlue,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gerencie as carteirinhas vinculadas à sua conta.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Banner de membros
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildMembersBanner(activeMembers.length),
                      ),

                      const SizedBox(height: 16),

                      // Seletor de membros (chips horizontais)
                      if (activeMembers.length > 1) ...[
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: activeMembers.length,
                            itemBuilder: (context, i) {
                              final m = activeMembers[i];
                              final isSelected = i == selIdx;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedMemberIndex = i;
                                  _showBack = false;
                                }),
                                child: Container(
                                  width: 130,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.borderLight,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.2)
                                              : AppColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          m.initials,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              m.name.split(' ').first,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.darkBlue,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColors.statusGreen,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Ativa',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: isSelected
                                                        ? Colors.white.withValues(alpha: 0.8)
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Preview da carteirinha + info lateral
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card preview
                            Expanded(
                              flex: 3,
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

                            const SizedBox(width: 16),

                            // Info lateral
                            Expanded(
                              flex: 2,
                              child: _buildCardInfo(selectedCard),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botões de ação
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildActionButtons(
                            selectedMember, activeMembers, activeCardsMap),
                      ),

                      const SizedBox(height: 32),

                      // Lista: todos os membros da família
                      if (members.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Membros da família',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...members.map((m) => _buildMemberListItem(
                          m,
                          activeCardsMap[m.id],
                          activeMembers,
                          activeCardsMap,
                          requests,
                        )),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMembersBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'membro vinculado' : 'membros vinculados'}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.darkBlue,
                  ),
                ),
                Text(
                  'Selecione uma carteirinha para visualizar.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildCardInfo(DigitalCard card) {
    final dateStr = DateFormat('dd/MM/yyyy').format(card.validUntil);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.statusGreen, size: 32),
              const SizedBox(height: 8),
              Text(
                'Carteirinha\nativa',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Válida até',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    Member member,
    List<Member> activeMembers,
    Map<String, DigitalCard> cardsMap,
  ) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.badge_rounded,
            label: 'Ver carteirinha',
            onTap: () => _openFullScreen(member, activeMembers, cardsMap),
          ),
        ),
        if (activeMembers.length > 1) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              icon: Icons.swap_horiz_rounded,
              label: 'Alternar membro',
              onTap: () => setState(() {
                _selectedMemberIndex =
                    (_selectedMemberIndex + 1) % activeMembers.length;
                _showBack = false;
              }),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: _ActionBtn(
            icon: Icons.flip_rounded,
            label: 'Ver verso',
            onTap: () => setState(() => _showBack = !_showBack),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberListItem(
    Member member,
    DigitalCard? card,
    List<Member> activeMembers,
    Map<String, DigitalCard> cardsMap,
    List<CardRequest> requests,
  ) {
    final hasActiveCard = card != null && card.isActive;
    final request = requests.firstWhere(
      (r) => r.memberId == member.id,
      orElse: () => CardRequest(
        id: '', userId: '', memberId: member.id, type: '', status: 'waiting_approval',
        protocol: '', adminNotes: '', driveFolderUrl: '', documentUrl: '',
        medicalReportUrl: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                member.initials,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  Text(
                    'Membro vinculado',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasActiveCard
                          ? AppColors.statusGreen.withValues(alpha: 0.1)
                          : AppColors.alertOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasActiveCard
                              ? Icons.check_circle_rounded
                              : Icons.access_time_rounded,
                          size: 12,
                          color: hasActiveCard
                              ? AppColors.statusGreen
                              : AppColors.alertOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasActiveCard
                              ? 'Carteirinha ativa'
                              : _getStatusLabel(request.status),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasActiveCard
                                ? AppColors.statusGreen
                                : AppColors.alertOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasActiveCard) ...[
              OutlinedButton(
                onPressed: () => _openFullScreen(member, activeMembers, cardsMap),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(
                  'Abrir',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
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
              color: AppColors.darkBlue,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gerencie as carteirinhas vinculadas à sua conta.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.alertOrange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pending_actions_rounded,
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
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua solicitação está sendo verificada.\nEm breve sua carteirinha aparecerá aqui!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Solicitações em Andamento',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBlue,
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
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
                            color: AppColors.darkBlue,
                          ),
                        ),
                        Text(
                          _getStatusLabel(req.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.access_time_rounded,
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
            child: const Icon(Icons.badge_outlined, size: 72, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma carteira emitida',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cadastre um membro e envie a documentação\npara receber sua identificação digital.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
