import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/premium/conectea_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/card_request.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '${members.length} MEMBROS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.cardMutedText,
              letterSpacing: 1.2,
            ),
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
              final request = requests
                  .where((r) => r.memberId == member.id)
                  .firstOrNull;

              final activeMembers = members
                  .where((m) => activeCardsMap.containsKey(m.id))
                  .toList();
              final isSelected =
                  hasActiveCard && activeMembers.indexOf(member) == selectedIdx;

              return GestureDetector(
                onTap: () {
                  if (hasActiveCard) {
                    final idx = activeMembers.indexOf(member);
                    onMemberSelected(idx);
                  } else {
                    String message =
                        '${member.name} não possui carteirinha ativa.';
                    if (request != null) {
                      message =
                          'Carteirinha de ${member.name} está em análise.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: AppColors.alertOrange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
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
                      ConecteaAvatar(
                        initials: member.initials,
                        size: 32,
                        isInactive: !isSelected,
                        paletteSeed: paletteSeed,
                        showGlow: isSelected,
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
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.cardSubtitle,
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
}
