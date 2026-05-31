import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';
import 'package:conectea/core/widgets/premium/status_action_button.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:conectea/features/carteirinhas/solicitacao/add_member_page.dart';

class RequestsView extends StatefulWidget {
  final VoidCallback? onBack;

  const RequestsView({super.key, this.onBack});

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> {
  Stream<List<CardRequest>>? _cardRequestsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final userId = AuthService().currentUser?.id;
    if (userId != null) {
      _cardRequestsStream = DatabaseService().cardRequestsStream(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding =
        topSafeArea + headerVisualHeight + headerClearance;

    final authService = AuthService();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Por favor, faça login'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: StreamBuilder<List<CardRequest>>(
          stream: _cardRequestsStream,
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

            final ongoing = requests
                .where((r) => _isOngoing(r.status))
                .toList();
            final history = requests
                .where((r) => !_isOngoing(r.status))
                .toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.onBack != null ||
                            Navigator.canPop(context)) ...[
                          GestureDetector(
                            onTap:
                                widget.onBack ??
                                () => Navigator.maybePop(context),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.arrowLeft,
                                    color: const Color(
                                      0xFF00D8D0,
                                    ), // Azul ciano DS V2
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Voltar',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF00D8D0),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Text(
                          'Acompanhamentos',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cardTitle,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Veja o andamento dos seus pedidos, correções e solicitações.',
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
                    child: _buildSectionHeader(
                      context,
                      PhosphorIconsRegular.rocketLaunch,
                      'EM ANDAMENTO',
                      ongoing.length,
                    ),
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
                    child: _buildSectionHeader(
                      context,
                      PhosphorIconsRegular.clockCounterClockwise,
                      'HISTÓRICO',
                      history.length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRequestCard(
                            context,
                            history[index],
                            isHistory: true,
                          ),
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
            );
          },
        ),
      ),
    );
  }

  bool _isOngoing(String status) {
    final s = status.toLowerCase();
    return s != 'active' &&
        s != 'rejected' &&
        s != 'suspended' &&
        s != 'expired';
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    int count,
  ) {
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
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.92),
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
            child: const Icon(
              PhosphorIconsRegular.clipboardText,
              size: 64,
              color: AppColors.cardMutedText,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum acompanhamento por enquanto.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando você fizer uma solicitação, ela aparecerá aqui.',
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

  Widget _buildRequestCard(
    BuildContext context,
    CardRequest request, {
    bool isHistory = false,
  }) {
    final databaseService = DatabaseService();
    final tokens = StatusVisualTokens.fromStatus(request.status);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(request.createdAt);

    bool isActionable =
        request.status == 'reviewing_data' || request.status == 'waiting_docs';

    return PremiumCard(
      hasGradient: true,
      padding: EdgeInsets.zero,
      radius: 20,
      onTap: !isActionable
          ? null
          : () async {
              final member = await databaseService.getMember(request.memberId);
              if (member != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddMemberPage(member: member, request: request),
                  ),
                );
              }
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faixa/acento superior colorido pelo status
          Container(height: 4, width: double.infinity, color: tokens.primary),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pill de status
                _buildStatusBadge(tokens),
                const SizedBox(height: 12),

                // 2. Ícone + Título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTypeIcon(request.type),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getTypeLabel(request.type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.cardTitle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Protocolo
                if (request.protocol.isNotEmpty) ...[
                  Text(
                    'Protocolo: ${request.protocol}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.cardMutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // 4. Data
                Text(
                  'Solicitado em $dateFormatted',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.cardMutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Progresso da análise (apenas para itens em andamento)
                if (!isHistory) ...[
                  const SizedBox(height: 16),
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
                        '${(_getProgress(request.status) * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: tokens.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
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
                            width:
                                constraints.maxWidth *
                                _getProgress(request.status),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tokens.primary.withValues(alpha: 0.6),
                                  tokens.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                // Notas Administrativas de Pendência / O que Ajustar
                if (isActionable && request.adminNotes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.info,
                              color: tokens.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'O que precisa ajustar:',
                              style: GoogleFonts.inter(
                                color: tokens.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.adminNotes.trim(),
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botão CORRIGIR alinhado no canto inferior direito
                if (isActionable) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: StatusActionButton(
                      label: 'CORRIGIR',
                      statusKey: request.status,
                      height: 28,
                      fontSize: 9,
                      iconSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StatusVisualTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.pillBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tokens.icon, size: 12, color: tokens.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              tokens.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: tokens.primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getProgress(String status) {
    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
        return 0.25;
      case 'reviewing_data':
        return 0.45;
      case 'waiting_docs':
        return 0.35;
      case 'active':
        return 1.0;
      case 'rejected':
        return 1.0;
      case 'suspended':
        return 1.0;
      case 'expired':
        return 1.0;
      default:
        return 0.1;
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
