import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
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

  List<Member> _members = [];
  Map<String, DigitalCard> _cardsByMemberId = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      final members = await _databaseService.getMembers(userId);
      final Map<String, DigitalCard> cards = {};

      for (final member in members) {
        // Find a card for this member.
        // Note: Assume getDigitalCard(memberId) exists, or we fetch all and filter.
        // If not available, we can mock it based on member if they are active
        if (member.status.toLowerCase() == 'ativa' ||
            member.status.toLowerCase() == 'active') {
          // Fallback to mock for now, but in real app we fetch it
          cards[member.id] = DigitalCard(
            id: 'mock_${member.id}',
            memberId: member.id,
            userId: userId,
            cardNumber: '0000 0000 0000',
            status: 'active',
            validUntil: DateTime.now().add(const Duration(days: 365)),
            issuedAt: DateTime.now(),
            frontData: {},
            backData: {},
            qrValidationUrl: 'https://conectea.com/validate/${member.id}',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }

      if (mounted) {
        setState(() {
          _members = members;
          _cardsByMemberId = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_members.isEmpty) {
      return _buildEmptyState();
    }

    final activeMembers = _members
        .where((m) => _cardsByMemberId.containsKey(m.id))
        .toList();

    if (activeMembers.isEmpty) {
      return _buildPendingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minhas Carteirinhas',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em uma carteirinha para visualizar e validar.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ...activeMembers.map((member) {
            final card = _cardsByMemberId[member.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FullScreenCardPage(
                        members: activeMembers,
                        cardsByMemberId: _cardsByMemberId,
                        initialMemberIndex: activeMembers.indexOf(member),
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                },
                child: Hero(
                  tag: 'card_${member.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: DigitalCardWidget(
                      card: card,
                      member: member,
                      showBack: false,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_rounded, size: 80, color: AppColors.borderLight),
            const SizedBox(height: 24),
            Text(
              'Nenhuma carteirinha encontrada',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Você precisa cadastrar um membro para solicitar uma carteirinha.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions_rounded,
              size: 80,
              color: AppColors.alertOrange.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Carteirinhas em análise',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suas solicitações estão sendo analisadas. Assim que aprovadas, as carteirinhas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
