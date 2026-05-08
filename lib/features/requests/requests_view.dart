import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/card_request.dart';
import 'package:intl/intl.dart';
import 'add_member_page.dart';

class RequestsView extends StatelessWidget {
  const RequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final databaseService = DatabaseService();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Por favor, faça login'));
    }

    return StreamBuilder<List<CardRequest>>(
      stream: databaseService.cardRequestsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final requests = snapshot.data ?? [];
        
        // Sorting: ongoing first, then by date
        requests.sort((a, b) {
          final aIsOngoing = _isOngoing(a.status);
          final bIsOngoing = _isOngoing(b.status);
          if (aIsOngoing && !bIsOngoing) return -1;
          if (!aIsOngoing && bIsOngoing) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        final ongoing = requests.where((r) => _isOngoing(r.status)).toList();
        final history = requests.where((r) => !_isOngoing(r.status)).toList();

        return RefreshIndicator(
          onRefresh: () async {},
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minhas Solicitações',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acompanhe o status e histórico de seus pedidos.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (ongoing.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('🚀 Em andamento', ongoing.length),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRequestCard(context, ongoing[index]),
                      ),
                      childCount: ongoing.length,
                    ),
                  ),
                ),
              ],

              if (history.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('📜 Histórico', history.length),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRequestCard(context, history[index], isHistory: true),
                      ),
                      childCount: history.length,
                    ),
                  ),
                ),
              ],

              if (requests.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  bool _isOngoing(String status) {
    final s = status.toLowerCase();
    return s != 'active' && s != 'rejected' && s != 'suspended' && s != 'expired';
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_rounded, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma solicitação',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus pedidos aparecerão aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, CardRequest request, {bool isHistory = false}) {
    final databaseService = DatabaseService();
    final ui = _getStatusUI(request.status);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(request.createdAt);
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (request.status == 'reviewing_data' || request.status == 'waiting_docs') {
              final member = await databaseService.getMember(request.memberId);
              if (member != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMemberPage(
                      member: member,
                      request: request,
                    ),
                  ),
                );
              }
            }
          },
          child: Column(
            children: [
              // Header Gradient Strip
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ui.color.withValues(alpha: 0.8), ui.color],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ui.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_getTypeIcon(request.type), color: ui.color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTypeLabel(request.type),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Protocolo: ${request.protocol}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(ui),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!isHistory) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status atual',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${(ui.progress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: ui.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 8,
                            width: (MediaQuery.of(context).size.width - 88) * ui.progress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [ui.color.withValues(alpha: 0.6), ui.color],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: ui.color.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              dateFormatted,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (request.status == 'reviewing_data' || request.status == 'waiting_docs')
                          Text(
                            'TOQUE PARA CORRIGIR',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: ui.color,
                              letterSpacing: 0.5,
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
      ),
    );
  }

  Widget _buildStatusBadge(_StatusUI ui) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ui.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ui.color.withValues(alpha: 0.2)),
      ),
      child: Text(
        ui.label.toUpperCase(),
        style: GoogleFonts.inter(
          color: ui.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _StatusUI _getStatusUI(String status) {
    switch (status.toLowerCase()) {
      case 'waiting_approval':
        return _StatusUI('Em análise', AppColors.alertOrange, 0.25);
      case 'reviewing_data':
        return _StatusUI('Revisar Dados', AppColors.alertOrange, 0.45);
      case 'waiting_docs':
        return _StatusUI('Docs Pendentes', const Color(0xFFEF4444), 0.35);
      case 'active':
        return _StatusUI('Emitida', AppColors.statusGreen, 1.0);
      case 'rejected':
        return _StatusUI('Reprovada', const Color(0xFFEF4444), 1.0);
      case 'suspended':
        return _StatusUI('Suspensa', Colors.grey, 1.0);
      case 'expired':
        return _StatusUI('Expirada', Colors.grey, 1.0);
      default:
        return _StatusUI('Processando', AppColors.primary, 0.1);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'new_card':
      case 'emissão digital':
        return Icons.badge_rounded;
      case 'update_data':
      case 'atualização de cadastro':
        return Icons.edit_note_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'new_card':
      case 'emissão digital':
      case 'primeira via':
        return 'Emissão de Carteirinha';
      case 'update_data':
      case 'atualização de cadastro':
        return 'Atualização Cadastral';
      case 'support':
        return 'Solicitação de Suporte';
      default:
        return 'Solicitação';
    }
  }
}

class _StatusUI {
  final String label;
  final Color color;
  final double progress;

  _StatusUI(this.label, this.color, this.progress);
}

