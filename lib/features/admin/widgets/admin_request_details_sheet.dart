import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../services/database_service.dart';
import '../../../services/google_drive_service.dart';
import '../../../models/card_request.dart';
import '../../../models/app_user.dart';
import '../../../models/member.dart';
import '../../../models/notification_item.dart';
import '../../../core/constants/colors.dart';
import '../utils/admin_status_helper.dart';
import 'admin_common_widgets.dart';

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
  State<AdminRequestDetailsSheet> createState() => _AdminRequestDetailsSheetState();
}

class _AdminRequestDetailsSheetState extends State<AdminRequestDetailsSheet> {
  bool _isLoading = true;
  AppUser? _requester;
  Member? _member;
  final _notesController = TextEditingController();
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.request.adminNotes;
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
          SnackBar(content: Text('Erro ao carregar detalhes: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus, String notes, {DateTime? expiresAt}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // Único ponto de atualização — updateCardRequestStatus agora propaga
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status atualizado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // 3. Fechar o sheet de detalhes
        Navigator.of(context).pop();

        // 4. Notificar o pai para atualizar a lista
        widget.onStatusChanged();
      }
    } catch (e) {
      if (mounted) {
        // Fechar o dialog de carregamento em caso de erro
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmStatusUpdate(String status, String label) async {
    // Aprovar e Renovar não precisam de justificativa, processam direto
    if (status == 'active' || (status == 'renewing' && widget.request.status == 'renewing')) {
      _updateStatus(status, 'Solicitação aprovada e processada.');
      return;
    }

    final notesController = TextEditingController();
    final Color statusColor = AdminStatusHelper.getStatusColor(status);

    List<String> options = [];
    Map<String, bool> selectedOptions = {};

    if (status == 'reviewing_data') {
      options = ['Nome Completo', 'CPF', 'Data de Nascimento', 'Estado', 'Cidade'];
      
      // Adicionar Responsável apenas se for menor de 18 anos
      if (_member != null && _member!.dateOfBirth.isNotEmpty) {
        try {
          final parts = _member!.dateOfBirth.split('/');
          if (parts.length == 3) {
            final birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            final age = DateTime.now().year - birthDate.year;
            if (age < 18) {
              options.add('Responsável');
            }
          }
        } catch (_) {}
      }
    } else if (status == 'waiting_docs') {
      options = ['Documento com Foto (RG/CNH)', 'Laudo Médico'];
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirmar: $label',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Justificativa para o usuário:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Descreva aqui o motivo da alteração...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      status == 'reviewing_data' ? '📋 Campos para correção:' : '📄 Documentos solicitados:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: options.map((opt) => CheckboxListTile(
                          title: Text(opt, style: GoogleFonts.inter(fontSize: 13)),
                          value: selectedOptions[opt] ?? false,
                          dense: true,
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedOptions[opt] = val ?? false;
                              
                              String newNotes = "Pendências encontradas:\n";
                              bool hasAny = false;
                              selectedOptions.forEach((key, isSelected) {
                                if (isSelected) {
                                  newNotes += "- Pendência: $key\n";
                                  hasAny = true;
                                }
                              });
                              notesController.text = hasAny ? newNotes : "";
                            });
                          },
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '⏳ Prazo para resposta:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedDays,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 7, child: Text('7 dias')),
                        DropdownMenuItem(value: 15, child: Text('15 dias')),
                        DropdownMenuItem(value: 30, child: Text('30 dias')),
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
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Justificativa obrigatória')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Confirmar Alteração', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      DateTime? expiresAt;
      if (options.isNotEmpty) {
        expiresAt = DateTime.now().add(Duration(days: selectedDays));
      }
      _updateStatus(status, notesController.text.trim(), expiresAt: expiresAt);
    }
  }

  Future<void> _handleDeleteDocument(String url, String fieldKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar Arquivo?'),
        content: const Text('Isso removerá o arquivo permanentemente do Google Drive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deletando arquivo...')));

