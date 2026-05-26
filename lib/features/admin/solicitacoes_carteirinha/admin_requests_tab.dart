import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/core/widgets/loading_shimmer.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/features/admin/solicitacoes_carteirinha/admin_request_card.dart';
import 'package:conectea/features/admin/widgets/admin_request_details_sheet.dart';
import 'package:conectea/core/theme/conectea_visual_tokens.dart';

class AdminRequestsTab extends StatefulWidget {
  final DatabaseService databaseService;

  const AdminRequestsTab({super.key, required this.databaseService});

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

enum _AdminRequestQueueFilter {
  newRequests,
  corrections,
  active,
  restricted,
  expired,
  renewal,
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  _AdminRequestQueueFilter _activeFilter = _AdminRequestQueueFilter.newRequests;
  late final Stream<List<CardRequest>> _requestsStream;
  List<CardRequest> _lastRequests = [];
  late final TextEditingController _searchController;
  FocusNode? _searchFocusNode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _requestsStream = widget.databaseService.getAllCardRequestsStream();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode!.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode?.removeListener(_onFocusChange);
    _searchFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CardRequest>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        final bool hasCachedRequests = _lastRequests.isNotEmpty;

        if (snapshot.hasData) {
          _lastRequests = snapshot.data!.whereType<CardRequest>().toList();
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !hasCachedRequests) {
          return _buildShimmerList();
        }

        final List<CardRequest> requests = snapshot.hasData
            ? snapshot.data!.whereType<CardRequest>().toList()
            : _lastRequests;

