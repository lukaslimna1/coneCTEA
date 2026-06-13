import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/widgets/account_change_summary_card.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_detail_view.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/services/database_service.dart';

class AccountChangesView extends StatefulWidget {
  const AccountChangesView({super.key});

  @override
  State<AccountChangesView> createState() => _AccountChangesViewState();
}

class _AccountChangesViewState extends State<AccountChangesView> {
  final DatabaseService _databaseService = DatabaseService();
  List<AccountChangeRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountChanges(showLoading: true);
  }

  Future<void> _loadAccountChanges({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _databaseService.listMyAccountChanges(
        limit: 10,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _requests = data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Não foi possível carregar suas solicitações.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: () => _loadAccountChanges(showLoading: false),
          color: DsCores.correcao.accent,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final ongoing = _requests
        .where((r) => AccountChangePresentation(r).isOngoing)
        .toList();
    final history = _requests
        .where((r) => !AccountChangePresentation(r).isOngoing)
        .toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // 1. Cabeçalho Principal (Botão Voltar, Título e Subtítulo)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsBotaoVoltar(onPressed: () => Navigator.pop(context)),
                const SizedBox(height: 24),
                Text(
                  'Minhas alterações de conta',
                  style: DsTipografia.pageTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe o andamento das solicitações de e-mail e CPF.',
                  style: DsTipografia.pageSubtitle,
                ),
              ],
            ),
          ),
        ),

        // 2. Fluxo Principal baseado nos estados
        if (_isLoading)
          SliverFillRemaining(hasScrollBody: false, child: _buildLoadingState())
        else if (_errorMessage != null)
          SliverFillRemaining(hasScrollBody: false, child: _buildErrorState())
        else if (_requests.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
        else ...[
          // Seção: Em andamento
          if (ongoing.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: PhosphorIconsRegular.rocketLaunch,
                title: 'EM ANDAMENTO E PENDÊNCIAS',
                topPadding: DsEspacamentos.lg,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final req = ongoing[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DsEspacamentos.md),
                    child: AccountChangeSummaryCard(
                      request: req,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountChangeDetailView(requestId: req.id),
                          ),
                        );
                      },
                    ),
                  );
                }, childCount: ongoing.length),
              ),
            ),
          ],

          // Seção: Histórico
          if (history.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: PhosphorIconsRegular.clockCounterClockwise,
                title: 'HISTÓRICO',
                topPadding: ongoing.isEmpty
                    ? DsEspacamentos.lg
                    : DsEspacamentos.xl,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final req = history[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DsEspacamentos.md),
                    child: AccountChangeSummaryCard(
                      request: req,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountChangeDetailView(requestId: req.id),
                          ),
                        );
                      },
                    ),
                  );
                }, childCount: history.length),
              ),
            ),
          ],

          // Espaçamento final seguro contra a navbar do shell
          const SliverToBoxAdapter(child: SizedBox(height: DsEspacamentos.xl)),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: DsCores.textSecondary),
          const SizedBox(height: 16),
          Semantics(
            label: 'Carregando alterações...',
            child: Text(
              'Carregando alterações...',
              style: TextStyle(color: DsCores.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DsEspacamentos.xl),
              decoration: const BoxDecoration(
                color: DsCores.iconFrameBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.clipboardText,
                size: DsTamanhos.iconLg,
                color: DsCores.iconMuted,
              ),
            ),
            const SizedBox(height: DsEspacamentos.lg),
            Text(
              'Nenhuma alteração solicitada',
              style: DsTipografia.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DsEspacamentos.xs),
            Text(
              'Quando você solicitar uma mudança de e-mail ou CPF, o acompanhamento aparecerá aqui.',
              textAlign: TextAlign.center,
              style: DsTipografia.infoBody.copyWith(
                color: DsCores.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: DsCard(
          borderColor: DsCores.perigo.border,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.warningCircle,
                color: DsCores.perigo.accent,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar',
                style: DsTipografia.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Confira sua conexão e tente novamente.',
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              DsBotao(
                label: 'Tentar novamente',
                onPressed: () => _loadAccountChanges(showLoading: true),
                variante: DsBotaoVariante.acao,
                token: DsCores.perigo,
                icon: PhosphorIconsRegular.arrowClockwise,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required double topPadding,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, DsEspacamentos.sm),
      child: Row(
        children: [
          Icon(icon, color: DsCores.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: DsTipografia.label.copyWith(
              color: DsCores.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
