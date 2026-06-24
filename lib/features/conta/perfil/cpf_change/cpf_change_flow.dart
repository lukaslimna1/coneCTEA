import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:conectea/features/home/app_navigation_guard_controller.dart';
import 'package:conectea/services/google_drive_service.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_detail_view.dart';

class CpfChangeFlow extends StatefulWidget {
  final String currentCpf;

  const CpfChangeFlow({super.key, required this.currentCpf});

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
  bool _showCurrentCpf = false;
  bool _isCheckingActiveRequest = true;

  String _getCurrentCpfDisplay() {
    if (_showCurrentCpf) {
      return widget.currentCpf;
    }
    return '•••.•••.•••-••';
  }

  @override
  void initState() {
    super.initState();
    _cpfController.addListener(_clearCpfError);
    _justificationController.addListener(_clearJustificationError);
    _checkActiveRequestOnStart();
  }

  Future<void> _checkActiveRequestOnStart() async {
    try {
      final activeRequest = await DatabaseService()
          .getMyActiveCpfAccountChange();

      if (!mounted) return;

      if (activeRequest != null) {
        final showDetail = await DsDialog.show<bool>(
          context: context,
          title: 'Solicitação em andamento',
          description:
              'Você já tem uma solicitação de revisão de CPF em andamento. Acompanhe a análise da equipe.',
          icon: PhosphorIconsRegular.warningCircle,
          token: DsCores.alerta,
          secondaryAction: const DsDialogAction(
            label: 'Voltar',
            value: false,
            variante: DsBotaoVariante.ghost,
            token: DsCores.alerta,
          ),
          primaryAction: const DsDialogAction(
            label: 'Acompanhar solicitação',
            value: true,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
          ),
        );

        if (!mounted) return;

        if (showDetail == true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  AccountChangeDetailView(requestId: activeRequest.id),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _isCheckingActiveRequest = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingActiveRequest = false;
        });
      }
    }
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

