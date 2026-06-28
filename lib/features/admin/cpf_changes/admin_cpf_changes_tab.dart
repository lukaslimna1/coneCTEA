import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_filter.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_summary.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_list_result.dart';
import 'package:conectea/features/admin/cpf_changes/services/admin_cpf_changes_repository.dart';
import 'package:conectea/features/admin/cpf_changes/admin_cpf_change_details_sheet.dart';

enum _CpfFilter {
  underReview,
  corrections,
  completed,
  waitingHolderConfirmation,
  rejectedByAdmin,
  cancelledByHolder,
  expiredOrFailed,
}

extension _CpfFilterExtension on _CpfFilter {
  String get label {
    switch (this) {
      case _CpfFilter.underReview:
        return 'Análise';
      case _CpfFilter.corrections:
        return 'Correções';
      case _CpfFilter.completed:
        return 'Concluídas';
      case _CpfFilter.waitingHolderConfirmation:
        return 'Confirmar';
      case _CpfFilter.rejectedByAdmin:
        return 'Rejeitadas';
      case _CpfFilter.cancelledByHolder:
        return 'Canceladas';
      case _CpfFilter.expiredOrFailed:
        return 'Expiradas';
    }
  }

  String get semanticsLabel {
    switch (this) {
      case _CpfFilter.underReview:
        return 'Solicitações em Análise';
      case _CpfFilter.corrections:
        return 'Aguardando Correção de Dados ou Documento';
      case _CpfFilter.completed:
        return 'Solicitações Concluídas';
      case _CpfFilter.waitingHolderConfirmation:
        return 'Aguardando Confirmação do Titular';
      case _CpfFilter.rejectedByAdmin:
        return 'Solicitações Rejeitadas';
      case _CpfFilter.cancelledByHolder:
        return 'Solicitações Canceladas pelo Titular';
      case _CpfFilter.expiredOrFailed:
        return 'Solicitações Expiradas ou Falhas';
    }
  }

  IconData get icon {
    switch (this) {
      case _CpfFilter.underReview:
        return PhosphorIconsRegular.sparkle;
      case _CpfFilter.corrections:
        return PhosphorIconsRegular.notePencil;
      case _CpfFilter.completed:
        return PhosphorIconsRegular.checkCircle;
      case _CpfFilter.waitingHolderConfirmation:
        return PhosphorIconsRegular.userCheck;
      case _CpfFilter.rejectedByAdmin:
        return PhosphorIconsRegular.prohibit;
      case _CpfFilter.cancelledByHolder:
        return PhosphorIconsRegular.calendarX;
      case _CpfFilter.expiredOrFailed:
        return PhosphorIconsRegular.warningOctagon;
    }
  }

  DsCorVisual get token {
    switch (this) {
      case _CpfFilter.underReview:
        return DsCores.alerta;
      case _CpfFilter.corrections:
        return DsCores.correcao;
      case _CpfFilter.completed:
        return DsCores.sucesso;
      case _CpfFilter.waitingHolderConfirmation:
        return DsCores.conta;
      case _CpfFilter.rejectedByAdmin:
        return DsCores.perigo;
      case _CpfFilter.cancelledByHolder:
        return DsCores.manutencao;
      case _CpfFilter.expiredOrFailed:
        return DsCores.manutencao;
    }
  }
}

class AdminCpfChangesTab extends StatefulWidget {
  const AdminCpfChangesTab({super.key});

  @override
  State<AdminCpfChangesTab> createState() => _AdminCpfChangesTabState();
}

class _AdminCpfChangesTabState extends State<AdminCpfChangesTab> {
  late final AdminCpfChangesRepository _repository;
  late final TextEditingController _searchController;
  late final ValueNotifier<_CpfFilter> _selectedFilterNotifier;
  late final ValueNotifier<String> _searchQueryNotifier;

  Timer? _debounceTimer;
  bool _isLoading = false;
  String? _errorMessage;
  AdminCpfChangeListResult? _result;
  int _currentRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    _repository = AdminCpfChangesRepository();
    _searchController = TextEditingController();
    _selectedFilterNotifier = ValueNotifier<_CpfFilter>(_CpfFilter.underReview);
    _searchQueryNotifier = ValueNotifier<String>('');