        // Sort: pendentes primeiro, depois por data
        final sortedRequests = List<CardRequest>.from(requests)
          ..sort((a, b) {
            final aStatus = a.status;
            final bStatus = b.status;
            if (aStatus == 'waiting_approval' &&
                bStatus != 'waiting_approval') {
              return -1;
            }
            if (aStatus != 'waiting_approval' &&
                bStatus == 'waiting_approval') {
              return 1;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

        // Contagens precisas dos 6 grupos semânticos
        final newRequestsCount = requests
            .where((r) => r.status == 'waiting_approval')
            .length;
        final correctionsCount = requests
            .where((r) => ['reviewing_data', 'waiting_docs'].contains(r.status))
            .length;
        final activeCount = requests
            .where((r) => ['active', 'approved'].contains(r.status))
            .length;
        final restrictedCount = requests
            .where((r) => ['rejected', 'suspended'].contains(r.status))
            .length;
        final expiredCount = requests
            .where((r) => r.status == 'expired')
            .length;
        final renewalCount = requests
            .where((r) => r.status == 'renewing')
            .length;

        // 1. Filtrar a lista com base no _activeFilter selecionado nos contadores superiores
        final filteredRequests = sortedRequests.where((r) {
          switch (_activeFilter) {
            case _AdminRequestQueueFilter.newRequests:
              return r.status == 'waiting_approval';
            case _AdminRequestQueueFilter.corrections:
              return ['reviewing_data', 'waiting_docs'].contains(r.status);
            case _AdminRequestQueueFilter.active:
              return ['active', 'approved'].contains(r.status);
            case _AdminRequestQueueFilter.restricted:
              return ['rejected', 'suspended'].contains(r.status);
            case _AdminRequestQueueFilter.expired:
              return r.status == 'expired';
            case _AdminRequestQueueFilter.renewal:
              return r.status == 'renewing';
          }
        }).toList();

        // 2. Aplicar busca global sobre todas as solicitações caso haja busca ativa
        final isSearching = _searchQuery.trim().isNotEmpty;
        final globalSearchResults = sortedRequests.where((r) {
          if (!isSearching) return false;
          final query = _searchQuery.trim().toLowerCase();

          final protocol = r.protocol.toLowerCase();
          final idFallback = r.id.length >= 6
              ? r.id.substring(0, 6).toLowerCase()
              : r.id.toLowerCase();
          final memberName = r.memberName.toLowerCase();

          return protocol.contains(query) ||
              idFallback.contains(query) ||
              memberName.contains(query);
        }).toList();

        // 3. Determinar a lista final a ser exibida
        final List<CardRequest> displayRequests = isSearching
            ? globalSearchResults
            : filteredRequests;

        return CustomScrollView(
          slivers: [
            // Bloco 3: Campo de busca global (Sempre Visível)
            SliverToBoxAdapter(child: _buildSearchBar()),
            // Bloco 4: Carrossel de filtros
            SliverToBoxAdapter(
              child: _AdminRequestFilterCarousel(
                key: const PageStorageKey('admin_request_filter_carousel'),
                activeFilter: _activeFilter,
                newRequests: newRequestsCount,
                corrections: correctionsCount,
                active: activeCount,
                restricted: restrictedCount,
                expired: expiredCount,
                renewal: renewalCount,
                onFilterChanged: (filter) {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
              ),
            ),
            // Bloco 5: Lista / Empty states
            if (!isSearching && filteredRequests.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  child: _buildEmptyState(
                    _activeFilter == _AdminRequestQueueFilter.newRequests
                        ? 'Nenhuma solicitação nova'
                        : _activeFilter == _AdminRequestQueueFilter.corrections
                        ? 'Nenhuma solicitação em correção'
                        : _activeFilter == _AdminRequestQueueFilter.active
                        ? 'Nenhuma solicitação ativa'
                        : _activeFilter == _AdminRequestQueueFilter.restricted
                        ? 'Nenhuma solicitação restrita'
                        : _activeFilter == _AdminRequestQueueFilter.expired
                        ? 'Nenhuma solicitação vencida'
                        : 'Nenhuma solicitação de renovação',
                    Icons.inbox_rounded,
                  ),
                ),
              )
            else if (isSearching && globalSearchResults.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
                  child: _buildSearchEmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final request = displayRequests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdminRequestCard(
                        request: request,
                        onTap: () => _showRequestDetails(request),
                      ),
                    );
                  }, childCount: displayRequests.length),
                ),
              ),
          ],
        );
      },
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
                  LoadingShimmer(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 16,
                  ),
                  const SizedBox(height: 8),
                  LoadingShimmer(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
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
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            Icon(
              PhosphorIconsRegular.tray,
              size: 32,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quando houver registros, eles aparecerão aqui.',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
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

  Widget _buildSearchBar() {
    final hasText = _searchQuery.isNotEmpty;
    final isFocused = _searchFocusNode?.hasFocus ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xA60F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? ConecteaVisualTokens.visualizacao.accent.withValues(
                        alpha: 0.35,
                      )
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (isFocused)
                  BoxShadow(
                    color: ConecteaVisualTokens.visualizacao.accent.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ConecteaVisualTokens.visualizacao.accent.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: 18,
                      color: ConecteaVisualTokens.visualizacao.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    child: TextSelectionTheme(
                      data: TextSelectionThemeData(
                        cursorColor: ConecteaVisualTokens.visualizacao.accent,
                        selectionColor: ConecteaVisualTokens.visualizacao.accent
                            .withValues(alpha: 0.22),
                        selectionHandleColor:
                            ConecteaVisualTokens.visualizacao.accent,
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        cursorColor: ConecteaVisualTokens.visualizacao.accent,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: GoogleFonts.inter(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por protocolo ou nome',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasText) ...[
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(
                      PhosphorIconsRegular.xCircle,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                  const SizedBox(width: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
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
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 32,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Nenhum resultado encontrado',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tente buscar por protocolo ou nome.',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _AdminRequestFilterCarousel extends StatefulWidget {
  final _AdminRequestQueueFilter activeFilter;
  final int newRequests;
  final int corrections;
  final int active;
  final int restricted;
  final int expired;
  final int renewal;
  final ValueChanged<_AdminRequestQueueFilter> onFilterChanged;

  const _AdminRequestFilterCarousel({
    super.key,
    required this.activeFilter,
    required this.newRequests,
    required this.corrections,
    required this.active,
    required this.restricted,
    required this.expired,
    required this.renewal,
    required this.onFilterChanged,
  });

  @override
  State<_AdminRequestFilterCarousel> createState() =>
      _AdminRequestFilterCarouselState();
}

class _AdminRequestFilterCarouselState
    extends State<_AdminRequestFilterCarousel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  _buildStatCard(
                    _AdminRequestQueueFilter.newRequests,
                    'Novas',
                    widget.newRequests.toString(),
                    const Color(0xFFF59E0B),
                    PhosphorIconsRegular.sparkle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    _AdminRequestQueueFilter.corrections,
                    'Correções',
                    widget.corrections.toString(),
                    const Color(0xFFFF7A1A),
                    PhosphorIconsRegular.notePencil,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    _AdminRequestQueueFilter.active,
                    'Ativas',
                    widget.active.toString(),
                    const Color(0xFF00FF85),
                    PhosphorIconsRegular.checkCircle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    _AdminRequestQueueFilter.restricted,
                    'Restritas',
                    widget.restricted.toString(),
                    const Color(0xFFE11D48),
                    PhosphorIconsRegular.prohibit,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    _AdminRequestQueueFilter.expired,
                    'Vencidas',
                    widget.expired.toString(),
                    const Color(0xFFCBD5E1),
                    PhosphorIconsRegular.calendarX,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    _AdminRequestQueueFilter.renewal,
                    'Renovação',
                    widget.renewal.toString(),
                    const Color(0xFF8B3DFF),
                    PhosphorIconsRegular.arrowsClockwise,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'deslize',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    _AdminRequestQueueFilter filter,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final isSelected = widget.activeFilter == filter;

    return PremiumCard(
      width: 120,
      height: 102,
      padding: EdgeInsets.zero,
      onTap: () {
        widget.onFilterChanged(filter);
      },
      borderOverride: isSelected
          ? Border.all(color: color.withValues(alpha: 0.6), width: 1.5)
          : Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
      shadow: isSelected
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
      child: Expanded(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isSelected ? 0.18 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Icon(icon, color: color, size: 18)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
