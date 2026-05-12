import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/widgets/loading_shimmer.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/features/admin/widgets/admin_request_card.dart';
import 'package:conectea/features/admin/widgets/admin_request_details_sheet.dart';

class AdminRequestsTab extends StatefulWidget {
  final DatabaseService databaseService;

  const AdminRequestsTab({
    super.key,
    required this.databaseService,
  });

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  // 0 = Ativas, 1 = Concluídas, 2 = Restritas
  int _requestFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CardRequest>>(
      stream: widget.databaseService.getAllCardRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        // Filtrar nulos e garantir segurança de tipos
        final List<CardRequest> requests = (snapshot.data ?? []).whereType<CardRequest>().toList();
        
        if (requests.isEmpty) {
          return _buildEmptyState('Nenhuma solicitação encontrada', Icons.inbox_rounded);
        }

        // Sort: pendentes primeiro, depois por data
        final sortedRequests = List<CardRequest>.from(requests)
          ..sort((a, b) {
            final aStatus = a.status;
            final bStatus = b.status;
            if (aStatus == 'waiting_approval' && bStatus != 'waiting_approval') return -1;
            if (aStatus != 'waiting_approval' && bStatus == 'waiting_approval') return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

        final pendingCount = requests.where((r) => ['waiting_approval', 'reviewing_data', 'waiting_docs', 'renewing'].contains(r.status)).length;
        final approvedCount = requests.where((r) => ['active', 'approved'].contains(r.status)).length;
        final restrictedCount = requests.where((r) => ['rejected', 'suspended', 'expired'].contains(r.status)).length;

        // Filtrar a lista com base no _requestFilterIndex
        final filteredRequests = sortedRequests.where((r) {
          if (_requestFilterIndex == 0) {
            return ['waiting_approval', 'reviewing_data', 'waiting_docs', 'renewing'].contains(r.status);
          } else if (_requestFilterIndex == 1) {
            return ['active', 'approved'].contains(r.status);
          } else {
            return ['rejected', 'suspended', 'expired'].contains(r.status);
          }
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildStatsRow(pendingCount, approvedCount, restrictedCount),
            ),
            SliverToBoxAdapter(
              child: _buildRequestFilter(),
            ),
            if (filteredRequests.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: _buildEmptyState(
                    _requestFilterIndex == 0 ? 'Nenhuma solicitação ativa' :
                    _requestFilterIndex == 1 ? 'Nenhuma solicitação concluída' : 'Nenhuma solicitação restrita',
                    Icons.inbox_rounded,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final request = filteredRequests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdminRequestCard(
                          request: request,
                          onTap: () => _showRequestDetails(request),
                        ),
                      );
                    },
                    childCount: filteredRequests.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRequestFilter() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: PremiumCard(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildFilterButton(0, 'Ativas'),
                _buildFilterButton(1, 'Concluídas'),
                _buildFilterButton(2, 'Restritas'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(int index, String label) {
    final isSelected = _requestFilterIndex == index;
    final IconData icon;
    
    switch (index) {
      case 0:
        icon = PhosphorIconsRegular.clock;
        break;
      case 1:
        icon = PhosphorIconsRegular.checkCircle;
        break;
      default:
        icon = PhosphorIconsRegular.shieldWarning;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _requestFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C3AED).withValues(alpha: 0.2) : Colors.transparent, 
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isSelected ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(int pending, int approved, int restricted) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Ativas', pending.toString(), AppColors.alertOrange, Icons.pending_actions_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Concluídas', approved.toString(), AppColors.statusGreen, Icons.check_circle_rounded),
              const SizedBox(width: 12),
              _buildStatCard('Restritas', restricted.toString(), AppColors.adminDanger, Icons.block_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return PremiumCard(
      width: 140,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const LoadingShimmer(width: 50, height: 50, borderRadius: 25),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(width: MediaQuery.of(context).size.width * 0.5, height: 16),
                  const SizedBox(height: 8),
                  LoadingShimmer(width: MediaQuery.of(context).size.width * 0.3, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              Icon(
                PhosphorIconsRegular.tray, 
                size: 48, 
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arraste para baixo para atualizar',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(PhosphorIconsRegular.caretDoubleDown, color: Color(0xFF1B3D71), size: 24),
        ],
      ),
    );
  }

  void _showRequestDetails(CardRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminRequestDetailsSheet(
        request: request,
        databaseService: widget.databaseService,
        onStatusChanged: () {}, // O StreamBuilder atualiza automaticamente
      ),
    );
  }
}
