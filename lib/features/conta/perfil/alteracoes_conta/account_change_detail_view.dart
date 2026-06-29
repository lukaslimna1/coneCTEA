import 'dart:math';

import 'package:conectea/core/campos_cadastrais/campos/campo_cpf.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/widgets/account_change_value_delta.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/google_drive_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  // Variáveis para as novas ações
  bool _isSubmittingDocument = false;
  bool _isSubmittingCpf = false;
  final TextEditingController _correctionCpfController =
      TextEditingController();
  final GlobalKey<FormState> _correctionFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _correctionCpfController.dispose();
    super.dispose();
  }

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
      forceVerticalActions: true,
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
            DsFeedback.showSnackBar(
              context: context,
              mensagem: 'Solicitação cancelada com sucesso.',
              tipo: DsFeedbackTipo.sucesso,
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
          DsFeedback.showSnackBar(
            context: context,
            mensagem: message,
            tipo: DsFeedbackTipo.erro,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        DsFeedback.showSnackBar(
          context: context,
          mensagem: 'Ocorreu um erro ao cancelar. Tente novamente mais tarde.',
          tipo: DsFeedbackTipo.erro,
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

  String _buildSafeDriveFileName(String extension) {
    final random = Random.secure();
    final randomVal = random.nextInt(65536);
    final hex = randomVal.toRadixString(16).padLeft(4, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ctea_anx_${timestamp}_$hex.$extension';
  }

  void _showFeedback(String message, DsFeedbackTipo tipo) {
    DsFeedback.showSnackBar(context: context, mensagem: message, tipo: tipo);
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'expired':
        return 'Seu prazo para concluir esta etapa expirou.';
      case 'invalid_status':
        return 'Essa solicitação não está mais aguardando esta ação.';
      case 'invalid_document':
        return 'Não foi possível validar o documento enviado.';
      case 'missing_document':
        return 'Documento não encontrado. Tente enviar novamente.';
      case 'invalid_cpf':
        return 'O CPF informado não parece válido.';
      case 'cpf_unchanged':
        return 'Informe um CPF diferente do CPF atual.';
      case 'cpf_conflict':
        return 'Não foi possível usar esse CPF. Verifique os dados informados.';
      case 'forbidden':
        return 'Você não tem permissão para alterar esta solicitação.';
      case 'unauthenticated':
        return 'Sessão expirada. Entre novamente.';
      case 'temporarily_unavailable':
      case 'internal_error':
      default:
        return 'Não foi possível concluir agora. Tente novamente.';
    }
  }

  Future<void> _handleReplaceDocument(AccountChangeRequest request) async {
    if (_isSubmittingDocument) return;

    PlatformFile? selectedFile;
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return;
      selectedFile = result.files.first;

      const maxFileSize = 5 * 1024 * 1024; // 5MB
      if (selectedFile.size > maxFileSize) {
        _showFeedback(
          'O arquivo excede o limite máximo de 5MB.',
          DsFeedbackTipo.erro,
        );
        return;
      }
    } catch (_) {
      _showFeedback(
        'Não foi possível selecionar o arquivo.',
        DsFeedbackTipo.erro,
      );
      return;
    }

    setState(() {
      _isSubmittingDocument = true;
    });

    String? uploadedDriveUrl;
    try {
      final ext = selectedFile.extension?.toLowerCase() ?? 'pdf';
      final fileName = _buildSafeDriveFileName(ext);
      uploadedDriveUrl = await GoogleDriveService().uploadFile(
        file: selectedFile,
        fileName: fileName,
      );

      if (uploadedDriveUrl == null || uploadedDriveUrl.isEmpty) {
        _showFeedback(
          'Não foi possível enviar o documento. Tente novamente.',
          DsFeedbackTipo.erro,
        );
        return;
      }

      final fileId = GoogleDriveService().extractFileId(uploadedDriveUrl);
      if (fileId == null || fileId.isEmpty) {
        await GoogleDriveService().deleteFile(uploadedDriveUrl);
        _showFeedback(
          'Não foi possível preparar o documento. Tente novamente.',
          DsFeedbackTipo.erro,
        );
        return;
      }

      final result = await _databaseService.submitCpfDocumentReplacement(
        requestId: request.id,
        documentFileId: fileId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showFeedback('Documento enviado com sucesso.', DsFeedbackTipo.sucesso);
        await _loadDetail(showLoading: true);
      } else {
        await GoogleDriveService().deleteFile(uploadedDriveUrl);
        final errorCode = result['error_code'] ?? 'internal_error';
        _showFeedback(_getErrorMessage(errorCode), DsFeedbackTipo.erro);
        if (errorCode == 'expired' || errorCode == 'invalid_status') {
          await _loadDetail(showLoading: true);
        }
      }
    } catch (_) {
      if (uploadedDriveUrl != null) {
        await GoogleDriveService().deleteFile(uploadedDriveUrl);
      }
      if (mounted) {
        _showFeedback(
          'Erro inesperado. Tente novamente mais tarde.',
          DsFeedbackTipo.erro,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingDocument = false;
        });
      }
    }
  }

  Future<void> _handleCorrectCpf(AccountChangeRequest request) async {
    if (_isSubmittingCpf) return;

    if (!_correctionFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmittingCpf = true;
    });

    try {
      final cpfVal = _correctionCpfController.text;
      final result = await _databaseService.submitCpfCorrection(
        requestId: request.id,
        newCpf: cpfVal,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showFeedback('CPF corrigido com sucesso.', DsFeedbackTipo.sucesso);
        _correctionCpfController.clear();
        await _loadDetail(showLoading: true);
      } else {
        final errorCode = result['error_code'] ?? 'internal_error';
        _showFeedback(_getErrorMessage(errorCode), DsFeedbackTipo.erro);
        if (errorCode == 'expired' || errorCode == 'invalid_status') {
          await _loadDetail(showLoading: true);
        }
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(
          'Erro inesperado. Tente novamente mais tarde.',
          DsFeedbackTipo.erro,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingCpf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsLoadingOverlay(
        isLoading: _isSubmittingDocument || _isSubmittingCpf,
        message: _isSubmittingDocument
            ? 'Enviando documento...'
            : 'Enviando correção...',
        child: AppBackground(
          child: RefreshIndicator(
            onRefresh: () => _loadDetail(showLoading: false),
            color: DsCores.correcao.accent,
            child: _buildBody(),
          ),
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
                  '${ConecteaDateTimeHelper.formatProjectDateShort(request.createdAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.createdAt)}',
                ),
                const SizedBox(height: DsEspacamentos.md),
                _buildCompactDetailRow(
                  request.status == AccountChangeStatus.cancelledByHolder
                      ? 'Cancelado em'
                      : 'Última atualização',
                  request.status == AccountChangeStatus.cancelledByHolder
                      ? '${ConecteaDateTimeHelper.formatProjectDateShort(request.closedAt ?? request.updatedAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.closedAt ?? request.updatedAt)}'
                      : '${ConecteaDateTimeHelper.formatProjectDateShort(request.updatedAt)} às ${ConecteaDateTimeHelper.formatProjectTime(request.updatedAt)}',
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

          if (request.type == AccountChangeType.cpf &&
              request.status ==
                  AccountChangeStatus.waitingHolderConfirmation) ...[
            const SizedBox(height: DsEspacamentos.md),
            _buildConfirmationSection(request, visualToken),
          ],

          // AÇÕES DO SOLICITANTE
          if (request.type == AccountChangeType.cpf &&
              request.status ==
                  AccountChangeStatus.waitingDocumentReplacement) ...[
            const SizedBox(height: DsEspacamentos.md),
            _buildDocumentReplacementSection(request, visualToken),
          ],

          if (request.type == AccountChangeType.cpf &&
              request.status == AccountChangeStatus.waitingCpfCorrection) ...[
            const SizedBox(height: DsEspacamentos.md),
            _buildCpfCorrectionSection(request, visualToken),
          ],

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
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.holderConfirmedAt!)} às ${ConecteaDateTimeHelper.formatProjectTime(request.holderConfirmedAt!)}',
                    ),
                  if (request.applicationStartedAt != null)
                    _buildCompactDetailRow(
                      'Aplicação iniciada',
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.applicationStartedAt!)} às ${ConecteaDateTimeHelper.formatProjectTime(request.applicationStartedAt!)}',
                      isLast: request.applicationCompletedAt == null,
                    ),
                  if (request.applicationCompletedAt != null)
                    _buildCompactDetailRow(
                      'Alteração concluída',
                      '${ConecteaDateTimeHelper.formatProjectDateShort(request.applicationCompletedAt!)} às ${ConecteaDateTimeHelper.formatProjectTime(request.applicationCompletedAt!)}',
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
                    '${ConecteaDateTimeHelper.formatProjectDateShort(request.closedAt!)} às ${ConecteaDateTimeHelper.formatProjectTime(request.closedAt!)}',
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
          Divider(color: DsCores.border.withValues(alpha: 0.06), height: 1),
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
              style: DsTipografia.bodySmall.copyWith(
                color: DsCores.textSecondary,
              ),
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

  bool _isConfirming = false;

  Future<void> _handleConfirmCpfChange(AccountChangeRequest request) async {
    if (_isConfirming) return;
    setState(() {
      _isConfirming = true;
    });

    try {
      final result = await _databaseService.confirmCpfChangeRequest(
        requestId: request.id,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        DsFeedback.showSnackBar(
          context: context,
          mensagem: 'Alteração confirmada com sucesso.',
          tipo: DsFeedbackTipo.sucesso,
        );
        await _loadDetail(showLoading: true);
      } else {
        final errorCode = result['error_code'];
        String message = 'Não foi possível confirmar a troca agora.';
        if (errorCode == 'expired') {
          message = 'O prazo para confirmar esta solicitação expirou.';
        } else if (errorCode == 'cpf_conflict') {
          message =
              'Não foi possível concluir a troca porque o CPF informado não está disponível.';
        } else if (errorCode == 'current_cpf_mismatch') {
          message =
              'Não foi possível concluir porque os dados da conta mudaram.';
        }
        DsFeedback.showSnackBar(
          context: context,
          mensagem: message,
          tipo: DsFeedbackTipo.erro,
        );

        if (errorCode == 'expired' ||
            errorCode == 'cpf_conflict' ||
            errorCode == 'current_cpf_mismatch') {
          await _loadDetail(showLoading: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      DsFeedback.showSnackBar(
        context: context,
        mensagem:
            'Não foi possível confirmar a alteração. Tente novamente mais tarde.',
        tipo: DsFeedbackTipo.erro,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  Widget _buildConfirmationSection(
    AccountChangeRequest request,
    DsCorVisual visualToken,
  ) {
    String deadlineText =
        'Confirme dentro do prazo informado para a solicitação.';
    if (request.holderDeadlineDueDate != null) {
      final date = request.holderDeadlineDueDate!;
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().padLeft(4, '0');
      deadlineText = 'Você pode confirmar até $day/$month/$year.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: PhosphorIconsRegular.checkCircle,
          title: 'CONFIRME A TROCA DE CPF',
        ),
        const SizedBox(height: DsEspacamentos.sm),
        DsCard(
          borderColor: visualToken.border,
          padding: const EdgeInsets.all(DsEspacamentos.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A Gestão aprovou sua solicitação. Confira os dados abaixo e escolha se deseja continuar.',
                style: DsTipografia.body.copyWith(
                  color: DsCores.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: DsEspacamentos.md),
              Container(
                padding: const EdgeInsets.all(DsEspacamentos.sm),
                decoration: BoxDecoration(
                  color: DsCores.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactDetailRow(
                      'CPF atual',
                      request.oldValueMasked ?? '***.***.***-**',
                    ),
                    const SizedBox(height: DsEspacamentos.sm),
                    _buildCompactDetailRow(
                      'Novo CPF',
                      request.newValueMasked,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DsEspacamentos.md),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.clockCountdown,
                    color: DsCores.alerta.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deadlineText,
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsEspacamentos.lg),
              SizedBox(
                width: double.infinity,
                child: DsBotao(
                  label: 'Confirmar',
                  onPressed: _isConfirming
                      ? null
                      : () => _handleConfirmCpfChange(request),
                  variante: DsBotaoVariante.acao,
                  token: DsCores.sucesso,
                  icon: PhosphorIconsRegular.check,
                  isLoading: _isConfirming,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentReplacementSection(
    AccountChangeRequest request,
    DsCorVisual visualToken,
  ) {
    final bool isExpired =
        request.holderDeadlineDueDate != null &&
        DateTime.now().isAfter(
          DateTime(
            request.holderDeadlineDueDate!.year,
            request.holderDeadlineDueDate!.month,
            request.holderDeadlineDueDate!.day,
            23,
            59,
            59,
          ),
        );

    String deadlineText = 'Reenvie o documento dentro do prazo.';
    if (request.holderDeadlineDueDate != null) {
      final date = request.holderDeadlineDueDate!;
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().padLeft(4, '0');
      deadlineText = 'Você tem até $day/$month/$year para concluir essa etapa.';
    }

    if (isExpired) {
      deadlineText =
          'O prazo para concluir essa etapa expirou. Esta solicitação não pode mais ser alterada.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: PhosphorIconsRegular.fileArrowUp,
          title: 'REENVIO DE DOCUMENTO PENDENTE',
        ),
        const SizedBox(height: DsEspacamentos.sm),
        DsCard(
          borderColor: DsCores.alerta.border,
          padding: const EdgeInsets.all(DsEspacamentos.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A equipe identificou um problema no documento enviado. Por favor, reenvie um documento válido para continuarmos a análise.',
                style: DsTipografia.body.copyWith(
                  color: DsCores.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: DsEspacamentos.md),
              Row(
                children: [
                  Icon(
                    isExpired
                        ? PhosphorIconsRegular.xCircle
                        : PhosphorIconsRegular.clockCountdown,
                    color: isExpired
                        ? DsCores.perigo.accent
                        : DsCores.alerta.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deadlineText,
                      style: DsTipografia.caption.copyWith(
                        color: isExpired
                            ? DsCores.perigo.accent
                            : DsCores.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isExpired) ...[
                const SizedBox(height: DsEspacamentos.lg),
                SizedBox(
                  width: double.infinity,
                  child: DsBotao(
                    label: 'Reenviar documento',
                    onPressed: _isSubmittingDocument
                        ? null
                        : () => _handleReplaceDocument(request),
                    variante: DsBotaoVariante.acao,
                    token: DsCores.alerta,
                    icon: PhosphorIconsRegular.uploadSimple,
                    isLoading: _isSubmittingDocument,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCpfCorrectionSection(
    AccountChangeRequest request,
    DsCorVisual visualToken,
  ) {
    final bool isExpired =
        request.holderDeadlineDueDate != null &&
        DateTime.now().isAfter(
          DateTime(
            request.holderDeadlineDueDate!.year,
            request.holderDeadlineDueDate!.month,
            request.holderDeadlineDueDate!.day,
            23,
            59,
            59,
          ),
        );

    String deadlineText = 'Corrija o CPF dentro do prazo.';
    if (request.holderDeadlineDueDate != null) {
      final date = request.holderDeadlineDueDate!;
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().padLeft(4, '0');
      deadlineText = 'Você tem até $day/$month/$year para concluir essa etapa.';
    }

    if (isExpired) {
      deadlineText =
          'O prazo para concluir essa etapa expirou. Esta solicitação não pode mais ser alterada.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: PhosphorIconsRegular.pencilSimple,
          title: 'CORREÇÃO DE CPF PENDENTE',
        ),
        const SizedBox(height: DsEspacamentos.sm),
        DsCard(
          borderColor: visualToken.border,
          padding: const EdgeInsets.all(DsEspacamentos.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precisamos que você corrija o número do CPF para continuar a análise.',
                style: DsTipografia.body.copyWith(
                  color: DsCores.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: DsEspacamentos.xs),
              Text(
                'O documento enviado anteriormente será mantido.',
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: DsEspacamentos.md),
              Row(
                children: [
                  Icon(
                    isExpired
                        ? PhosphorIconsRegular.xCircle
                        : PhosphorIconsRegular.clockCountdown,
                    color: isExpired
                        ? DsCores.perigo.accent
                        : DsCores.alerta.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deadlineText,
                      style: DsTipografia.caption.copyWith(
                        color: isExpired
                            ? DsCores.perigo.accent
                            : DsCores.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isExpired) ...[
                const SizedBox(height: DsEspacamentos.md),
                Form(
                  key: _correctionFormKey,
                  child: CampoCpf(
                    controller: _correctionCpfController,
                    enabled: !_isSubmittingCpf,
                  ),
                ),
                const SizedBox(height: DsEspacamentos.lg),
                SizedBox(
                  width: double.infinity,
                  child: DsBotao(
                    label: 'Enviar CPF corrigido',
                    onPressed: _isSubmittingCpf
                        ? null
                        : () => _handleCorrectCpf(request),
                    variante: DsBotaoVariante.acao,
                    token: visualToken,
                    icon: PhosphorIconsRegular.paperPlaneRight,
                    isLoading: _isSubmittingCpf,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
