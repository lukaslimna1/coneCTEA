import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/core/campos_cadastrais/campos/campo_cpf.dart';
import 'package:conectea/features/carteirinhas/solicitacao/dependent_cpf_change_presentation.dart';
import 'package:conectea/models/dependent_cpf_change_request.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/google_drive_service.dart';

class DependentCpfChangeDetailView extends StatefulWidget {
  final DependentCpfChangeRequest request;
  final VoidCallback onBack;

  const DependentCpfChangeDetailView({
    super.key,
    required this.request,
    required this.onBack,
  });

  @override
  State<DependentCpfChangeDetailView> createState() =>
      _DependentCpfChangeDetailViewState();
}

class _DependentCpfChangeDetailViewState
    extends State<DependentCpfChangeDetailView> {
  final DatabaseService _databaseService = DatabaseService();

  // Estados locais para controle de submissão
  bool _isSubmittingCpf = false;
  bool _isSubmittingDocument = false;
  final TextEditingController _correctionCpfController =
      TextEditingController();
  final GlobalKey<FormState> _correctionFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _correctionCpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Como a tela de detalhes é renderizada embutida na aba sob a HomePage,
    // não criamos um Scaffold ou AppBackground aninhados. Isso evita duplicações de SafeAreas
    // e gradientes. Retornamos o corpo da view que se integrará diretamente ao Scaffold da HomePage.
    return DsLoadingOverlay(
      isLoading: _isSubmittingCpf || _isSubmittingDocument,
      message: _isSubmittingDocument
          ? 'Enviando documento...'
          : 'Enviando correção...',
      child: _buildBody(context),
    );
  }


  Widget _buildBody(BuildContext context) {
    final request = widget.request;
    final onBack = widget.onBack;
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

              // AÇÕES DO SOLICITANTE
              if (request.status.toLowerCase() == 'waiting_document_replacement') ...[
                _buildDocumentReplacementSection(request, visualToken),
                const SizedBox(height: DsEspacamentos.md),
              ],

              if (request.status.toLowerCase() == 'waiting_cpf_correction') ...[
                _buildCpfCorrectionSection(request, visualToken),
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
    final request = widget.request;
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

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'unauthenticated':
        return 'Sessão expirada. Entre novamente.';
      case 'forbidden':
        return 'Você não tem permissão para alterar esta solicitação.';
      case 'not_found':
        return 'Solicitação não encontrada.';
      case 'invalid_status':
        return 'Essa solicitação não está mais aguardando esta ação.';
      case 'expired':
        return 'Seu prazo para concluir esta etapa expirou.';
      case 'invalid_cpf':
        return 'O CPF informado não parece válido.';
      case 'cpf_unchanged':
        return 'Informe um CPF diferente do CPF atual.';
      case 'account_cpf_conflict':
      case 'cpf_in_use':
      case 'reservation_unavailable':
        return 'Não foi possível usar esse CPF. Verifique os dados informados.';
      case 'invalid_file_id':
      case 'invalid_document_state':
        return 'Não foi possível validar o documento enviado.';
      case 'temporarily_unavailable':
      case 'internal_error':
      default:
        return 'Não foi possível concluir agora. Tente novamente.';
    }
  }

  void _showFeedback(BuildContext context, String message, DsFeedbackTipo tipo) {
    DsFeedback.showSnackBar(context: context, mensagem: message, tipo: tipo);
  }

  String _buildSafeDriveFileName(String extension) {
    final random = Random.secure();
    final randomVal = random.nextInt(65536);
    final hex = randomVal.toRadixString(16).padLeft(4, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ctea_dep_anx_${timestamp}_$hex.$extension';
  }

  Future<void> _handleReplaceDocument() async {
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
        if (mounted) {
          _showFeedback(
            context,
            'O arquivo excede o limite máximo de 5MB.',
            DsFeedbackTipo.erro,
          );
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(
          context,
          'Não foi possível selecionar o arquivo.',
          DsFeedbackTipo.erro,
        );
      }
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
        if (mounted) {
          _showFeedback(
            context,
            'Não foi possível enviar o documento. Tente novamente.',
            DsFeedbackTipo.erro,
          );
        }
        return;
      }

      final fileId = GoogleDriveService().extractFileId(uploadedDriveUrl);
      if (fileId == null || fileId.isEmpty) {
        await GoogleDriveService().deleteFile(uploadedDriveUrl);
        if (mounted) {
          _showFeedback(
            context,
            'Não foi possível preparar o documento. Tente novamente.',
            DsFeedbackTipo.erro,
          );
        }
        return;
      }

      final result = await _databaseService.submitDependentCpfDocumentReplacement(
        requestId: widget.request.id,
        documentFileId: fileId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showFeedback(context, 'Documento enviado com sucesso.', DsFeedbackTipo.sucesso);
        widget.onBack();
      } else {
        await GoogleDriveService().deleteFile(uploadedDriveUrl);
        if (!mounted) return;
        final errorCode = result['error_code'] ?? 'internal_error';
        _showFeedback(context, _getErrorMessage(errorCode), DsFeedbackTipo.erro);
      }

    } catch (_) {
      if (uploadedDriveUrl != null) {
        await GoogleDriveService().deleteFile(uploadedDriveUrl);
      }
      if (mounted) {
        _showFeedback(
          context,
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

  Future<void> _handleCorrectCpf() async {
    if (_isSubmittingCpf) return;

    if (!_correctionFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmittingCpf = true;
    });

    try {
      final cpfVal = _correctionCpfController.text;
      final result = await _databaseService.submitDependentCpfCorrection(
        requestId: widget.request.id,
        newCpf: cpfVal,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showFeedback(context, 'CPF corrigido com sucesso.', DsFeedbackTipo.sucesso);
        FocusScope.of(context).unfocus();
        _correctionCpfController.clear();
        widget.onBack();
      } else {
        final errorCode = result['error_code'] ?? 'internal_error';
        _showFeedback(context, _getErrorMessage(errorCode), DsFeedbackTipo.erro);
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(
          context,
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

  Widget _buildDocumentReplacementSection(
    DependentCpfChangeRequest request,
    DsCorVisual visualToken,
  ) {
    String deadlineText = 'Reenvie o documento dentro do prazo.';
    if (request.expiresAt != null) {
      final date = request.expiresAt!;
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().padLeft(4, '0');
      deadlineText = 'Você tem até $day/$month/$year para concluir essa etapa.';
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
                  label: 'Reenviar documento',
                  onPressed: _isSubmittingDocument
                      ? null
                      : _handleReplaceDocument,
                  variante: DsBotaoVariante.acao,
                  token: DsCores.alerta,
                  icon: PhosphorIconsRegular.uploadSimple,
                  isLoading: _isSubmittingDocument,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCpfCorrectionSection(
    DependentCpfChangeRequest request,
    DsCorVisual visualToken,
  ) {
    String deadlineText = 'Corrija o CPF dentro do prazo.';
    if (request.expiresAt != null) {
      final date = request.expiresAt!;
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString().padLeft(4, '0');
      deadlineText = 'Você tem até $day/$month/$year para concluir essa etapa.';
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
                      : _handleCorrectCpf,
                  variante: DsBotaoVariante.acao,
                  token: visualToken,
                  icon: PhosphorIconsRegular.paperPlaneRight,
                  isLoading: _isSubmittingCpf,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
