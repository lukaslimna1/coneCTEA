import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:conectea/features/home/app_navigation_guard_controller.dart';
import 'package:conectea/services/google_drive_service.dart';
import 'package:conectea/services/database_service.dart';

class CpfChangeFlow extends StatefulWidget {
  const CpfChangeFlow({super.key});

  @override
  State<CpfChangeFlow> createState() => _CpfChangeFlowState();
}

class _CpfChangeFlowState extends State<CpfChangeFlow> {
  final _cpfController = TextEditingController();
  final _justificationController = TextEditingController();
  final _cpfFocusNode = FocusNode();
  final _justificationFocusNode = FocusNode();
  final _fileFocusNode = FocusNode();

  PlatformFile? _selectedFile;
  String? _cpfError;
  String? _fileError;
  String? _justificationError;

  AppNavigationGuardController? _navigationGuardController;
  bool _isDiscardDialogOpen = false;
  bool _isSuccess = false;
  bool _isSubmitting = false;
  String? _uploadedDriveUrl;

  @override
  void initState() {
    super.initState();
    _cpfController.addListener(_clearCpfError);
    _justificationController.addListener(_clearJustificationError);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigationGuardController == null) {
      _navigationGuardController = AppNavigationGuardScope.of(context);
      _navigationGuardController!.registerGuard(_confirmDiscardGuard);
    }
  }

  @override
  void dispose() {
    if (_navigationGuardController != null) {
      _navigationGuardController!.unregisterGuard(_confirmDiscardGuard);
    }
    _cpfController.dispose();
    _justificationController.dispose();
    _cpfFocusNode.dispose();
    _justificationFocusNode.dispose();
    _fileFocusNode.dispose();
    super.dispose();
  }

  void _clearCpfError() {
    if (_cpfError != null) {
      setState(() => _cpfError = null);
    }
  }

  void _clearJustificationError() {
    if (_justificationError != null) {
      setState(() => _justificationError = null);
    }
  }

  bool _hasChanges() {
    return _cpfController.text.isNotEmpty ||
        _justificationController.text.isNotEmpty ||
        _selectedFile != null;
  }

  Future<bool> _confirmDiscardGuard() async {
    if (_isSubmitting) return false;
    if (_isSuccess) return true;
    if (!_hasChanges()) return true;
    if (_isDiscardDialogOpen) return false;

    _isDiscardDialogOpen = true;
    final result = await DsDialog.show<bool>(
      context: context,
      title: 'Descartar solicitação?',
      description:
          'As informações preenchidas ainda não foram enviadas. Se sair agora, elas serão descartadas.',
      icon: PhosphorIconsRegular.warningCircle,
      token: DsCores.alerta,
      secondaryAction: const DsDialogAction(
        label: 'Descartar',
        value: true,
        variante: DsBotaoVariante.ghost,
        token: DsCores.alerta,
      ),
      primaryAction: const DsDialogAction(
        label: 'Continuar editando',
        value: false,
        variante: DsBotaoVariante.acao,
        token: DsCores.sucesso,
      ),
    );
    _isDiscardDialogOpen = false;

    final shouldDiscard = result ?? false;
    if (shouldDiscard && _uploadedDriveUrl != null) {
      final deleted = await GoogleDriveService().deleteFile(_uploadedDriveUrl!);
      if (!deleted && mounted) {
        await DsDialog.show<void>(
          context: context,
          title: 'Erro ao descartar',
          description:
              'Não foi possível remover o documento carregado. Por segurança, tente novamente.',
          icon: PhosphorIconsRegular.warningCircle,
          token: DsCores.alerta,
          primaryAction: const DsDialogAction(
            label: 'Entendido',
            value: null,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
          ),
        );
        return false;
      }
      _uploadedDriveUrl = null;
    }

    return shouldDiscard;
  }

  Future<void> _requestExit() async {
    final canExit = await _confirmDiscardGuard();
    if (canExit && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      const maxFileSize = 5 * 1024 * 1024; // 5MB

      if (file.size > maxFileSize) {
        setState(() {
          _selectedFile = null;
          _fileError = 'O arquivo excede o limite máximo de 5MB.';
        });
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileError = null;
      });
    } catch (_) {
      setState(() {
        _fileError = 'Não foi possível selecionar o arquivo.';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileError = null;
    });
  }

  bool _validateForm() {
    bool hasError = false;

    // Validação de CPF
    final cpfVal = _cpfController.text;
    final cpfValidationError = ValidadoresCadastrais.cpf(cpfVal);
    if (cpfValidationError != null) {
      setState(() => _cpfError = cpfValidationError);
      hasError = true;
    }

    // Validação de arquivo
    if (_selectedFile == null) {
      setState(() => _fileError = 'O documento de comprovação é obrigatório.');
      hasError = true;
    }

    // Validação de Justificativa
    final justification = _justificationController.text;
    if (justification.length > 1000) {
      setState(
        () => _justificationError =
            'A justificativa não deve ultrapassar 1000 caracteres.',
      );
      hasError = true;
    }

    if (hasError) {
      // Focar e rolar até o primeiro campo com erro
      if (_cpfError != null) {
        _cpfFocusNode.requestFocus();
        Scrollable.ensureVisible(
          _cpfFocusNode.context!,
          duration: const Duration(milliseconds: 300),
        );
      } else if (_fileError != null) {
        _fileFocusNode.requestFocus();
        Scrollable.ensureVisible(
          _fileFocusNode.context!,
          duration: const Duration(milliseconds: 300),
        );
      } else if (_justificationError != null) {
        _justificationFocusNode.requestFocus();
        Scrollable.ensureVisible(
          _justificationFocusNode.context!,
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    return !hasError;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    final ext = _selectedFile!.extension?.toLowerCase() ?? 'pdf';
    final fileName =
        'cpf_revisao_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final driveUrl = await GoogleDriveService().uploadFile(
      file: _selectedFile!,
      fileName: fileName,
    );

    if (driveUrl == null || driveUrl.isEmpty) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        await DsDialog.show<void>(
          context: context,
          title: 'Erro de envio',
          description:
              'Não foi possível enviar o documento. Verifique sua conexão e tente novamente.',
          icon: PhosphorIconsRegular.warningCircle,
          token: DsCores.alerta,
          primaryAction: const DsDialogAction(
            label: 'Entendido',
            value: null,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
          ),
        );
      }
      return;
    }

    _uploadedDriveUrl = driveUrl;

    final fileId = GoogleDriveService().extractFileId(driveUrl);
    if (fileId == null || fileId.isEmpty) {
      await GoogleDriveService().deleteFile(driveUrl);
      setState(() {
        _uploadedDriveUrl = null;
        _isSubmitting = false;
      });
      if (mounted) {
        await DsDialog.show<void>(
          context: context,
          title: 'Erro no documento',
          description:
              'Não foi possível preparar o documento enviado. Tente novamente.',
          icon: PhosphorIconsRegular.warningCircle,
          token: DsCores.alerta,
          primaryAction: const DsDialogAction(
            label: 'Entendido',
            value: null,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
          ),
        );
      }
      return;
    }

    final result = await DatabaseService().createCpfChangeRequest(
      newCpf: _cpfController.text,
      fileId: fileId,
      justification: _justificationController.text.trim(),
    );

    if (result['success'] == true) {
      setState(() {
        _isSuccess = true;
        _isSubmitting = false;
        _uploadedDriveUrl = null;
        _selectedFile = null;
      });

      final protocol = result['protocol_number'] ?? '';
      final description = protocol.isNotEmpty
          ? 'Sua solicitação de revisão de CPF foi enviada para análise da equipe administrativa.\n\nProtocolo: $protocol'
          : 'Sua solicitação de revisão de CPF foi enviada para análise da equipe administrativa.';

      if (mounted) {
        await DsDialog.show<void>(
          context: context,
          title: 'Solicitação enviada',
          description: description,
          icon: PhosphorIconsRegular.checkCircle,
          token: DsCores.sucesso,
          primaryAction: const DsDialogAction(
            label: 'Entendido',
            value: null,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
          ),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } else {
      final cleanedUp = await GoogleDriveService().deleteFile(driveUrl);
      if (cleanedUp) {
        setState(() {
          _uploadedDriveUrl = null;
        });
      }
      setState(() {
        _isSubmitting = false;
      });

      final errorKey = result['error'] ?? '';
      String errorMsg =
          'Não foi possível concluir a solicitação agora. Tente novamente em alguns instantes.';

      if (errorKey == 'active_request_exists') {
        errorMsg =
            'Já existe uma solicitação de alteração de CPF em andamento. Acompanhe o andamento em Minhas alterações de conta.';
      } else if (errorKey == 'invalid_request') {
        errorMsg =
            'Não foi possível validar os dados enviados. Revise as informações e tente novamente.';
      } else if (errorKey == 'temporarily_unavailable' ||
          errorKey == 'unavailable') {
        errorMsg =
            'Não foi possível concluir a solicitação agora. Tente novamente em alguns instantes.';
      }

      if (mounted) {
        await DsDialog.show<void>(
          context: context,
          title: 'Não foi possível enviar',
          description: cleanedUp
              ? '$errorMsg\n\nO documento enviado foi removido com segurança.'
              : '$errorMsg\n\nPor segurança, tente novamente mais tarde ou procure o suporte.',
          icon: PhosphorIconsRegular.warningCircle,
          token: DsCores.alerta,
          primaryAction: const DsDialogAction(
            label: 'Entendido',
            value: null,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isSuccess && !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Barra superior de navegação
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsEspacamentos.lg,
                    vertical: DsEspacamentos.sm,
                  ),
                  child: Row(
                    children: [DsBotaoVoltar(onPressed: _requestExit)],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      DsEspacamentos.lg,
                      DsEspacamentos.sm,
                      DsEspacamentos.lg,
                      DsEspacamentos.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitar revisão de CPF',
                          style: DsTipografia.pageTitle.copyWith(
                            color: DsCores.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use este formulário apenas se o CPF cadastrado na sua conta principal estiver incorreto. A solicitação será analisada pela equipe administrativa.',
                          style: DsTipografia.body.copyWith(
                            color: DsCores.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Card Informativo (Aviso Importante)
                        DsCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: DsCores.alerta.border.withValues(
                            alpha: 0.3,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIconsRegular.info,
                                color: DsCores.alerta.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'A carteirinha do ConeCTEA é comunitária e não substitui documentos oficiais.',
                                  style: DsTipografia.bodySmall.copyWith(
                                    color: DsCores.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        DsCard(
                          padding: const EdgeInsets.all(24),
                          borderColor: DsCores.correcao.border,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo 1: Novo CPF
                              DsInput(
                                label: 'Novo CPF',
                                controller: _cpfController,
                                focusNode: _cpfFocusNode,
                                hint: '000.000.000-00',
                                icon: PhosphorIconsRegular.identificationCard,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                errorText: _cpfError,
                                inputFormatters: [
                                  FormatadoresCadastrais.obterMascaraCpf(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Campo 2: Seleção de Documento
                              Focus(
                                focusNode: _fileFocusNode,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Documento de comprovação',
                                      style: DsTipografia.inputLabel.copyWith(
                                        color: DsCores.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: DsEspacamentos.sm),
                                    if (_selectedFile == null)
                                      InkWell(
                                        onTap: _pickFile,
                                        borderRadius: BorderRadius.circular(
                                          DsRaios.input,
                                        ),
                                        child: DsCard(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 24,
                                            horizontal: 16,
                                          ),
                                          borderColor: _fileError != null
                                              ? DsCores.perigo.accent
                                              : DsCores.inputBorder,
                                          child: Center(
                                            child: Column(
                                              children: [
                                                Icon(
                                                  PhosphorIconsRegular
                                                      .fileArrowUp,
                                                  color: DsCores.inputIcon,
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Anexar documento de identificação',
                                                  style: DsTipografia.body
                                                      .copyWith(
                                                        color:
                                                            DsCores.textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Formatos aceitos: PDF, JPG, JPEG, PNG (máx. 5MB)',
                                                  style: DsTipografia.caption
                                                      .copyWith(
                                                        color:
                                                            DsCores.textMuted,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      DsCard(
                                        padding: const EdgeInsets.all(16),
                                        borderColor: DsCores.inputBorder,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _selectedFile!.extension == 'pdf'
                                                  ? PhosphorIconsRegular.filePdf
                                                  : PhosphorIconsRegular.image,
                                              color: DsCores.sucesso.accent,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _selectedFile!.name,
                                                    style: DsTipografia.body
                                                        .copyWith(
                                                          color: DsCores
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _formatFileSize(
                                                      _selectedFile!.size,
                                                    ),
                                                    style: DsTipografia.caption
                                                        .copyWith(
                                                          color: DsCores
                                                              .textSecondary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                PhosphorIconsRegular.trash,
                                                color: DsCores.perigo.accent,
                                              ),
                                              onPressed: _removeFile,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_fileError != null) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          _fileError!,
                                          style: DsTipografia.caption.copyWith(
                                            color: DsCores.perigo.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Campo 3: Justificativa
                              DsInput(
                                label: 'Justificativa (Opcional)',
                                controller: _justificationController,
                                focusNode: _justificationFocusNode,
                                hint:
                                    'Descreva resumidamente o motivo da alteração...',
                                icon: PhosphorIconsRegular.chatText,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                maxLines: 5,
                                errorText: _justificationError,
                              ),
                              const SizedBox(height: 32),
                              // CTA Principal
                              DsBotao(
                                label: _isSubmitting
                                    ? 'Enviando...'
                                    : 'Revisar solicitação',
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                variante: DsBotaoVariante.acao,
                                token: DsCores.correcao,
                                icon: PhosphorIconsRegular.paperPlaneRight,
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
          ),
        ),
      ),
    );
  }
}
