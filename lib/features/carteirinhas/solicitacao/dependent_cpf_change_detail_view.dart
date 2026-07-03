import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/carteirinhas/solicitacao/dependent_cpf_change_presentation.dart';
import 'package:conectea/models/dependent_cpf_change_request.dart';

class DependentCpfChangeDetailView extends StatelessWidget {
  final DependentCpfChangeRequest request;
  final VoidCallback onBack;

  const DependentCpfChangeDetailView({
    super.key,
    required this.request,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Como a tela de detalhes é renderizada embutida na aba sob a HomePage,
    // não criamos um Scaffold ou AppBackground aninhados. Isso evita duplicações de SafeAreas
    // e gradientes. Retornamos o corpo da view que se integrará diretamente ao Scaffold da HomePage.
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    final presentation = DependentCpfChangePresentation(request);
    final visualToken = presentation.visualToken;

    final hasFeedback = request.adminFeedback != null && request.adminFeedback!.trim().isNotEmpty;
    final isCompleted = request.status.toLowerCase() == 'completed';

    final hasRegisteredDates = request.completedAt != null || request.cancelledAt != null;

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
                DsBotaoVoltar(onPressed: onBack),
                const SizedBox(height: 24),
                Text('Detalhe da alteração', style: DsTipografia.pageTitle),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe as informações detalhadas sobre a sua solicitação.',
                  style: DsTipografia.pageSubtitle,
                ),
              ],
            ),
          ),
        ),

        // 2. Conteúdo da tela de detalhes
        SliverPadding(
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
                    DsSelo.fromCorVisual(
                      label: presentation.statusLabel,
                      token: visualToken,
                      icon: presentation.statusIcon,
                      compact: true,
                    ),
                    const SizedBox(height: DsEspacamentos.md),
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

              // B. CARD DE PRAZO/ALERTA (Se aplicável)
              if (presentation.canShowDeadline) ...[
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
                          presentation.deadlineText ?? '',
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

              // C. ORIENTAÇÃO DA ADMINISTRAÇÃO (Se aplicável)
              if (hasFeedback) ...[
                _buildSectionHeader(
                  icon: PhosphorIconsRegular.info,
                  title: 'ORIENTAÇÃO DA ADMINISTRAÇÃO',
                ),
                const SizedBox(height: DsEspacamentos.sm),
                DsCard(
                  borderColor: visualToken.border.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(DsEspacamentos.md),
                  child: Text(
                    request.adminFeedback!.trim(),
                    style: DsTipografia.bodySmall.copyWith(
                      color: DsCores.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: DsEspacamentos.md),
              ],

              // D. IDENTIFICAÇÃO da Solicitação
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
                      'Alteração de CPF do dependente',
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
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.createdAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.createdAt)}',
                    ),
                    const SizedBox(height: DsEspacamentos.md),
                    _buildCompactDetailRow(
                      'Última atualização',
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.updatedAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.updatedAt)}',
                      isLast: request.expiresAt == null,
                    ),
                    if (request.expiresAt != null) ...[
                      const SizedBox(height: DsEspacamentos.md),
                      _buildCompactDetailRow(
                        'Previsão de análise',
                        'Até ${ConecteaDateTimeHelper.formatProjectDateShort(request.expiresAt!)} (10 dias corridos)',
                        isLast: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DsEspacamentos.md),

              // E. BLOCO COMPARATIVO (Alteração solicitada)
              _buildSectionHeader(
                icon: PhosphorIconsRegular.pencilSimpleLine,
                title: 'ALTERAÇÃO SOLICITADA',
              ),
              const SizedBox(height: DsEspacamentos.sm),
              _buildValueDeltaBlock(isCompleted, visualToken),
              const SizedBox(height: DsEspacamentos.md),

              // F. DATAS REGISTRADAS
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
                    _buildCompactDetailRow(
                      'Solicitação aberta',
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.createdAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.createdAt)}',
                    ),
                    const SizedBox(height: DsEspacamentos.md),
                    _buildCompactDetailRow(
                      'Última atualização',
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.updatedAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.updatedAt)}',
                      isLast: request.expiresAt == null && request.completedAt == null && request.cancelledAt == null,
                    ),
                    if (request.expiresAt != null) ...[
                      const SizedBox(height: DsEspacamentos.md),
                      _buildCompactDetailRow(
                        'Previsão de análise',
                        'Até ${ConecteaDateTimeHelper.formatProjectDateShort(request.expiresAt!)} (10 dias corridos)',
                        isLast: request.completedAt == null && request.cancelledAt == null,
                      ),
                    ],
                    if (request.completedAt != null) ...[
                      const SizedBox(height: DsEspacamentos.md),
                      _buildCompactDetailRow(
                        'Concluída em',
                        '${ConecteaDateTimeHelper.formatProjectDateShort(request.completedAt!)} às ${ConecteaDateTimeHelper.formatProjectTime(request.completedAt!)}',
                        isLast: true,
                      ),
                    ],
                    if (request.cancelledAt != null) ...[
                      const SizedBox(height: DsEspacamentos.md),
                      _buildCompactDetailRow(
                        'Cancelada em',
                        '${ConecteaDateTimeHelper.formatProjectDateShort(request.cancelledAt!)} às ${ConecteaDateTimeHelper.formatProjectTime(request.cancelledAt!)}',
                        isLast: true,
                      ),
                    ],
                  ],
                ),
              ),

              // G. ENCERRAMENTO DA SOLICITAÇÃO (Se aplicável)
              if (hasRegisteredDates && presentation.closedAtText != null) ...[
                const SizedBox(height: DsEspacamentos.md),
                _buildSectionHeader(
                  icon: PhosphorIconsRegular.checkSquare,
                  title: 'ENCERRAMENTO',
                ),
                const SizedBox(height: DsEspacamentos.sm),
                DsCard(
                  borderColor: DsCores.border.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(DsEspacamentos.md),
                  child: _buildCompactDetailRow(
                    presentation.closedAtLabel ?? 'Encerramento',
                    presentation.closedAtText!,
                    isLast: true,
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
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
        if (!isLast) const SizedBox(height: DsEspacamentos.sm),
      ],
    );
  }

  Widget _buildValueDeltaBlock(bool isCompleted, DsCorVisual statusToken) {
    final hasOldValue = request.currentCpfMasked != null && request.currentCpfMasked!.trim().isNotEmpty;
    final targetToken = isCompleted ? DsCores.sucesso : statusToken;

    return DsCard(
      borderColor: DsCores.border.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(DsEspacamentos.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção ANTES
          if (hasOldValue) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANTES',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.currentCpfMasked!,
                  style: DsTipografia.bodySmall.copyWith(
                    color: DsCores.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsEspacamentos.sm),
            Center(
              child: Icon(
                PhosphorIconsRegular.arrowDown,
                color: DsCores.textMuted.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
            const SizedBox(height: DsEspacamentos.sm),
          ],

          // Seção DEPOIS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DsEspacamentos.sm),
            decoration: BoxDecoration(
              color: targetToken.softBackground,
              borderRadius: BorderRadius.circular(DsRaios.sm),
              border: Border.all(color: targetToken.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEPOIS',
                  style: DsTipografia.caption.copyWith(
                    color: targetToken.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.requestedCpfMasked ?? '***.***.***-XX',
                  style: DsTipografia.body.copyWith(
                    color: DsCores.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
