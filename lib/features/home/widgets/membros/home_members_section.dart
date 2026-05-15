import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/premium/conectea_avatar.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/features/home/widgets/comum/home_section_header.dart';
import 'package:conectea/features/home/utils/home_status_helper.dart';

class HomeMembersSection extends StatelessWidget {
  final List<Member> members;
  final Member? selectedMember;
  final VoidCallback onViewAllTap;
  final ValueChanged<Member> onMemberSelected;
  final String? paletteSeed;

  const HomeMembersSection({
    super.key,
    required this.members,
    required this.selectedMember,
    required this.onViewAllTap,
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
          subtitle: 'Selecione um membro para visualizar.',
          actionLabel: 'Ver todos',
          onActionTap: onViewAllTap,
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
              final isSelected = member.id == selectedMember?.id;
              final initials = member.initials;
              final statusInfo = HomeStatusHelper.memberStatus(member.status);

              return GestureDetector(
                onTap: () => onMemberSelected(member),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ConecteaAvatar(
                        initials: initials,
                        size: 38,
                        isInactive: !isSelected,
                        paletteSeed: paletteSeed,
                        showGlow: isSelected,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name.split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusInfo.isActive
                                      ? AppColors.statusGreen
                                      : AppColors.alertOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusInfo.shortLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusInfo.isActive
                                      ? AppColors.statusGreen
                                      : AppColors.alertOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
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
