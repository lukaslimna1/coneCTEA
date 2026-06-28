import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_summary.dart';
import 'package:conectea/services/database_service.dart';

class AdminCpfChangeDetailsSheet extends StatefulWidget {
  final AdminCpfChangeSummary summary;

  const AdminCpfChangeDetailsSheet({super.key, required this.summary});

  @override
  State<AdminCpfChangeDetailsSheet> createState() => _AdminCpfChangeDetailsSheetState();
}

class _AdminCpfChangeDetailsSheetState extends State<AdminCpfChangeDetailsSheet> {
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = true;
  bool _canView = false;
  String? _oldCpfClear;
  String? _newCpfClear;
  bool _canViewDocument = false;
  String? _documentFileId;

  @override
  void initState() {
    super.initState();
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
          _canView = false;
        });
      }
      return;
    }

    try {
      final res = await _databaseService.getCpfChangeSensitiveReview(
        requestId: widget.summary.id,
      );
      if (mounted) {
        setState(() {
          _canView = res['can_view'] == true;
          if (_canView) {
            _oldCpfClear = res['old_cpf_clear'];
            _newCpfClear = res['new_cpf_clear'];
            _canViewDocument = res['can_view_document'] == true;
            _documentFileId = res['document_file_id'];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _canView = false;
        });
      }
    }
  }

  Future<void> _openDocument(String fileId) async {
    try {
      final url = 'https://drive.google.com/file/d/$fileId/view?usp=drivesdk';
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String _formatCpf(String? cpf) {
    if (cpf == null) return 'Não informado';
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
      case AccountChangeStatus.waitingHolderConfirmation:
        return 'Confirmar';
      case AccountChangeStatus.applying:
        return 'Processando';
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
      case AccountChangeStatus.waitingHolderConfirmation:
        return DsTokenStatus.renewing;
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

  String _formatCivilDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'Não informado';
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

  @override
  Widget build(BuildContext context) {
    final statusToken = _getStatusToken(widget.summary.status);
    final statusColor = statusToken.primary;
    final isEditable = [
      AccountChangeStatus.underReview,
      AccountChangeStatus.waitingDocumentReplacement,
      AccountChangeStatus.waitingCpfCorrection,
    ].contains(widget.summary.status);

    // Regra do documento
    String documentStatusText;
    IconData documentIcon;
    Color documentColor;

    if (!widget.summary.hasDocument) {
      documentStatusText = 'Documento não informado';
      documentIcon = PhosphorIconsRegular.fileX;
      documentColor = DsCores.textMuted;
    } else if (isEditable) {
      documentStatusText = 'Documento informado para análise';
      documentIcon = PhosphorIconsRegular.fileText;
      documentColor = DsCores.sucesso.accent;
    } else {
      documentStatusText = 'Documento pode estar indisponível ou descartado';
      documentIcon = PhosphorIconsRegular.trash;
      documentColor = DsCores.textSecondary.withValues(alpha: 0.6);
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
                // Handle centralizado
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
                bottom:
                    MediaQuery.paddingOf(context).bottom + DsEspacamentos.xl,
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
                          child: DsSelo(
                            label: _getStatusLabel(
                              widget.summary.status,
                            ).toUpperCase(),
                            labelColor: statusColor,
                            backgroundColor: statusColor.withValues(
                              alpha: 0.12,
                            ),
                            borderColor: statusColor.withValues(alpha: 0.25),
                            icon: statusToken.icon,
                            iconColor: statusColor,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Titular da Conta
                  Text(
                    'TITULAR DA CONTA',
                    style: DsTipografia.sectionLabel.copyWith(
                      color: DsCores.textMuted,
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.sm),
                  DsCard(
                    padding: const EdgeInsets.all(DsEspacamentos.md),
                    margin: EdgeInsets.zero,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DsCores.conta.softBackground,
                            borderRadius: BorderRadius.circular(DsRaios.sm),
                            border: Border.all(color: DsCores.conta.border),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.user,
                            color: DsCores.conta.accent,
                            size: DsTamanhos.iconSm,
                          ),
                        ),
                        const SizedBox(width: DsEspacamentos.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.summary.userFirstName.toUpperCase(),
                                style: DsTipografia.body.copyWith(
                                  color: DsCores.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.summary.userEmailMasked.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.summary.userEmailMasked,
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
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Alteração de CPF
                  Text(
                    _canView ? 'DADOS PARA ANÁLISE' : 'VALORES DA REVISÃO',
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
                              child: Text(
                                'Carregando dados para análise...',
                                style: DsTipografia.caption.copyWith(
                                  color: DsCores.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CPF Anterior / CPF atual
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _canView ? 'CPF ATUAL' : 'CPF ANTERIOR',
                                    style: DsTipografia.caption.copyWith(
                                      fontSize: 10,
                                      color: DsCores.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: DsEspacamentos.xs),
                                  Text(
                                    _canView
                                        ? _formatCpf(_oldCpfClear)
                                        : (widget.summary.oldValueMasked ?? 'Não informado'),
                                    style: DsTipografia.body.copyWith(
                                      color: DsCores.textPrimary.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: DsEspacamentos.md,
                                ),
                                child: Divider(color: DsCores.border, height: 1),
                              ),
                              // CPF Novo / CPF solicitado
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _canView ? 'CPF SOLICITADO' : 'NOVO CPF SOLICITADO',
                                    style: DsTipografia.caption.copyWith(
                                      fontSize: 10,
                                      color: DsCores.conta.accent.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: DsEspacamentos.xs),
                                  Text(
                                    _canView
                                        ? _formatCpf(_newCpfClear)
                                        : (widget.summary.newValueMasked ?? 'Não informado'),
                                    style: DsTipografia.body.copyWith(
                                      color: DsCores.conta.accent,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_canView && !_isLoading) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: DsEspacamentos.md,
                                  ),
                                  child: Divider(color: DsCores.border, height: 1),
                                ),
                                Text(
                                  'Dados sensíveis indisponíveis para este status.',
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

                  // Seção: Documento Comprobatório
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
                              child: Text(
                                documentStatusText,
                                style: DsTipografia.bodySmall.copyWith(
                                  color: DsCores.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_canViewDocument && _documentFileId != null && _documentFileId!.isNotEmpty) ...[
                          const SizedBox(height: DsEspacamentos.md),
                          DsBotao(
                            label: 'Abrir documento',
                            variante: DsBotaoVariante.secundario,
                            icon: PhosphorIconsRegular.arrowSquareOut,
                            onPressed: () => _openDocument(_documentFileId!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Prazos e Datas
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
                        if (widget.summary.adminDeadlineDueDate != null) ...[
                          const Divider(
                            color: DsCores.border,
                            height: DsEspacamentos.lg,
                          ),
                          _buildTimelineItem(
                            label: 'Prazo limite da análise admin',
                            value: _formatCivilDate(
                              widget.summary.adminDeadlineDueDate,
                            ),
                            valueColor: widget.summary.isOverdue
                                ? DsCores.perigo.accent
                                : DsCores.alerta.accent,
                          ),
                        ],
                        if (widget.summary.holderDeadlineDueDate != null) ...[
                          const Divider(
                            color: DsCores.border,
                            height: DsEspacamentos.lg,
                          ),
                          _buildTimelineItem(
                            label: 'Prazo limite de resposta do titular',
                            value: _formatCivilDate(
                              widget.summary.holderDeadlineDueDate,
                            ),
                            valueColor: DsCores.conta.accent,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: DsEspacamentos.lg),

                  // Seção: Ações da Solicitação
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
                                'As ações administrativas serão conectadas em uma próxima etapa.',
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