    // Recarrega os dados dinamicamente ao trocar de aba
    _selectedFilterNotifier.addListener(() {
      _loadData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _selectedFilterNotifier.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  AdminCpfChangeFilter _mapCpfFilterToRepositoryFilter(_CpfFilter filter) {
    switch (filter) {
      case _CpfFilter.underReview:
        return AdminCpfChangeFilter.analysis;
      case _CpfFilter.corrections:
        return AdminCpfChangeFilter.corrections;
      case _CpfFilter.completed:
        return AdminCpfChangeFilter.completed;
      case _CpfFilter.waitingHolderConfirmation:
        return AdminCpfChangeFilter.confirmation;
      case _CpfFilter.rejectedByAdmin:
        return AdminCpfChangeFilter.rejected;
      case _CpfFilter.cancelledByHolder:
        return AdminCpfChangeFilter.cancelled;
      case _CpfFilter.expiredOrFailed:
        return AdminCpfChangeFilter.expiredFailed;
    }
  }

  Future<void> _loadData() async {
    _currentRequestVersion++;
    final int thisVersion = _currentRequestVersion;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = _searchQueryNotifier.value.trim();
      final filter = _selectedFilterNotifier.value;

      final result = await _repository.listCpfChangeRequests(
        filter: query.isNotEmpty
            ? AdminCpfChangeFilter.all
            : _mapCpfFilterToRepositoryFilter(filter),
        search: query,
        limit: 20,
        offset: 0,
      );

      if (thisVersion != _currentRequestVersion) return;

      setState(() {
        _result = result;
      });
    } catch (_) {
      if (thisVersion != _currentRequestVersion) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar as solicitações agora.';
      });
    } finally {
      if (thisVersion == _currentRequestVersion) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDetailSheet(AdminCpfChangeSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminCpfChangeDetailsSheet(summary: summary),
    );
  }

