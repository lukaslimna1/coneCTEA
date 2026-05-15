import 'package:flutter/material.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/features/home/widgets/solicitacoes/home_ongoing_request_section.dart';
import 'package:conectea/features/home/widgets/membros/home_members_section.dart';
import 'package:conectea/features/home/widgets/carteirinha/home_digital_card_section.dart';
import 'package:conectea/features/home/widgets/acesso_rapido/home_quick_access_section.dart';

class HomeDynamicContent extends StatelessWidget {
  final List<Member> members;
  final List<CardRequest> requests;
  final List<DigitalCard> digitalCards;
  final Member? selectedMember;
  final VoidCallback onDetailsTap;
  final ValueChanged<Member> onMemberSelected;
  final VoidCallback onRequestCard;
  final VoidCallback onOpenDigitalCard;
  final void Function(Member member, CardRequest? request) onEditPendingRequest;
  final void Function(String requestId) onRequestRenewal;
  final VoidCallback onSupportTap;
  final VoidCallback onOpenMural;
  final VoidCallback onViewAllMembers;
  final String? paletteSeed;

  const HomeDynamicContent({
    super.key,
    required this.members,
    required this.requests,
    required this.digitalCards,
    required this.selectedMember,
    required this.onDetailsTap,
    required this.onMemberSelected,
    required this.onRequestCard,
    required this.onOpenDigitalCard,
    required this.onEditPendingRequest,
    required this.onRequestRenewal,
    required this.onSupportTap,
    required this.onOpenMural,
    required this.onViewAllMembers,
    this.paletteSeed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeOngoingRequestSection(
          requests: requests,
          onDetailsTap: onDetailsTap,
        ),
        const SizedBox(height: 12),
        HomeMembersSection(
          members: members,
          selectedMember: selectedMember,
          onViewAllTap: onViewAllMembers,
          onMemberSelected: onMemberSelected,
          paletteSeed: paletteSeed,
        ),
        const SizedBox(height: 24),
        HomeDigitalCardSection(
          members: members,
          requests: requests,
          digitalCards: digitalCards,
          selectedMember: selectedMember,
          onRequestCard: onRequestCard,
          onOpenDigitalCard: onOpenDigitalCard,
          onEditPendingRequest: onEditPendingRequest,
          onRequestRenewal: onRequestRenewal,
          onSupportTap: onSupportTap,
        ),
        const SizedBox(height: 32),
        HomeQuickAccessSection(
          onOpenDigitalCard: onOpenDigitalCard,
          onRequestCard: onRequestCard,
          onOpenMural: onOpenMural,
        ),
      ],
    );
  }
}
