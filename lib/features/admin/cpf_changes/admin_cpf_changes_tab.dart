import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

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
  late final TextEditingController _searchController;
  late final ValueNotifier<_CpfFilter> _selectedFilterNotifier;
  late final ValueNotifier<String> _searchQueryNotifier;
  late final Listenable _resultNotifier;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedFilterNotifier = ValueNotifier<_CpfFilter>(_CpfFilter.underReview);
    _searchQueryNotifier = ValueNotifier<String>('');
    _resultNotifier = Listenable.merge([
      _selectedFilterNotifier,
      _searchQueryNotifier,
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedFilterNotifier.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // 1. Campo de busca no topo (DS V2)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: DsInput(
              label: 'Buscar solicitação',
              controller: _searchController,
              hint: 'Buscar por protocolo ou titular',
              icon: PhosphorIconsRegular.magnifyingGlass,
              onChanged: (val) {
                _searchQueryNotifier.value = val;
              },
            ),
          ),
        ),

        // 2. Filtros horizontais com contadores (Carrossel)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: ValueListenableBuilder<_CpfFilter>(
              valueListenable: _selectedFilterNotifier,
              builder: (context, selectedFilter, child) {
                return _buildFilterCarousel(selectedFilter);
              },
            ),
          ),
        ),

        // 3. Indicador sutil de deslize (Estilo Carteirinhas)
        SliverToBoxAdapter(
          child: Padding(
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
        ),

        // 4. Área de Lista / Empty State reativa
        AnimatedBuilder(
          animation: _resultNotifier,
          builder: (context, child) {
            return SliverToBoxAdapter(
              child: _buildEmptyState(
                filter: _selectedFilterNotifier.value,
                query: _searchQueryNotifier.value,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterCarousel(_CpfFilter selectedFilter) {
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

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DsCardFiltroContador(
              label: filter.label,
              count: 0,
              icon: filter.icon,
              isSelected: isSelected,
              token: filter.token,
              semanticsLabel: '${filter.semanticsLabel}: 0 itens',
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
