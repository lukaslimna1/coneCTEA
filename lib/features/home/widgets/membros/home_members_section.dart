import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/constants/colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: '${members.length} membros vinculados',
          subtitle: 'Selecione um membro.',
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
              // Localiza request deste membro para status unificado
              final memberRequest = requests
                  .where((r) => r.memberId == member.id)
                  .toList()
                  .firstOrNull;

              final isSelected = member.id == selectedMemberId;
              final initials = member.initials;
              final statusInfo = HomeStatusHelper.memberStatus(
                member.status,
                memberRequest: memberRequest,
              );

              return GestureDetector(
                onTap: () => onMemberSelected(member.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  width: 175, // Largura fixa para estabilidade
                  constraints: const BoxConstraints(
                    minHeight:
                        64, // Altura mínima para consistência e segurança sob zoom
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      DsAvatar(
                        initials: initials,
                        size: 34,
                        isInactive: !isSelected,
                        paletteSeed: paletteSeed,
                        showGlow: isSelected,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              member.name.split(' ').first,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cardTitle,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: statusInfo.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusInfo.color.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    statusInfo.shortLabel.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: statusInfo.color.withValues(
                                        alpha: 0.9,
                                      ),
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
            }),
          ),
        ),
      ],
    );
  }
}
