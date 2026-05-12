import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';

class CardsPendingState extends StatelessWidget {
  final List<Member> pendingMembers;
  final List<CardRequest> requests;
  final String Function(String) statusLabelBuilder;

  const CardsPendingState({
    super.key,
    required this.pendingMembers,
    required this.requests,
    required this.statusLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.cardSubtitle,
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.alertOrange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.clockClockwise,
              size: 72,
              color: AppColors.alertOrange,
            ),
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
        ...pendingMembers.map((m) {
          final req = requests.firstWhere(
            (r) => r.memberId == m.id,
            orElse: () => CardRequest(
              id: '',
              userId: '',
              memberId: m.id,
              type: '',
              status: 'waiting_approval',
              protocol: '',
              adminNotes: '',
              driveFolderUrl: '',
              documentUrl: '',
              medicalReportUrl: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
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
                        statusLabelBuilder(req.status),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.cardSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  PhosphorIconsRegular.clock,
                  color: AppColors.alertOrange,
                  size: 20,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
