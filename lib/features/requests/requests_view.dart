import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:conectea/features/requests/add_member_page.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: StreamBuilder<List<CardRequest>>(
          stream: databaseService.cardRequestsStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final requests = snapshot.data ?? [];
            
            // Ordenação: em andamento primeiro, depois por data
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
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solicitações',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Acompanhe o status e histórico de seus pedidos de carteirinha.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.cardSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (ongoing.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(context, PhosphorIconsRegular.rocketLaunch, 'EM ANDAMENTO', ongoing.length),
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
                      child: _buildSectionHeader(context, PhosphorIconsRegular.clockCounterClockwise, 'HISTÓRICO', history.length),
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
        ),
      ),
    );
  }

  bool _isOngoing(String status) {
    final s = status.toLowerCase();
    return s != 'active' && s != 'rejected' && s != 'suspended' && s != 'expired';
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cardMutedText, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.cardMutedText,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 11,
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.clipboardText, size: 64, color: AppColors.cardMutedText),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma solicitação',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus pedidos aparecerão aqui assim que\nvocê solicitar uma nova carteirinha.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.cardSubtitle,
              height: 1.5,
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
    
    return PremiumCard(
      hasGradient: true,
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
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getTypeIcon(request.type), color: AppColors.primary, size: 24),
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
                              color: AppColors.cardTitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Protocolo: ${request.protocol}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.cardMutedText,
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
                        'Progresso da análise',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cardSubtitle,
                        ),
                      ),
                      Text(
                        '${(ui.progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ui.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 6,
                        width: (MediaQuery.of(context).size.width - 88) * ui.progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ui.color.withValues(alpha: 0.6), ui.color],
                          ),
                          borderRadius: BorderRadius.circular(10),
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
                        const Icon(PhosphorIconsRegular.calendar, size: 14, color: AppColors.cardMutedText),
                        const SizedBox(width: 6),
                        Text(
                          dateFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.cardMutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (request.status == 'reviewing_data' || request.status == 'waiting_docs')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ui.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CORRIGIR',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: ui.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatusBadge(_StatusUI ui) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ui.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
        return _StatusUI('Docs Pendentes', AppColors.errorRed, 0.35);
      case 'active':
        return _StatusUI('Emitida', AppColors.statusGreen, 1.0);
      case 'rejected':
        return _StatusUI('Reprovada', AppColors.errorRed, 1.0);
      case 'suspended':
        return _StatusUI('Suspensa', AppColors.cardMutedText, 1.0);
      case 'expired':
        return _StatusUI('Expirada', AppColors.cardMutedText, 1.0);
      default:
        return _StatusUI('Processando', AppColors.primary, 0.1);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'new_card':
      case 'emissão digital':
        return PhosphorIconsRegular.identificationCard;
      case 'update_data':
      case 'atualização de cadastro':
        return PhosphorIconsRegular.notePencil;
      case 'support':
        return PhosphorIconsRegular.headset;
      default:
        return PhosphorIconsRegular.fileText;
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
