import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/google_drive_service.dart';
import 'package:conectea/models/card_request.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/features/admin/solicitacoes_carteirinha/utils/admin_status_helper.dart';
import 'package:conectea/features/admin/solicitacoes_carteirinha/widgets/admin_common_widgets.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

class AdminRequestDetailsSheet extends StatefulWidget {
  final CardRequest request;
  final DatabaseService databaseService;
  final VoidCallback onStatusChanged;

  const AdminRequestDetailsSheet({
    super.key,
    required this.request,
    required this.databaseService,
    required this.onStatusChanged,
  });

  @override
  State<AdminRequestDetailsSheet> createState() =>
      _AdminRequestDetailsSheetState();
}

class _AdminRequestDetailsSheetState extends State<AdminRequestDetailsSheet> {
  bool _isLoading = true;
  AppUser? _requester;
  Member? _member;
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final user = await widget.databaseService.getUserProfile(
        widget.request.userId,
      );
      final member = await widget.databaseService.getMemberById(
        widget.request.memberId,
      );

      if (mounted) {
        setState(() {
          _requester = user;
          _member = member;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar os detalhes agora. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(
    String newStatus,
    String notes, {
    DateTime? expiresAt,
    bool clearDocument = false,
    bool clearMedicalReport = false,
  }) async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    bool driveCleanupSuccess = true;

    try {
      if (newStatus == 'active') {
        // 1. Limpeza automática obrigatória de documentos sensíveis ANTES de aprovar (fail-closed)
        final cleanupSuccess = await _cleanupDocumentsAfterApproval();
        if (!cleanupSuccess) {
          throw Exception(
            'A limpeza de segurança dos documentos falhou no Google Drive.',
          );
        }
      }

      // 2. Tentar deletar do Drive se clearDocument for verdadeiro e URL válida (reenvio/pendências)
      if (clearDocument &&
          widget.request.documentUrl.isNotEmpty &&
          _isValidDriveUrl(widget.request.documentUrl)) {
        try {
          final success = await _driveService.deleteFile(
            widget.request.documentUrl,
          );
          if (!success) {
            driveCleanupSuccess = false;
            debugPrint('Falha ao deletar documento com foto antigo no Drive.');
          }
        } catch (e) {
          driveCleanupSuccess = false;
          debugPrint('Erro ao deletar documento com foto antigo no Drive.');
        }
      }

      // 3. Tentar deletar do Drive se clearMedicalReport for verdadeiro e URL válida (reenvio/pendências)
      if (clearMedicalReport &&
          widget.request.medicalReportUrl.isNotEmpty &&
          _isValidDriveUrl(widget.request.medicalReportUrl)) {
        try {
          final success = await _driveService.deleteFile(
            widget.request.medicalReportUrl,
          );
          if (!success) {
            driveCleanupSuccess = false;
            debugPrint('Falha ao deletar laudo medico antigo no Drive.');
          }
        } catch (e) {
          driveCleanupSuccess = false;
          debugPrint('Erro ao deletar laudo medico antigo no Drive.');
        }
      }

      // 4. Limpar no Supabase (tanto em card_requests quanto em members)
      if (clearDocument || clearMedicalReport) {
        await widget.databaseService.clearRequestDocumentUrls(
          requestId: widget.request.id,
          memberId: widget.request.memberId,
          clearDocument: clearDocument,
          clearMedicalReport: clearMedicalReport,
        );
      }

      // 5. Único ponto de atualização — updateCardRequestStatus agora propaga
      // para member.status e digital_cards.is_active automaticamente
      await widget.databaseService.updateCardRequestStatus(
        widget.request.id,
        newStatus,
        adminNotes: notes.trim(),
        expiresAt: expiresAt,
      );

      if (mounted) {
        // 1. Fechar o dialog de carregamento
        Navigator.of(context, rootNavigator: true).pop();

        // 2. Mostrar feedback de sucesso ANTES de fechar o sheet para garantir o contexto
        if (newStatus == 'active') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status atualizado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (newStatus == 'waiting_docs' ||
            newStatus == 'reviewing_data') {
          if (driveCleanupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Solicitação de reenvio enviada e documentos antigos limpos!',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A revisão foi enviada, mas a limpeza física de um arquivo no Drive precisa ser verificada.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status atualizado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // 3. Fechar o sheet de detalhes
        Navigator.of(context).pop();

        // 4. Notificar o pai para atualizar a lista
        widget.onStatusChanged();
      }
    } catch (e) {
      if (mounted) {
        // Fechar o dialog de carregamento em caso de erro
        Navigator.of(context, rootNavigator: true).pop();

        final String errorMessage = e.toString().contains('Google Drive')
            ? 'Erro crítico de LGPD: A remoção física dos documentos sensíveis falhou no Google Drive. A aprovação foi cancelada por segurança para evitar retenção de dados.'
            : 'Não foi possível atualizar o status agora. Tente novamente.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() => _isProcessingAction = false);
      }
    }
  }

  bool _isValidDriveUrl(String url) {
    if (url.trim().isEmpty) return false;
    if (!url.contains('google.com')) return false;
    final hasD = url.contains('/d/');
    final hasId = url.contains('id=');
    return hasD || hasId;
  }

  void _confirmStatusUpdate(String status, String label) async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);

    // Aprovar e Renovar não precisam de justificativa, processam direto
    if (status == 'active' ||
        (status == 'renewing' && widget.request.status == 'renewing')) {
      setState(() => _isProcessingAction = false);
      _updateStatus(status, 'Solicitação aprovada e processada.');
      return;
    }

    final notesController = TextEditingController();
    final statusToken = StatusVisualTokens.fromStatus(status);
    final Color statusColor = statusToken.primary;

    List<String> options = [];
    Map<String, bool> selectedOptions = {};

    if (status == 'reviewing_data') {
      options = [
        'Nome Completo',
        'Nome Social',
        'CPF',
        'Data de Nascimento',
        'Telefone',
        'Contato de Emergência',
        'Gênero',
        'Raça/Cor',
        'Tipo Sanguíneo',
        'Estado',
        'Cidade',
      ];

      // Adicionar Responsável apenas se for menor de 18 anos
      if (_member != null && _member!.dateOfBirth.isNotEmpty) {
        try {
          final parts = _member!.dateOfBirth.split('/');
          if (parts.length == 3) {
            final birthDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
            final age = DateTime.now().year - birthDate.year;
            if (age < 18) {
              options.add('Responsável');
            }
          }
        } catch (_) {}
      }
    } else if (status == 'waiting_docs') {
      if (_member?.teaRelationType == 'rede_apoio_tea') {
        options = [];
      } else {
        options = ['Documento com Foto (RG/CNH)', 'Laudo Médico'];
      }
    }

    // Inicializar o mapa de opções selecionadas como falso para todos
    for (var opt in options) {
      selectedOptions[opt] = false;
    }

    int selectedDays = 7;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1224),
          surfaceTintColor: Colors.transparent,
          shadowColor: statusColor.withValues(alpha: 0.15),
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: statusColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  statusToken.icon,
                  color: statusToken.iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width > 528
                ? 480.0
                : MediaQuery.sizeOf(context).width - 48.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JUSTIFICATIVA PARA O USUÁRIO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      cursorColor: statusColor,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Descreva detalhadamente o motivo...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.inputPlaceholder,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: statusColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (options.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        status == 'reviewing_data'
                            ? '📋 CAMPOS PARA CORREÇÃO'
                            : '📄 DOCUMENTOS SOLICITADOS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: options.map((opt) {
                            final isSelected = selectedOptions[opt] ?? false;
                            return Material(
                              color: Colors.transparent,
                              child: CheckboxListTile(
                                title: Text(
                                  opt,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                                value: isSelected,
                                dense: true,
                                activeColor: statusColor,
                                checkColor: Colors.white,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedOptions[opt] = val ?? false;

                                    String newNotes = "Pendência:\n";
                                    bool hasAny = false;
                                    selectedOptions.forEach((key, isSelected) {
                                      if (isSelected) {
                                        newNotes += "- $key\n";
                                        hasAny = true;
                                      }
                                    });
                                    notesController.text = hasAny
                                        ? newNotes
                                        : "";
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '⏳ PRAZO PARA RESPOSTA',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: [7, 15, 30].contains(selectedDays)
                            ? selectedDays
                            : 7,
                        dropdownColor: const Color(0xFF0B1224),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        iconEnabledColor: statusColor,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: statusColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 7,
                            child: Text('7 dias úteis'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('15 dias úteis'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 dias úteis'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedDays = val);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Tooltip(
                  message: 'Cancelar',
                  child: Semantics(
                    label: 'Cancelar',
                    hint: 'Fecha o diálogo sem confirmar a ação',
                    button: true,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, false),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 56,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFFE11D48,
                            ).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            color: Color(0xFFFB7185),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          if (notesController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Justificativa obrigatória'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF065F46), Color(0xFF047857)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFF34D399,
                              ).withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF047857,
                                ).withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Confirmar',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      DateTime? expiresAt;
      if (options.isNotEmpty) {
        try {
          expiresAt = await widget.databaseService.getAdminDeadlineFromServer(
            selectedDays,
          );
        } catch (e) {
          if (mounted) {
            setState(() => _isProcessingAction = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Erro ao obter prazo do servidor. Ação cancelada.',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
      final bool clearDocument =
          selectedOptions['Documento com Foto (RG/CNH)'] ?? false;
      final bool clearMedicalReport = selectedOptions['Laudo Médico'] ?? false;

      setState(() => _isProcessingAction = false);
      _updateStatus(
        status,
        notesController.text.trim(),
        expiresAt: expiresAt,
        clearDocument: clearDocument,
        clearMedicalReport: clearMedicalReport,
      );
    } else {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _handleDeleteDocument(String url, String fieldKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar Arquivo?'),
        content: const Text(
          'Isso removerá o arquivo permanentemente do Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deletando arquivo...')));

      final success = await _driveService.deleteFile(url);
      if (success) {
        try {
          await widget.databaseService.updateRequestFileUrl(
            widget.request.id,
            fieldKey,
            '',
          );
          if (mounted) {
            widget.onStatusChanged();
            Navigator.pop(context); // Close sheet to refresh
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Arquivo deletado com sucesso!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Arquivo removido, mas não foi possível atualizar o registro agora.',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao deletar arquivo no Drive.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Análise de Solicitação',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSectionTitle(title: 'Dados da Solicitação'),
                        AdminDetailRow(
                          label: 'Protocolo',
                          value: widget.request.protocol,
                        ),
                        AdminDetailRow(
                          label: 'Tipo',
                          value:
                              (widget.request.type == 'new_card' ||
                                  widget.request.type == 'Primeira via' ||
                                  widget.request.type == 'Emissão Digital')
                              ? 'Emissão Digital'
                              : widget.request.type,
                        ),
                        AdminDetailRow(
                          label: 'Status Atual',
                          customValue: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF020617,
                                  ).withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: StatusVisualTokens.fromStatus(
                                      widget.request.status,
                                    ).pillBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: StatusVisualTokens.fromStatus(
                                            widget.request.status,
                                          ).pillBackground,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          StatusVisualTokens.fromStatus(
                                            widget.request.status,
                                          ).icon,
                                          color: StatusVisualTokens.fromStatus(
                                            widget.request.status,
                                          ).primary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AdminStatusHelper.getStatusLabel(
                                            widget.request.status,
                                          ).toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color:
                                                StatusVisualTokens.fromStatus(
                                                  widget.request.status,
                                                ).primary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        AdminDetailRow(
                          label: 'Data',
                          value:
                              '${widget.request.createdAt.day}/${widget.request.createdAt.month}/${widget.request.createdAt.year}',
                        ),

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Documentação Enviada'),
                        AdminDocumentLink(
                          label: 'Documento com Foto',
                          url: widget.request.documentUrl,
                          iconData: Icons.badge_outlined,
                          onTap: () => _openUrl(widget.request.documentUrl),
                          onDelete: () => _handleDeleteDocument(
                            widget.request.documentUrl,
                            'document_url',
                          ),
                        ),
                        AdminDocumentLink(
                          label: 'Laudo Médico',
                          url: widget.request.medicalReportUrl,
                          iconData: Icons.medical_information_outlined,
                          onTap: () =>
                              _openUrl(widget.request.medicalReportUrl),
                          onDelete: () => _handleDeleteDocument(
                            widget.request.medicalReportUrl,
                            'medical_report_url',
                          ),
                        ),

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Membro (Beneficiário)'),
                        if (_member != null) ...[
                          AdminDetailRow(label: 'Nome', value: _member!.name),
                          AdminDetailRow(
                            label: 'Nome Social',
                            value:
                                (_member!.socialName != null &&
                                    _member!.socialName!.trim().isNotEmpty)
                                ? _member!.socialName!.trim()
                                : 'Não informado',
                          ),
                          AdminDetailRow(
                            label: 'Tipo de vínculo',
                            value: (_member!.teaRelationType == null)
                                ? 'Pessoa TEA'
                                : _member!.teaRelationLabel,
                          ),
                          AdminDetailRow(
                            label: 'CPF',
                            value: _member!.cpf,
                            isSensitive: true,
                          ),
                          AdminDetailRow(
                            label: 'Nascimento',
                            value: _member!.dateOfBirth,
                          ),
                          AdminDetailRow(
                            label: 'Localização',
                            value: '${_member!.city} - ${_member!.state}',
                          ),
                          AdminDetailRow(
                            label: 'Gênero',
                            value:
                                (_member!.gender != null &&
                                    _member!.gender!.trim().isNotEmpty)
                                ? _member!.gender!.trim()
                                : 'Não informado',
                          ),
                          AdminDetailRow(
                            label: 'Raça/Cor',
                            value:
                                (_member!.racaCor != null &&
                                    _member!.racaCor!.trim().isNotEmpty)
                                ? _member!.racaCor!.trim()
                                : 'Não informado',
                          ),
                          AdminDetailRow(label: 'CID', value: _member!.cid),
                          AdminDetailRow(
                            label: 'Tipo Sanguíneo',
                            value: _member!.bloodType,
                          ),
                          AdminDetailRow(
                            label: 'Contato Emergência',
                            value: _member!.emergencyContact,
                          ),
                        ],

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Usuário Solicitante'),
                        if (_requester != null) ...[
                          AdminDetailRow(
                            label: 'Nome',
                            value: _requester!.name,
                          ),
                          AdminDetailRow(
                            label: 'E-mail',
                            value: _requester!.email,
                          ),
                          AdminDetailRow(
                            label: 'Telefone',
                            value: _requester!.phone,
                          ),
                        ],

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Histórico da Análise'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Text(
                            widget.request.adminNotes.trim().isNotEmpty
                                ? widget.request.adminNotes.trim()
                                : 'Nenhum registro anterior cadastrado.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: widget.request.adminNotes.trim().isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                              fontStyle:
                                  widget.request.adminNotes.trim().isNotEmpty
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _buildStatusSelection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações da Solicitação',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Ações Positivas
        Text(
          'CONCORDÂNCIA E APROVAÇÃO',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Só mostra aprovar se não estiver ativa e não for renovação
            if (widget.request.status != 'active' &&
                widget.request.status != 'renewing')
              AdminStatusActionButton(
                label: 'APROVAR',
                statusKey: 'active',
                onTap: () => _confirmStatusUpdate('active', 'Aprovar'),
              ),

            // Só mostra renovar se o status for renovação (solicitado pelo user)
            if (widget.request.status == 'renewing')
              AdminStatusActionButton(
                label: 'APROVAR RENOVAÇÃO',
                statusKey: 'renewing',
                onTap: () => _confirmStatusUpdate('active', 'Renovar'),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Ações de Análise
        Text(
          'ANÁLISE E PENDÊNCIAS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (_member?.teaRelationType != 'rede_apoio_tea')
              AdminStatusActionButton(
                label: 'SOLICITAR DOCS',
                statusKey: 'waiting_docs',
                onTap: () => _confirmStatusUpdate(
                  'waiting_docs',
                  'Solicitar Documentos',
                ),
              ),
            AdminStatusActionButton(
              label: 'REVISAR DADOS',
              statusKey: 'reviewing_data',
              onTap: () =>
                  _confirmStatusUpdate('reviewing_data', 'Revisar Dados'),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Ações Negativas/Perigosas
        Text(
          'AÇÕES RESTRITIVAS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AdminStatusActionButton(
              label: 'REPROVAR',
              statusKey: 'rejected',
              onTap: () => _confirmStatusUpdate('rejected', 'Reprovar'),
            ),
            AdminStatusActionButton(
              label: 'SUSPENDER',
              statusKey: 'suspended',
              onTap: () => _confirmStatusUpdate('suspended', 'Suspender'),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _cleanupDocumentsAfterApproval() async {
    bool allSuccess = true;
    bool deletedDoc = false;
    bool deletedReport = false;

    try {
      // 1. Limpar Documento com Foto
      if (widget.request.documentUrl.isNotEmpty &&
          _isValidDriveUrl(widget.request.documentUrl)) {
        final success = await _driveService.deleteFile(
          widget.request.documentUrl,
        );
        if (success) {
          deletedDoc = true;
        } else {
          allSuccess = false;
          debugPrint('Falha ao deletar documento com foto no Drive.');
        }
      }

      // 2. Limpar Laudo Médico
      if (widget.request.medicalReportUrl.isNotEmpty &&
          _isValidDriveUrl(widget.request.medicalReportUrl)) {
        final success = await _driveService.deleteFile(
          widget.request.medicalReportUrl,
        );
        if (success) {
          deletedReport = true;
        } else {
          allSuccess = false;
          debugPrint('Falha ao deletar laudo médico no Drive.');
        }
      }

      // 3. Atualizar o banco em cascata de forma limpa e centralizada para as duas tabelas
      if (deletedDoc || deletedReport) {
        await widget.databaseService.clearRequestDocumentUrls(
          requestId: widget.request.id,
          memberId: widget.request.memberId,
          clearDocument: deletedDoc,
          clearMedicalReport: deletedReport,
        );
      }
    } catch (e) {
      allSuccess = false;
      debugPrint('Erro durante limpeza automática de documentos.');
    }
    return allSuccess;
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}
