import 'package:flutter/material.dart';
import '../../../../core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/features/home/widgets/comum/home_section_header.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';

class HomeMembersSection extends StatelessWidget {
  final List<Member> members;
  final List<CardRequest> requests;
  final String? selectedMemberId;
  final Function(String) onMemberSelected;
  final String? paletteSeed;

  const HomeMembersSection({
    super.key,
    required this.members,
    required this.requests,
    required this.selectedMemberId,
    required this.onMemberSelected,
    this.paletteSeed,
  });

  @override
  Widget build(BuildContext context) {
    final items = members.map((member) {
      final memberRequest = requests
          .where((r) => r.memberId == member.id)
          .toList()
          .firstOrNull;

      final statusInfo = HomeStatusHelper.memberStatus(
        member.status,
        memberRequest: memberRequest,
      );

      final status = HomeStatusHelper.getEffectiveStatus(
        memberStatus: member.status,
        memberRequest: memberRequest,
      );
      final token = DsTokenStatus.fromStatus(status);

      String displayLabel;
      switch (token.statusKey) {
        case 'waiting_docs':
          displayLabel = 'Documentos';
          break;
        case 'active':
          displayLabel = 'Ativa';
          break;
        case 'reviewing_data':
          displayLabel = 'Revisar';
          break;
        case 'waiting_approval':
          displayLabel = 'Análise';
          break;
        case 'renewing':
          displayLabel = 'Renovação';
          break;
        default:
          displayLabel = statusInfo.shortLabel;
      }

      return DsMembroCarrosselItem(
        id: member.id,
        name: member.name.split(' ').first,
        initials: member.initials,
        statusLabel: displayLabel.toUpperCase(),
        statusColor: statusInfo.color,
        paletteSeed: paletteSeed,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '${members.length} membros vinculados',
          subtitle: 'Selecione um membro.',
        ),
        const SizedBox(height: 12),
        DsMembrosCarrossel(
          items: items,
          selectedId: selectedMemberId ?? '',
          onItemSelected: onMemberSelected,
        ),
      ],
    );
  }
}
