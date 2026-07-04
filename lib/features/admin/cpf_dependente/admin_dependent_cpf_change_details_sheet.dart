import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_summary.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_sensitive_review.dart';
import 'package:conectea/features/admin/cpf_dependente/services/admin_dependent_cpf_changes_repository.dart';

class AdminDependentCpfChangeDetailsSheet extends StatefulWidget {
  final AdminDependentCpfChangeSummary summary;

  const AdminDependentCpfChangeDetailsSheet({super.key, required this.summary});

  @override
  State<AdminDependentCpfChangeDetailsSheet> createState() => _AdminDependentCpfChangeDetailsSheetState();
}

class _AdminDependentCpfChangeDetailsSheetState extends State<AdminDependentCpfChangeDetailsSheet> {
  late final AdminDependentCpfChangesRepository _repository;
  bool _isLoading = true;
  String? _errorMessage;
  AdminDependentCpfChangeSensitiveReview? _review;

  @override
  void initState() {
    super.initState();
    _repository = AdminDependentCpfChangesRepository();
    _loadSensitiveReview();
  }

  Future<void> _loadSensitiveReview() async {
    final isEditable = [
      AccountChangeStatus.underReview,
      AccountChangeStatus.waitingDocumentReplacement,
      AccountChangeStatus.waitingCpfCorrection,
    ].contains(widget.summary.status);

    if (!isEditable) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final res = await _repository.getDependentCpfChangeSensitiveReview(
        requestId: widget.summary.id,
      );

      if (mounted) {
        setState(() {
          _review = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatCpf(String? cpf) {
    if (cpf == null || cpf.trim().isEmpty) return 'Não informado';
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 11) return cpf;
    return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
  }

  String _getStatusLabel(AccountChangeStatus status) {
    switch (status) {
      case AccountChangeStatus.underReview:
        return 'Em análise';
      case AccountChangeStatus.waitingDocumentReplacement:
        return 'Aguardando doc.';
      case AccountChangeStatus.waitingCpfCorrection:
        return 'Corrigir CPF';
      case AccountChangeStatus.completed:
        return 'Concluída';
      case AccountChangeStatus.rejectedByAdmin:
        return 'Rejeitada';
      case AccountChangeStatus.cancelledByHolder:
        return 'Cancelada';
      case AccountChangeStatus.expired:
        return 'Expirada';
      case AccountChangeStatus.applicationFailed:
        return 'Falha';
      case AccountChangeStatus.applying:
        return 'Processando';
      default:
        return 'Desconhecido';
    }
  }

  DsTokenStatus _getStatusToken(AccountChangeStatus status) {
    switch (status) {
      case AccountChangeStatus.underReview:
        return DsTokenStatus.waitingApproval;
      case AccountChangeStatus.waitingCpfCorrection:
        return DsTokenStatus.reviewingData;
      case AccountChangeStatus.waitingDocumentReplacement:
        return DsTokenStatus.waitingDocs;
      case AccountChangeStatus.completed:
        return DsTokenStatus.active;
      case AccountChangeStatus.rejectedByAdmin:
        return DsTokenStatus.rejected;
      case AccountChangeStatus.cancelledByHolder:
      case AccountChangeStatus.expired:
        return DsTokenStatus.expired;
      case AccountChangeStatus.applicationFailed:
        return DsTokenStatus.rejected;
      case AccountChangeStatus.applying:
        return DsTokenStatus.waitingDocs;
      default:
        return DsTokenStatus.fallback;
    }
  }

  String _formatDateTime(DateTime dt) {
    final dateStr = ConecteaDateTimeHelper.formatProjectDateShort(dt);
    final timeStr = ConecteaDateTimeHelper.formatProjectTime(dt);
    return '$dateStr às $timeStr';
  }

  String _translateDocumentState(String? state) {
    if (state == null || state.trim().isEmpty) return 'Não informado';
    final clean = state.trim().toLowerCase();
    switch (clean) {
      case 'available':
        return 'Disponível para análise';
      case 'discarded':
        return 'Descartado';
      case 'replaced':
        return 'Substituído';
      case 'unavailable':
        return 'Indisponível';
      case 'none':
        return 'Não enviado';
      default:
        return 'Não informado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusToken = _getStatusToken(widget.summary.status);
    final statusColor = statusToken.primary;
    final statusIcon = statusToken.icon;


    final bool canView = _review != null && _review!.canView;
    final bool canViewDocument = _review != null && _review!.canViewDocument;

    // Regra do documento
    String documentStatusText;
    IconData documentIcon;
    Color documentColor;

    if (canViewDocument) {
      documentStatusText = 'Documento disponível para análise';
      documentIcon = PhosphorIconsRegular.fileText;
      documentColor = DsCores.sucesso.accent;
    } else {
      documentStatusText = 'Documento indisponível ou já descartado';
      documentIcon = PhosphorIconsRegular.fileX;
      documentColor = DsCores.textMuted;
    }

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: const BoxDecoration(
        color: DsCores.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DsRaios.modal),
          topRight: Radius.circular(DsRaios.modal),
        ),
      ),
      child: Column(
        children: [
          // Header Fixo
          Container(
            padding: const EdgeInsets.all(DsEspacamentos.lg),
            decoration: const BoxDecoration(
              color: DsCores.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DsRaios.modal),
                topRight: Radius.circular(DsRaios.modal),
              ),
              border: Border(
                bottom: BorderSide(color: DsCores.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DsCores.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: DsEspacamentos.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Análise de CPF',
                      style: DsTipografia.sectionTitle.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        PhosphorIconsRegular.x,
                        color: DsCores.textSecondary,
                        size: DsTamanhos.iconSm,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(
                          DsTamanhos.minTouchTarget,
                          DsTamanhos.minTouchTarget,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Corpo Rolável
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: DsEspacamentos.lg,
                right: DsEspacamentos.lg,
                top: DsEspacamentos.lg,
                bottom: MediaQuery.paddingOf(context).bottom + DsEspacamentos.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bloco de Protocolo e Status
                  DsCard(
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    margin: EdgeInsets.zero,
                    accentColor: statusColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROTOCOLO',
                          style: DsTipografia.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: DsCores.textMuted,
                          ),
                        ),
                        const SizedBox(height: DsEspacamentos.xs),
                        Text(
                          '#${widget.summary.protocolNumber}',
                          style: DsTipografia.cardTitle.copyWith(
                            color: DsCores.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: DsEspacamentos.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              DsSelo(
                                label: _getStatusLabel(widget.summary.status).toUpperCase(),
                                labelColor: statusColor,
                                backgroundColor: statusColor.withValues(alpha: 0.12),
                                borderColor: statusColor.withValues(alpha: 0.25),
                                icon: statusIcon,
                                iconColor: statusColor,
                                compact: true,
                              ),
                              DsSelo(
                                label: 'DEPENDENTE',
                                labelColor: DsCores.alerta.accent,
                                backgroundColor: DsCores.alerta.softBackground,
                                borderColor: DsCores.alerta.border,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Identificação Consolidada
                  Text(
                    'IDENTIFICAÇÃO',
                    style: DsTipografia.sectionLabel.copyWith(
                      color: DsCores.textMuted,
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.sm),
                  DsCard(
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dependente
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.user,
                              color: DsCores.alerta.accent,
                              size: DsTamanhos.iconSm,
                            ),
                            const SizedBox(width: DsEspacamentos.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.summary.dependentFullName,
                                    style: DsTipografia.body.copyWith(
                                      color: DsCores.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Beneficiário Dependente',
                                    style: DsTipografia.caption.copyWith(
                                      color: DsCores.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: DsEspacamentos.md),
                          child: Divider(color: DsCores.border, height: 1),
                        ),
                        // Titular da Conta
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.users,
                              color: DsCores.conta.accent,
                              size: DsTamanhos.iconSm,
                            ),
                            const SizedBox(width: DsEspacamentos.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.summary.userFirstName,
                                    style: DsTipografia.body.copyWith(
                                      color: DsCores.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.summary.userEmailMasked.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Titular da Conta • ${widget.summary.userEmailMasked}',
                                      style: DsTipografia.caption.copyWith(
                                        color: DsCores.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Valores da Revisão
                  Text(
                    'VALORES DA REVISÃO',
                    style: DsTipografia.sectionLabel.copyWith(
                      color: DsCores.textMuted,
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.sm),

                  DsCard(
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    margin: EdgeInsets.zero,
                    child: _isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: DsEspacamentos.md,
                              ),
                              child: Column(
                                children: [
                                  const DsLoadingSpinner(),
                                  const SizedBox(height: DsEspacamentos.md),
                                  Text(
                                    'Carregando dados para análise...',
                                    style: DsTipografia.caption.copyWith(
                                      color: DsCores.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (canView) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: DsCores.perigo.softBackground,
                                    borderRadius: BorderRadius.circular(DsRaios.sm),
                                    border: Border.all(color: DsCores.perigo.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.shieldCheck,
                                        color: DsCores.perigo.accent,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Dados sensíveis sob auditoria',
                                          style: DsTipografia.caption.copyWith(
                                            color: DsCores.perigo.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // CPF Anterior
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    canView ? 'CPF ATUAL' : 'CPF ANTERIOR',
                                    style: DsTipografia.caption.copyWith(
                                      fontSize: 10,
                                      color: DsCores.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: DsEspacamentos.xs),
                                  Text(
                                    canView
                                        ? _formatCpf(_review!.oldCpfClear)
                                        : widget.summary.currentCpfMasked,
                                    style: DsTipografia.body.copyWith(
                                      color: DsCores.textPrimary.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: DsEspacamentos.md),
                                child: Divider(color: DsCores.border, height: 1),
                              ),

                              // CPF Solicitado
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CPF SOLICITADO',
                                    style: DsTipografia.caption.copyWith(
                                      fontSize: 10,
                                      color: DsCores.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: DsEspacamentos.xs),
                                  Text(
                                    canView
                                        ? _formatCpf(_review!.newCpfClear)
                                        : widget.summary.requestedCpfMasked,
                                    style: DsTipografia.body.copyWith(
                                      color: DsCores.alerta.accent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),

                              if (!canView && !_isLoading) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: DsEspacamentos.md),
                                  child: Divider(color: DsCores.border, height: 1),
                                ),
                                Text(
                                  _errorMessage ?? 'Dados sensíveis indisponíveis para este status.',
                                  style: DsTipografia.caption.copyWith(
                                    color: DsCores.perigo.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Documento
                  Text(
                    'DOCUMENTO DE IDENTIDADE',
                    style: DsTipografia.sectionLabel.copyWith(
                      color: DsCores.textMuted,
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.sm),
                  DsCard(
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              documentIcon,
                              color: documentColor,
                              size: DsTamanhos.iconSm,
                            ),
                            const SizedBox(width: DsEspacamentos.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    documentStatusText,
                                    style: DsTipografia.bodySmall.copyWith(
                                      color: DsCores.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_review != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Estado: ${_translateDocumentState(_review!.documentState)}',
                                      style: DsTipografia.caption.copyWith(
                                        color: DsCores.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Linha do Tempo
                  Text(
                    'LINHA DO TEMPO E PRAZOS',
                    style: DsTipografia.sectionLabel.copyWith(
                      color: DsCores.textMuted,
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.sm),
                  DsCard(
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildTimelineItem(
                          label: 'Solicitação criada',
                          value: _formatDateTime(widget.summary.createdAt),
                        ),
                        const Divider(
                          color: DsCores.border,
                          height: DsEspacamentos.lg,
                        ),
                        _buildTimelineItem(
                          label: 'Última atualização',
                          value: _formatDateTime(widget.summary.updatedAt),
                        ),
                        if (widget.summary.completedAt != null) ...[
                          const Divider(
                            color: DsCores.border,
                            height: DsEspacamentos.lg,
                          ),
                          _buildTimelineItem(
                            label: 'Concluída em',
                            value: _formatDateTime(widget.summary.completedAt!),
                            valueColor: DsCores.sucesso.accent,
                          ),
                        ] else if (widget.summary.cancelledAt != null) ...[
                          const Divider(
                            color: DsCores.border,
                            height: DsEspacamentos.lg,
                          ),
                          _buildTimelineItem(
                            label: 'Cancelada em',
                            value: _formatDateTime(widget.summary.cancelledAt!),
                            valueColor: DsCores.textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Ações Administrativas
                  Text(
                    'AÇÕES ADMINISTRATIVAS',
                    style: DsTipografia.sectionLabel.copyWith(
                      color: DsCores.textMuted,
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    decoration: BoxDecoration(
                      color: DsCores.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(DsRaios.md),
                      border: Border.all(
                        color: DsCores.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.info,
                          color: DsCores.textMuted,
                          size: DsTamanhos.iconSm,
                        ),
                        const SizedBox(width: DsEspacamentos.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Operações Indisponíveis',
                                style: DsTipografia.bodySmall.copyWith(
                                  color: DsCores.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: DsEspacamentos.xxs),
                              Text(
                                'As ações administrativas para CPF de dependente serão liberadas em uma próxima etapa.',
                                style: DsTipografia.caption.copyWith(
                                  color: DsCores.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildTimelineItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: DsTipografia.caption.copyWith(
              color: DsCores.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: DsTipografia.caption.copyWith(
            color: valueColor ?? DsCores.textPrimary.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
