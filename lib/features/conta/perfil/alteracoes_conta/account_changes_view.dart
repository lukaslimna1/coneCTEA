import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/widgets/account_change_summary_card.dart';
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
    // A tela já fica sob a aba Conta, logo a navbar e o header são visíveis.
    // Usamos um layout consistente com Meus Dados para o cabeçalho.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: () => _loadAccountChanges(showLoading: false),
          color: DsCores.correcao.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Área do cabeçalho da página (compensado pelo shell da aba Conta na HomePage)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsBotaoVoltar(onPressed: () => Navigator.pop(context)),
                    const SizedBox(height: 24),
                    Text(
                      'Minhas alterações de conta',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acompanhe o andamento das solicitações de e-mail e CPF.',
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Corpo da tela (Lista ou Estados de Loading/Erro/Vazio)
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_requests.isEmpty) {
      return _buildEmptyState();
    }

    // Separação das requisições localmente de acordo com a apresentação
    final ongoing = _requests
        .where((r) => AccountChangePresentation(r).isOngoing)
        .toList();
    final history = _requests
        .where((r) => !AccountChangePresentation(r).isOngoing)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: [
        if (ongoing.isNotEmpty) ...[
          _buildSectionHeader(
            icon: PhosphorIconsRegular.rocketLaunch,
            title: 'EM ANDAMENTO E PENDÊNCIAS',
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ongoing.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AccountChangeSummaryCard(request: ongoing[index]),
              );
            },
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader(
            icon: PhosphorIconsRegular.clockCounterClockwise,
            title: 'HISTÓRICO',
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AccountChangeSummaryCard(request: history[index]),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: DsCores.textSecondary, size: 20),
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
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
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
                style: DsTipografia.sectionTitle.copyWith(
                  color: DsCores.textPrimary,
                ),
              ),
              const SizedBox(height: DsEspacamentos.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Quando você solicitar uma mudança de e-mail ou CPF, o acompanhamento aparecerá aqui.',
                  textAlign: TextAlign.center,
                  style: DsTipografia.infoBody.copyWith(
                    color: DsCores.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        DsCard(
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
                style: DsTipografia.cardTitle.copyWith(
                  color: DsCores.textPrimary,
                ),
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
      ],
    );
  }
}