  String _buildSafeDriveFileName(String extension) {
    final random = Random.secure();
    final randomVal = random.nextInt(65536);
    final hex = randomVal.toRadixString(16).padLeft(4, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ctea_anx_${timestamp}_$hex.$extension';
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    final ext = _selectedFile!.extension?.toLowerCase() ?? 'pdf';
    final fileName = _buildSafeDriveFileName(ext);

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

  Widget _buildStepHeader({
    required String title,
    required String subtitle,
    required DsCorVisual colorToken,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorToken.softBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorToken.border, width: 1),
          ),
          child: Center(child: Icon(icon, size: 24, color: colorToken.accent)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: DsTipografia.sectionTitle.copyWith(
                  color: DsCores.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        height: 1,
        color: DsCores.inputBorder.withValues(alpha: 0.3),
      ),
    );
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
          child: _isCheckingActiveRequest
              ? const Center(
                  child: CircularProgressIndicator(
                    color: DsCores.textSecondary,
                  ),
                )
              : Column(
                  children: [
                    // Barra superior de navegação — Mais compacta
                    Padding(
                      padding: const EdgeInsets.only(
                        left: DsEspacamentos.lg,
                        right: DsEspacamentos.lg,
                        top: DsEspacamentos.xs,
                        bottom: DsEspacamentos.xs,
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
                          DsEspacamentos.xs,
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
                            const SizedBox(height: 6),
                            Text(
                              'Confira o CPF atual e envie o documento para análise.',
                              style: DsTipografia.body.copyWith(
                                color: DsCores.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DsCard(
                              borderColor: DsCores.comunicacao.border
                                  .withValues(alpha: 0.15),
                              padding: const EdgeInsets.all(DsEspacamentos.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.info,
                                    color: DsCores.comunicacao.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Após o envio, a equipe administrativa analisará sua solicitação em até 10 dias corridos. Você poderá acompanhar o andamento em Minhas alterações de conta.',
                                      style: DsTipografia.bodySmall.copyWith(
                                        color: DsCores.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // =======================================================
                            // ETAPA 1: DADOS DO CPF
                            // =======================================================
                            _buildStepHeader(
                              title: 'Dados do CPF',
                              subtitle: 'Confira o atual e informe o correto.',
                              colorToken: DsCores.correcao,
                              icon: PhosphorIconsRegular.identificationCard,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'CPF atual: ',
                                    style: DsTipografia.bodySmall.copyWith(
                                      color: DsCores.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.03,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        DsRaios.pill,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.shieldCheck,
                                          color: DsCores.dadosProtegidos.accent
                                              .withValues(alpha: 0.5),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getCurrentCpfDisplay(),
                                          style: DsTipografia.bodySmall
                                              .copyWith(
                                                color: DsCores.textSecondary,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(
                                      _showCurrentCpf
                                          ? PhosphorIconsRegular.eyeSlash
                                          : PhosphorIconsRegular.eye,
                                      color: DsCores.textMuted,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showCurrentCpf = !_showCurrentCpf;
                                      });
                                    },
                                    tooltip: _showCurrentCpf
                                        ? 'Ocultar CPF'
                                        : 'Mostrar CPF',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
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
                            _buildDivider(),

                            // =======================================================
                            // ETAPA 2: DOCUMENTO
                            // =======================================================
                            _buildStepHeader(
                              title: 'Documento',
                              subtitle: 'Anexe uma comprovação com seus dados.',
                              colorToken: DsCores.solicitacao,
                              icon: PhosphorIconsRegular.fileArrowUp,
                            ),
                            const SizedBox(height: 16),
                            Focus(
                              focusNode: _fileFocusNode,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Documento com CPF, nome completo e data de nascimento.',
                                          style: DsTipografia.bodySmall
                                              .copyWith(
                                                color: DsCores.textSecondary,
                                                height: 1.4,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'CNH, CIN, RG, CPF ou equivalente.',
                                          style: DsTipografia.caption.copyWith(
                                            color: DsCores.textMuted,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_selectedFile == null)
                                    InkWell(
                                      onTap: _pickFile,
                                      borderRadius: BorderRadius.circular(
                                        DsRaios.input,
                                      ),
                                      child: DsCard(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        borderColor: _fileError != null
                                            ? DsCores.perigo.accent
                                            : DsCores.inputBorder,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.03,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                PhosphorIconsRegular
                                                    .fileArrowUp,
                                                color:
                                                    DsCores.solicitacao.accent,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Anexar documento',
                                                    style: DsTipografia
                                                        .bodySmall
                                                        .copyWith(
                                                          color: DsCores
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'PDF, JPG, JPEG ou PNG até 5MB',
                                                    style: DsTipografia.caption
                                                        .copyWith(
                                                          color:
                                                              DsCores.textMuted,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    DsCard(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      borderColor: DsCores.inputBorder,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _selectedFile!.extension == 'pdf'
                                                ? PhosphorIconsRegular.filePdf
                                                : PhosphorIconsRegular.image,
                                            color: DsCores.sucesso.accent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _selectedFile!.name,
                                                  style: DsTipografia.bodySmall
                                                      .copyWith(
                                                        color:
                                                            DsCores.textPrimary,
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
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              PhosphorIconsRegular.trash,
                                              color: DsCores.perigo.accent,
                                              size: 20,
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
                            _buildDivider(),

                            // =======================================================
                            // ETAPA 3: JUSTIFICATIVA
                            // =======================================================
                            _buildStepHeader(
                              title: 'Justificativa (Opcional)',
                              subtitle: 'Use se quiser explicar o motivo.',
                              colorToken: DsCores.conta,
                              icon: PhosphorIconsRegular.chatText,
                            ),
                            const SizedBox(height: 16),
                            DsInput(
                              label: 'Motivo da correção',
                              controller: _justificationController,
                              focusNode: _justificationFocusNode,
                              hint:
                                  'Descreva resumidamente o motivo da alteração...',
                              icon: PhosphorIconsRegular.chatText,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              maxLines: 3,
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
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
