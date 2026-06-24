import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/widgets/account_change_value_delta.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/services/database_service.dart';

class AccountChangeDetailView extends StatefulWidget {
  final String requestId;

  const AccountChangeDetailView({super.key, required this.requestId});

  @override
  State<AccountChangeDetailView> createState() =>
      _AccountChangeDetailViewState();
}

class _AccountChangeDetailViewState extends State<AccountChangeDetailView> {
  final DatabaseService _databaseService = DatabaseService();
  AccountChangeRequest? _request;
  bool _isLoading = true;
  bool _notFound = false;
  String? _errorMessage;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadDetail(showLoading: true);
  }

  Future<void> _loadDetail({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _notFound = false;
      });
    }

    try {
      final request = await _databaseService.getMyAccountChange(
        requestId: widget.requestId,
      );

      if (mounted) {
        if (request == null) {
          setState(() {
            _notFound = true;
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _request = request;
            _isLoading = false;
            _notFound = false;
            _errorMessage = null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _notFound = false;
          _errorMessage = 'Não foi possível carregar os detalhes da alteração.';
        });
      }
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await DsDialog.show<bool>(
      context: context,
      title: 'Cancelar solicitação?',
      description:
          'Ao cancelar, esta solicitação será encerrada e o documento enviado será encaminhado para descarte seguro. Depois disso, você poderá iniciar uma nova solicitação de revisão de CPF.',
      icon: PhosphorIconsRegular.warning,
      token: DsCores.perigo,
      secondaryAction: const DsDialogAction(
        label: 'Manter solicitação',
        value: false,
        variante: DsBotaoVariante.ghost,
        token: DsCores.fallback,
      ),
      primaryAction: const DsDialogAction(
        label: 'Cancelar solicitação',
        value: true,
        variante: DsBotaoVariante.acao,
        token: DsCores.perigo,
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final result = await _databaseService.cancelCpfChangeRequest(
        requestId: widget.requestId,
      );

      if (mounted) {
        if (result['success'] == true) {
          await _loadDetail(showLoading: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Solicitação cancelada com sucesso.'),
                backgroundColor: DsCores.sucesso.accent,
              ),
            );
          }
        } else {
          final error = result['error'];
          String message =
              'Não foi possível cancelar agora. Tente novamente em alguns instantes.';
          if (error == 'not_found' || error == 'not_found_or_not_cancelable') {
            message =
                'Não foi possível cancelar esta solicitação. Ela pode já ter sido concluída ou alterada.';
          } else if (error == 'invalid_status') {
            message =
                'Esta solicitação não pode mais ser cancelada nesta etapa.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: DsCores.perigo.accent,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Não foi possível cancelar agora. Tente novamente em alguns instantes.',
            ),
            backgroundColor: DsCores.perigo.accent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
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
          onRefresh: () => _loadDetail(showLoading: false),
          color: DsCores.correcao.accent,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
                Text('Detalhe da alteração', style: DsTipografia.pageTitle),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe as informações detalhadas sobre a solicitação.',
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
        else if (_notFound || _request == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildNotFoundState(),
          )
        else ...[
          _buildSuccessSlivers(),
        ],
      ],
    );
  }

  Widget _buildSuccessSlivers() {
    final request = _request!;
    final presentation = AccountChangePresentation(request);
    final visualToken = presentation.visualToken;

    final hasJustification =
        request.justification != null &&
        request.justification!.trim().isNotEmpty;

    final hasRegisteredDates =
        request.holderConfirmedAt != null ||
        request.applicationStartedAt != null ||
        request.applicationCompletedAt != null;

    final isCompleted = request.status == AccountChangeStatus.completed;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, DsEspacamentos.xl),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // A. CARD STATUS ATUAL
          DsCard(
            showTopAccent: true,
            accentColor: visualToken.accent,
            borderColor: visualToken.border.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(DsEspacamentos.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill compacta
                DsSelo.fromCorVisual(
                  label: presentation.statusLabel,
                  token: visualToken,
                  icon: presentation.statusIcon,
                  compact: true,
                ),
                const SizedBox(height: DsEspacamentos.md),

                // Ícone + Título forte + Descrição
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsMolduraIcone(
                      icon: presentation.statusIcon,
                      accentColor: visualToken.accent,
                      size: DsTamanhos.iconFrameSm,
                      iconSize: DsTamanhos.iconSm,
                    ),
                    const SizedBox(width: DsEspacamentos.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            presentation.statusTitle,
                            style: DsTipografia.cardTitle,
                          ),
                          const SizedBox(height: DsEspacamentos.xs),
                          Text(
                            presentation.statusDescription,
                            style: DsTipografia.bodySmall.copyWith(
                              color: DsCores.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DsEspacamentos.md),

          // Prazo para Ação do Titular (Se aplicável)
          if (presentation.canShowHolderDeadline) ...[
            DsCard(
              borderColor: DsCores.alerta.border.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(DsEspacamentos.md),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.clockCountdown,
                    color: DsCores.alerta.accent,
                    size: 20,
                  ),
                  const SizedBox(width: DsEspacamentos.md),
                  Expanded(
                    child: Text(
                      presentation.holderDeadlineText ?? '',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsEspacamentos.md),
          ],

          // Orientação Pública Administrativa (Se aplicável)
          if (presentation.canShowPublicAdminGuidance) ...[
            _buildSectionHeader(
              icon: PhosphorIconsRegular.info,
              title: 'ORIENTAÇÃO DA ADMINISTRAÇÃO',
            ),
            const SizedBox(height: DsEspacamentos.sm),
            DsCard(
              borderColor: visualToken.border.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(DsEspacamentos.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (presentation.publicAdminReasonText != null)
                    Text(
                      presentation.publicAdminReasonText!,
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (presentation.publicAdminReasonText != null &&
                      presentation.publicAdminFeedbackText != null)
                    const SizedBox(height: DsEspacamentos.xs),
                  if (presentation.publicAdminFeedbackText != null)
                    Text(
                      presentation.publicAdminFeedbackText!,
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DsEspacamentos.md),
          ],

          // B. IDENTIFICAÇÃO
          _buildSectionHeader(
            icon: PhosphorIconsRegular.fingerprint,
            title: 'IDENTIFICAÇÃO',
          ),
          const SizedBox(height: DsEspacamentos.sm),
          DsCard(
            borderColor: DsCores.border.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(DsEspacamentos.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactDetailRow(
                  'Tipo da alteração',
                  presentation.typeLabel,
                ),
                const SizedBox(height: DsEspacamentos.md),
                _buildCompactDetailRow(
                  'Protocolo',
                  request.protocolNumber,
                  isSelectable: true,
                ),
                const SizedBox(height: DsEspacamentos.md),
                _buildCompactDetailRow(
                  'Data da solicitação',
                  ConecteaDateTimeHelper.formatProjectDateShort(
                    request.createdAt,
                  ),
                ),
                const SizedBox(height: DsEspacamentos.md),
                _buildCompactDetailRow(
                  'Última atualização',
                  ConecteaDateTimeHelper.formatProjectDateShort(
                    request.updatedAt,
                  ),
                  isLast:
                      !(request.status == AccountChangeStatus.underReview ||
                          request.status == AccountChangeStatus.applying),
                ),
                if (request.status == AccountChangeStatus.underReview ||
                    request.status == AccountChangeStatus.applying) ...[
                  const SizedBox(height: DsEspacamentos.md),
                  _buildCompactDetailRow(
                    'Previsão de análise',
                    'Até ${ConecteaDateTimeHelper.formatProjectDateShort(request.createdAt.add(const Duration(days: 10)))} (10 dias corridos)',
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: DsEspacamentos.md),

          // C. BLOCO ANTES -> DEPOIS (Delta)
          AccountChangeValueDelta(
            oldValueMasked: request.oldValueMasked,
            newValueMasked: request.newValueMasked,
            statusToken: visualToken,
            isCompleted: isCompleted,
          ),

          // D. JUSTIFICATIVA
          if (hasJustification) ...[
            const SizedBox(height: DsEspacamentos.md),
            _buildSectionHeader(
              icon: PhosphorIconsRegular.chatText,
              title: 'JUSTIFICATIVA INFORMADA',
            ),
            const SizedBox(height: DsEspacamentos.sm),
            DsCard(
              borderColor: DsCores.border.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(DsEspacamentos.md),
              child: Text(
                request.justification!.trim(),
                style: DsTipografia.body.copyWith(
                  color: DsCores.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // E. DATAS REGISTRADAS
          if (hasRegisteredDates) ...[
            const SizedBox(height: DsEspacamentos.md),
            _buildSectionHeader(
              icon: PhosphorIconsRegular.calendar,
              title: 'DATAS REGISTRADAS',
            ),
            const SizedBox(height: DsEspacamentos.sm),
            DsCard(
              borderColor: DsCores.border.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(DsEspacamentos.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (request.holderConfirmedAt != null)
                    _buildCompactDetailRow(
                      'Confirmação do titular',
                      ConecteaDateTimeHelper.formatProjectDateShort(
                        request.holderConfirmedAt!,
                      ),
                    ),
                  if (request.applicationStartedAt != null)
                    _buildCompactDetailRow(
                      'Aplicação iniciada',
                      ConecteaDateTimeHelper.formatProjectDateShort(
                        request.applicationStartedAt!,
                      ),
                      isLast: request.applicationCompletedAt == null,
                    ),
                  if (request.applicationCompletedAt != null)
                    _buildCompactDetailRow(
                      'Alteração concluída',
                      ConecteaDateTimeHelper.formatProjectDateShort(
                        request.applicationCompletedAt!,
                      ),
                      isLast: true,
                    ),
                ],
              ),
            ),
          ],

          // F. ENCERRAMENTO DA SOLICITAÇÃO (Se aplicável)
          if (presentation.canShowClosedAt) ...[
            const SizedBox(height: DsEspacamentos.md),
            _buildSectionHeader(
              icon: PhosphorIconsRegular.checkSquare,
              title: 'ENCERRAMENTO',
            ),
            const SizedBox(height: DsEspacamentos.sm),
            DsCard(
              borderColor: DsCores.border.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(DsEspacamentos.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactDetailRow(
                    presentation.closedAtLabel ?? 'Encerramento',
                    ConecteaDateTimeHelper.formatProjectDateShort(
                      request.closedAt!,
                    ),
                    isLast: !presentation.canShowResolutionReason,
                  ),
                  if (presentation.canShowResolutionReason) ...[
                    const SizedBox(height: DsEspacamentos.md),
                    _buildCompactDetailRow(
                      'Motivo',
                      presentation.resolutionReasonText ??
                          'Prazo ou cancelamento',
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // G. BOTÃO DE CANCELAMENTO DA SOLICITAÇÃO (Se aplicável)
          if (presentation.canCancelByHolder) ...[
            const SizedBox(height: DsEspacamentos.lg),
            DsBotao(
              label: 'Cancelar solicitação',
              onPressed: _isCancelling ? null : _handleCancel,
              variante: DsBotaoVariante.perigo,
              icon: PhosphorIconsRegular.xCircle,
              isLoading: _isCancelling,
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
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
    );
  }

  Widget _buildCompactDetailRow(
    String label,
    String value, {
    bool isSelectable = false,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DsTipografia.caption.copyWith(color: DsCores.textMuted),
        ),
        const SizedBox(height: 2),
        Wrap(
          children: [
            isSelectable
                ? SelectableText(
                    value,
                    style: DsTipografia.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DsCores.textPrimary,
                    ),
                  )
                : Text(
                    value,
                    style: DsTipografia.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DsCores.textPrimary,
                    ),
                  ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: DsEspacamentos.sm),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
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
            label: 'Carregando detalhes...',
            child: Text(
              'Carregando detalhes...',
              style: TextStyle(color: DsCores.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
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
                'Alteração não encontrada',
                style: DsTipografia.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Este protocolo não está disponível ou não pertence mais à sua conta.',
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              DsBotao(
                label: 'Voltar',
                onPressed: () => Navigator.pop(context),
                variante: DsBotaoVariante.acao,
                token: DsCores.perigo,
                icon: PhosphorIconsRegular.arrowLeft,
              ),
            ],
          ),
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
                onPressed: () => _loadDetail(showLoading: true),
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
}