  String? _formatCivilDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return null;
    final clean = rawDate.trim();
    final parts = clean.split('-');
    if (parts.length == 3) {
      final year = parts[0];
      final month = parts[1];
      final day = parts[2];
      return '$day/$month/$year';
    }
    return clean;
  }

  String _formatDateTime(DateTime dt) {
    final dateStr = ConecteaDateTimeHelper.formatProjectDateShort(dt);
    final timeStr = ConecteaDateTimeHelper.formatProjectTime(dt);
    return '$dateStr às $timeStr';
  }

  String? _getDeadlineText(AdminCpfChangeSummary item) {
    if (item.status == AccountChangeStatus.underReview) {
      final formatted = _formatCivilDate(item.adminDeadlineDueDate);
      if (formatted != null) {
        return 'Prazo: $formatted';
      }
    } else if (item.status == AccountChangeStatus.waitingCpfCorrection ||
        item.status == AccountChangeStatus.waitingDocumentReplacement) {
      final formatted = _formatCivilDate(item.holderDeadlineDueDate);
      if (formatted != null) {
        return 'Prazo Titular: $formatted';
      }
    }
    return null;
  }

  Widget _buildStatusSelo(AccountChangeStatus status) {
    String label;
    IconData icon;
    Color color;

    switch (status) {
      case AccountChangeStatus.underReview:
        label = 'EM ANÁLISE';
        icon = PhosphorIconsFill.clockCountdown;
        color = const Color(0xFFF59E0B);
        break;
      case AccountChangeStatus.waitingCpfCorrection:
        label = 'CORRIGIR CPF';
        icon = PhosphorIconsFill.warningCircle;
        color = const Color(0xFFFF7A1A);
        break;
      case AccountChangeStatus.waitingDocumentReplacement:
        label = 'REENVIAR DOC';
        icon = PhosphorIconsFill.files;
        color = const Color(0xFF22D3EE);
        break;
      case AccountChangeStatus.waitingHolderConfirmation:
        label = 'CONFIRMAR';
        icon = PhosphorIconsFill.userCheck;
        color = const Color(0xFF8B3DFF);
        break;
      case AccountChangeStatus.completed:
        label = 'CONCLUÍDA';
        icon = PhosphorIconsFill.checkCircle;
        color = const Color(0xFF00FF85);
        break;
      case AccountChangeStatus.rejectedByAdmin:
        label = 'REJEITADA';
        icon = PhosphorIconsFill.xCircle;
        color = const Color(0xFFE11D48);
        break;
      case AccountChangeStatus.cancelledByHolder:
        label = 'CANCELADA';
        icon = PhosphorIconsFill.calendarX;
        color = const Color(0xFFCBD5E1);
        break;
      case AccountChangeStatus.expired:
        label = 'EXPIRADA';
        icon = PhosphorIconsFill.calendarX;
        color = const Color(0xFFCBD5E1);
        break;
      case AccountChangeStatus.applicationFailed:
        label = 'FALHA';
        icon = PhosphorIconsFill.warningOctagon;
        color = const Color(0xFFE11D48);
        break;
      case AccountChangeStatus.applying:
        label = 'PROCESSANDO';
        icon = PhosphorIconsFill.arrowsClockwise;
        color = const Color(0xFF22D3EE);
        break;
      default:
        label = 'DESCONHECIDO';
        icon = PhosphorIconsFill.question;
        color = const Color(0xFFCBD5E1);
    }

    return DsSelo(
      label: label,
      labelColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.25),
      icon: icon,
      iconColor: color,
      compact: true,
    );
  }

  Widget _buildItemCard(AdminCpfChangeSummary item) {
    Color statusColor;
    switch (item.status) {
      case AccountChangeStatus.underReview:
        statusColor = const Color(0xFFF59E0B);
        break;
      case AccountChangeStatus.waitingCpfCorrection:
        statusColor = const Color(0xFFFF7A1A);
        break;
      case AccountChangeStatus.waitingDocumentReplacement:
        statusColor = const Color(0xFF22D3EE);
        break;
      case AccountChangeStatus.waitingHolderConfirmation:
        statusColor = const Color(0xFF8B3DFF);
        break;
      case AccountChangeStatus.completed:
        statusColor = const Color(0xFF00FF85);
        break;
      case AccountChangeStatus.rejectedByAdmin:
        statusColor = const Color(0xFFE11D48);
        break;
      default:
        statusColor = const Color(0xFFCBD5E1);
    }

    final String? deadlineText = _getDeadlineText(item);

    return GestureDetector(
      onTap: () => _openDetailSheet(item),
      child: DsCard(
        accentColor: statusColor,
        showGlow: item.isOverdue,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1 — Status + Prazo (Topo)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(child: _buildStatusSelo(item.status)),
                const SizedBox(width: 12),
                if (deadlineText != null)
                  Flexible(
                    flex: 0,
                    child: Text(
                      deadlineText,
                      style: DsTipografia.caption.copyWith(
                        color: item.isOverdue
                            ? DsCores.perigo.accent
                            : DsCores.textSecondary.withValues(alpha: 0.65),
                        fontWeight: item.isOverdue
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Linha 2 — Protocolo com destaque (Estilo Carteirinhas)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.receipt,
                    size: 14,
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#${item.protocolNumber}',
                      style: DsTipografia.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Linha 3 — Nome do beneficiário (Caixa Alta) e E-mail
            Text(
              item.userFirstName.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DsTipografia.body.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            if (item.userEmailMasked.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                item.userEmailMasked,
                style: DsTipografia.caption.copyWith(
                  color: DsCores.textSecondary.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Linha 4 — Datas Principais
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitada em: ${_formatDateTime(item.createdAt)}',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                if (item.status == AccountChangeStatus.cancelledByHolder) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Cancelada em: ${_formatDateTime(item.closedAt ?? item.statusChangedAt ?? item.updatedAt)}',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ] else if (item.status == AccountChangeStatus.completed) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Concluída em: ${_formatDateTime(item.closedAt ?? item.statusChangedAt ?? item.updatedAt)}',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ] else if (item.status ==
                    AccountChangeStatus.rejectedByAdmin) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Rejeitada em: ${_formatDateTime(item.closedAt ?? item.statusChangedAt ?? item.updatedAt)}',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ] else if (item.status == AccountChangeStatus.expired) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Expirada em: ${_formatDateTime(item.closedAt ?? item.statusChangedAt ?? item.updatedAt)}',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ] else if (item.status ==
                    AccountChangeStatus.applicationFailed) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Falha em: ${_formatDateTime(item.closedAt ?? item.statusChangedAt ?? item.updatedAt)}',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ] else if (item.status == AccountChangeStatus.underReview) ...[
                  if (item.adminDeadlineDueDate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Prazo de análise: ${_formatCivilDate(item.adminDeadlineDueDate)}',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ] else if (item.status ==
                    AccountChangeStatus.waitingCpfCorrection) ...[
                  if (item.holderDeadlineDueDate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Prazo para corrigir CPF: ${_formatCivilDate(item.holderDeadlineDueDate)}',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ] else if (item.status ==
                    AccountChangeStatus.waitingDocumentReplacement) ...[
                  if (item.holderDeadlineDueDate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Prazo para reenviar documento: ${_formatCivilDate(item.holderDeadlineDueDate)}',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ] else if (item.status ==
                    AccountChangeStatus.waitingHolderConfirmation) ...[
                  if (item.holderDeadlineDueDate != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Prazo para confirmar: ${_formatCivilDate(item.holderDeadlineDueDate)}',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ] else if (item.status == AccountChangeStatus.applying) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Processando alteração',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Linha 5 — Rodapé: Botão visual (CTA)
            Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.status == AccountChangeStatus.underReview
                        ? 'Analisar solicitação'
                        : 'Ver solicitação',
                    style: DsTipografia.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    PhosphorIconsRegular.arrowRight,
                    size: 15,
                    color: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Campo de busca no topo (DS V2) - Fixo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: DsInput(
              label: 'Buscar solicitação',
              controller: _searchController,
              hint: 'Buscar por protocolo ou titular',
              icon: PhosphorIconsRegular.magnifyingGlass,
              onChanged: (val) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  _searchQueryNotifier.value = val;
                  _loadData();
                });
              },
            ),
          ),

          // 2. Filtros horizontais com contadores (Carrossel) - Fixo
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: ValueListenableBuilder<_CpfFilter>(
              valueListenable: _selectedFilterNotifier,
              builder: (context, selectedFilter, child) {
                return _buildFilterCarousel(selectedFilter);
              },
            ),
          ),

          // 3. Indicador sutil de deslize (Estilo Carteirinhas) - Fixo
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'deslize',
                  style: DsTipografia.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

          // Indicador discreto de pesquisa global - Fixo
          ValueListenableBuilder<String>(
            valueListenable: _searchQueryNotifier,
            builder: (context, query, child) {
              if (query.trim().isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.info,
                      size: 14,
                      color: DsCores.conta.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pesquisando globalmente em todos os status.',
                        style: DsTipografia.caption.copyWith(
                          color: DsCores.conta.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 4. Área de Lista com Refresh Indicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: DsCores.conta.accent,
              backgroundColor: DsCores.background,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (_isLoading && _result == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 64, 24, 120),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              PhosphorIconsRegular.warningCircle,
                              size: 40,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: DsEspacamentos.sm),
                            Text(
                              _errorMessage!,
                              style: DsTipografia.body.copyWith(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DsEspacamentos.md),
                            DsBotao(
                              label: 'Tentar novamente',
                              variante: DsBotaoVariante.secundario,
                              token: DsCores.conta,
                              onPressed: _loadData,
                              fullWidth: false,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_result == null || _result!.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        filter: _selectedFilterNotifier.value,
                        query: _searchQueryNotifier.value,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 48),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _result!.items[index];
                          return _buildItemCard(item);
                        }, childCount: _result!.items.length),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCarousel(_CpfFilter selectedFilter) {
    int getCount(_CpfFilter f) {
      if (_result == null) return 0;
      switch (f) {
        case _CpfFilter.underReview:
          return _result!.counts.analysis;
        case _CpfFilter.corrections:
          return _result!.counts.corrections;
        case _CpfFilter.completed:
          return _result!.counts.completed;
        case _CpfFilter.waitingHolderConfirmation:
          return _result!.counts.confirmation;
        case _CpfFilter.rejectedByAdmin:
          return _result!.counts.rejected;
        case _CpfFilter.cancelledByHolder:
          return _result!.counts.cancelled;
        case _CpfFilter.expiredOrFailed:
          return _result!.counts.expiredFailed;
      }
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _CpfFilter.values.length,
        itemBuilder: (context, index) {
          final filter = _CpfFilter.values[index];
          final bool isSelected = selectedFilter == filter;
          final currentCount = getCount(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DsCardFiltroContador(
              label: filter.label,
              count: currentCount,
              icon: filter.icon,
              isSelected: isSelected,
              token: filter.token,
              semanticsLabel: '${filter.semanticsLabel}: $currentCount itens',
              onTap: () => _selectedFilterNotifier.value = filter,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required _CpfFilter filter, required String query}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filter.token.accent.withValues(alpha: 0.15),
                ),
              ),
              Icon(
                PhosphorIconsRegular.tray,
                size: 28,
                color: filter.token.accent,
              ),
            ],
          ),
          const SizedBox(height: DsEspacamentos.md),
          Text(
            query.isEmpty
                ? 'Nenhuma solicitação em ${filter.label}'
                : 'Nenhum resultado encontrado',
            style: DsTipografia.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DsEspacamentos.xs),
          Text(
            query.isEmpty
                ? 'Quando houver registros, eles aparecerão aqui.'
                : 'Tente buscar por protocolo ou titular.',
            style: DsTipografia.caption.copyWith(
              color: DsCores.textSecondary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