      final success = await _driveService.deleteFile(url);
      if (success) {
        try {
          await widget.databaseService.updateRequestFileUrl(widget.request.id, fieldKey, '');
          if (mounted) {
            widget.onStatusChanged();
            Navigator.pop(context); // Close sheet to refresh
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo deletado com sucesso!')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar banco: $e')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao deletar arquivo no Drive.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
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
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Análise de Solicitação',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSectionTitle(title: 'Dados da Solicitação'),
                        AdminDetailRow(label: 'Protocolo', value: widget.request.protocol),
                        AdminDetailRow(
                          label: 'Tipo', 
                          value: (widget.request.type == 'new_card' || widget.request.type == 'Primeira via' || widget.request.type == 'Emissão Digital') 
                              ? 'Emissão Digital' 
                              : widget.request.type
                        ),
                        AdminDetailRow(label: 'Status Atual', value: AdminStatusHelper.getStatusLabel(widget.request.status)),
                        AdminDetailRow(
                          label: 'Data',
                          value: '${widget.request.createdAt.day}/${widget.request.createdAt.month}/${widget.request.createdAt.year}',
                        ),

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Documentação Enviada'),
                        AdminDocumentLink(
                          label: 'Documento com Foto',
                          url: widget.request.documentUrl,
                          iconData: Icons.badge_outlined,
                          onTap: () => _openUrl(widget.request.documentUrl),
                          onDelete: () => _handleDeleteDocument(widget.request.documentUrl, 'document_url'),
                        ),
                        AdminDocumentLink(
                          label: 'Laudo Médico',
                          url: widget.request.medicalReportUrl,
                          iconData: Icons.medical_information_outlined,
                          onTap: () => _openUrl(widget.request.medicalReportUrl),
                          onDelete: () => _handleDeleteDocument(widget.request.medicalReportUrl, 'medical_report_url'),
                        ),

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Membro (Beneficiário)'),
                        if (_member != null) ...[
                          AdminDetailRow(label: 'Nome', value: _member!.name),
                          AdminDetailRow(label: 'CPF', value: _member!.cpf, isSensitive: true),
                          AdminDetailRow(label: 'Nascimento', value: _member!.dateOfBirth),
                          AdminDetailRow(label: 'Localização', value: '${_member!.city} - ${_member!.state}'),
                          AdminDetailRow(label: 'CID', value: _member!.cid),
                          AdminDetailRow(label: 'Tipo Sanguíneo', value: _member!.bloodType),
                          AdminDetailRow(label: 'Contato Emergência', value: _member!.emergencyContact),
                        ],

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Usuário Solicitante'),
                        if (_requester != null) ...[
                          AdminDetailRow(label: 'Nome', value: _requester!.name),
                          AdminDetailRow(label: 'E-mail', value: _requester!.email),
                          AdminDetailRow(label: 'Telefone', value: _requester!.phone),
                        ],

                        const SizedBox(height: 24),
                        const AdminSectionTitle(title: 'Anotações do Admin (Opcional)'),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Adicione notas sobre a análise...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        
        // Ações Positivas
        Text(
          'CONCORDÂNCIA E APROVAÇÃO',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Só mostra aprovar se não estiver ativa e não for renovação
            if (widget.request.status != 'active' && widget.request.status != 'renewing')
              AdminActionButton(
                label: 'APROVAR',
                icon: Icons.check_circle_rounded,
                color: AppColors.adminPositive,
                onTap: () => _confirmStatusUpdate('active', 'Aprovar'),
              ),
            
            // Só mostra renovar se o status for renovação (solicitado pelo user)
            if (widget.request.status == 'renewing')
              AdminActionButton(
                label: 'APROVAR RENOVAÇÃO',
                icon: Icons.sync_rounded,
                color: AppColors.adminPositive,
                onTap: () => _confirmStatusUpdate('active', 'Renovar'),
              ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Ações de Análise
        Text(
          'ANÁLISE E PENDÊNCIAS',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AdminActionButton(
              label: 'SOLICITAR DOCS',
              icon: Icons.file_present_rounded,
              color: AppColors.adminRequest,
              onTap: () => _confirmStatusUpdate('waiting_docs', 'Solicitar Documentos'),
            ),
            AdminActionButton(
              label: 'REVISAR DADOS',
              icon: Icons.edit_note_rounded,
              color: AppColors.adminAnalysis,
              isOutline: true,
              onTap: () => _confirmStatusUpdate('reviewing_data', 'Revisar Dados'),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Ações Negativas/Perigosas
        Text(
          'AÇÕES RESTRITIVAS',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AdminActionButton(
              label: 'REPROVAR',
              icon: Icons.cancel_outlined,
              color: AppColors.adminDanger,
              isOutline: true,
              onTap: () => _confirmStatusUpdate('rejected', 'Reprovar'),
            ),
            AdminActionButton(
              label: 'SUSPENDER',
              icon: Icons.block_outlined,
              color: AppColors.adminBlock,
              onTap: () => _confirmStatusUpdate('suspended', 'Suspender'),
            ),
          ],
        ),
      ],
    );
  }


  Future<void> _openUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }


}
