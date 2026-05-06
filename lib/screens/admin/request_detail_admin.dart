import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/id_request.dart';
import '../../services/database_service.dart';
import '../../core/app_theme.dart';

class RequestDetailAdmin extends StatefulWidget {
  final IDRequest request;

  const RequestDetailAdmin({super.key, required this.request});

  @override
  State<RequestDetailAdmin> createState() => _RequestDetailAdminState();
}

class _RequestDetailAdminState extends State<RequestDetailAdmin> {
  final _db = DatabaseService();
  final _cardNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _driveLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.text = widget.request.cardNumber ?? '';
    _notesController.text = widget.request.adminNotes ?? '';
    _driveLinkController.text = widget.request.driveLink ?? '';
  }

  Future<void> _updateStatus(RequestStatus status) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      DateTime? expiry;
      if (status == RequestStatus.approved) {
        expiry = DateTime.now().add(const Duration(days: 365)); // 1 year validity
      }

      await _db.updateRequestStatus(
        widget.request.id,
        IDRequest.statusToString(status),
        cardNumber: _cardNumberController.text.trim().isEmpty ? null : _cardNumberController.text.trim(),
        expiryDate: expiry,
        adminNotes: _notesController.text,
        driveLink: _driveLinkController.text.trim().isEmpty ? null : _driveLinkController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmStatusUpdate(RequestStatus status) async {
    final needsJustification = [
      RequestStatus.rejected,
      RequestStatus.suspended,
      RequestStatus.waitingDocument,
      RequestStatus.needsAdjustment,
    ].contains(status);

    if (!needsJustification) {
      _updateStatus(status);
      return;
    }

    String label = '';
    String prompt = '';
    IconData icon = Icons.info_outline;
    Color color = AppColors.primary;
    
    switch (status) {
      case RequestStatus.rejected:
        label = 'Reprovar Solicitação';
        prompt = 'Por que esta solicitação está sendo reprovada? Informe o motivo detalhado para o usuário.';
        icon = Icons.cancel_rounded;
        color = AppColors.error;
        break;
      case RequestStatus.suspended:
        label = 'Suspender Carteirinha';
        prompt = 'Qual o motivo da suspensão? Esta justificativa aparecerá para o usuário.';
        icon = Icons.block_rounded;
        color = Colors.black;
        break;
      case RequestStatus.waitingDocument:
        label = 'Solicitar Documentação';
        prompt = 'Quais documentos estão faltando? O usuário verá esta lista para enviar no Drive.';
        icon = Icons.file_present_rounded;
        color = AppColors.primary;
        break;
      case RequestStatus.needsAdjustment:
        label = 'Solicitar Correção';
        prompt = 'Descreva detalhadamente o que o usuário precisa corrigir (ex: foto embaçada, nome errado).';
        icon = Icons.edit_note_rounded;
        color = Colors.orange;
        break;
      default:
        label = 'Justificativa Necessária';
        prompt = 'Informe o motivo para esta alteração:';
    }

    final controller = TextEditingController(text: _notesController.text);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escreva aqui a justificativa...',
                fillColor: color.withValues(alpha: 0.05),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A justificativa é obrigatória')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (result == true) {
      _notesController.text = controller.text.trim();
      _updateStatus(status);
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = widget.request.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final name = widget.request.applicantName;
    final message = 'Olá $name, sou da equipe ConeCTEA. Recebemos sua solicitação de carteirinha digital. Por favor, envie o documento com foto e o laudo médico por aqui para validação.';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.request.status == RequestStatus.approved;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Gestão ConeCTEA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection('Dados do Solicitante', [
              _buildInfoRow('Nome', widget.request.applicantName, Icons.person_outline),
              _buildInfoRow('Nascimento', widget.request.birthDate, Icons.calendar_today_outlined),
              _buildInfoRow('RG/CPF', widget.request.rgCpf, Icons.badge_outlined),
              _buildInfoRow('Telefone/Whats', widget.request.phone, Icons.phone_android_outlined),
              _buildInfoRow('Cidade', widget.request.city, Icons.location_on_outlined),
              _buildInfoRow('Instituição', widget.request.institution, Icons.school_outlined),
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  const Text('Status Atual:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Icon(widget.request.statusIcon, color: widget.request.statusColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    widget.request.adminStatusLabel,
                    style: TextStyle(
                      color: widget.request.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (isApproved) ...[
                const SizedBox(height: 16),
                _buildInfoRow('Validade', widget.request.expiryDate != null ? '${widget.request.expiryDate!.day}/${widget.request.expiryDate!.month}/${widget.request.expiryDate!.year}' : 'N/A', Icons.event_available_outlined),
              ],
              if (widget.request.driveLink != null && widget.request.driveLink!.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.folder_shared_outlined, size: 20),
                    label: const Text('Ver Documentos no Drive'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse(widget.request.driveLink!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 32),
            const Text('Ações de Gestão', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            if (!isApproved) ...[
              TextField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número da Carteirinha (Opcional)',
                  hintText: 'Deixe vazio para gerar automático',
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: isApproved ? 'Motivo da Suspensão / Notas de Edição' : 'Observações para o Usuário',
                hintText: 'Justificativa para reprovação, suspensão ou ajustes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (widget.request.status != RequestStatus.approved) ...[
               TextField(
                controller: _driveLinkController,
                decoration: InputDecoration(
                  labelText: 'Link do Google Drive (Documentos)',
                  hintText: 'Link para os documentos anexados',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 32),
            ],
            if (!isApproved) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : () => _updateStatus(RequestStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text('APROVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : () => _confirmStatusUpdate(RequestStatus.rejected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text('REPROVAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_present_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : () => _confirmStatusUpdate(RequestStatus.waitingDocument),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text('FALTAM DOCS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : () => _confirmStatusUpdate(RequestStatus.needsAdjustment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text('PEDIR AJUSTE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Actions for APPROVED or RENEWAL_REQUESTED (as approved cards showing for renewal)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : _showEditDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text('EDITAR DADOS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.block_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : () => _confirmStatusUpdate(RequestStatus.suspended),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: const Text('SUSPENDER', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.request.status == RequestStatus.renewalRequested)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.autorenew_rounded, color: Colors.white),
                    onPressed: _isLoading ? null : () => _updateStatus(RequestStatus.approved),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: const Text('EFETUAR RENOVAÇÃO', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: _launchWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                label: const Text('Falar no WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.request.applicantName);
    final cardNumberController = TextEditingController(text: widget.request.cardNumber);
    final driveLinkController = TextEditingController(text: widget.request.driveLink);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Editar Dados'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: const InputDecoration(
                  labelText: 'Nome do Beneficiário',
                  prefixIcon: Icon(Icons.person_outline),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardNumberController, 
                decoration: const InputDecoration(
                  labelText: 'Número da Carteirinha',
                  prefixIcon: Icon(Icons.badge_outlined),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: driveLinkController, 
                decoration: const InputDecoration(
                  labelText: 'Link do Google Drive',
                  prefixIcon: Icon(Icons.link_rounded),
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded),
            onPressed: () async {
              if (!mounted) return;
              final navigator = Navigator.of(context);
              await _db.updateRequestData(widget.request.id, {
                'applicant_name': nameController.text.trim(),
                'card_number': cardNumberController.text.trim(),
                'drive_link': driveLinkController.text.trim(),
              });
              
              if (!mounted) return;
              
              // Fechar o diálogo primeiro
              navigator.pop();
              
              // Pequeno delay para garantir que o diálogo fechou antes de navegar
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (mounted) {
                navigator.pop(); // Voltar para a lista
              }
            },
            label: const Text('Salvar Alterações'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
