import 'package:flutter/material.dart';
import '../../../../core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';

class CardsMemberSelector extends StatelessWidget {
  final List<Member> members;
  final Map<String, DigitalCard> activeCardsMap;
  final int selectedIdx;
  final List<CardRequest> requests;
  final Function(int) onMemberSelected;
  final String? paletteSeed;

  const CardsMemberSelector({
    super.key,
    required this.members,
    required this.activeCardsMap,
    required this.selectedIdx,
    required this.requests,
    required this.onMemberSelected,
    this.paletteSeed,
  });

  @override
  Widget build(BuildContext context) {
    final items = members.map((member) {
      final request = requests
          .where((r) => r.memberId == member.id)
          .firstOrNull;

      final String status = HomeStatusHelper.getEffectiveStatus(
        memberStatus: member.status,
        memberRequest: request,
      );

      final tokens = DsTokenStatus.fromStatus(status);
      final Color statusColor = tokens.primary;

      String shortLabel = 'Pendente';
      switch (tokens.statusKey) {
        case 'active':
          shortLabel = 'Ativa';
          break;
        case 'waiting_docs':
          shortLabel = 'Documentos';
          break;
        case 'reviewing_data':
          shortLabel = 'Revisar';
          break;
        case 'waiting_approval':
          shortLabel = 'Análise';
          break;
        case 'renewing':
          shortLabel = 'Renovação';
          break;
        case 'expired':
          shortLabel = 'Vencida';
          break;
        case 'rejected':
          shortLabel = 'Reprovada';
          break;
        case 'suspended':
          shortLabel = 'Suspensa';
          break;
        default:
          shortLabel = tokens.label;
      }

      return DsMembroCarrosselItem(
        id: member.id,
        name: member.name.split(' ').first,
        initials: member.initials,
        statusLabel: shortLabel,
        statusColor: statusColor,
        paletteSeed: paletteSeed,
      );
    }).toList();

    final String currentSelectedId =
        selectedIdx >= 0 && selectedIdx < members.length
        ? members[selectedIdx].id
        : '';

    return DsMembrosCarrossel(
      items: items,
      selectedId: currentSelectedId,
      onItemSelected: (id) {
        final index = members.indexWhere((m) => m.id == id);
        if (index != -1) {
          onMemberSelected(index);
        }
      },
      sectionTitle: '${members.length} membros',
    );
  }
}
