import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  Future<void> _updateStatus(RequestStatus status) async {
    setState(() => _isLoading = true);
    try {
      DateTime? expiry;
      if (status == RequestStatus.approved) {
        expiry = DateTime.now().add(const Duration(days: 365 * 5)); // 5 years validity
      }

      await _db.updateRequestStatus(
        widget.request.id,
        IDRequest.statusToString(status),
        cardNumber: _cardNumberController.text.isEmpty ? null : _cardNumberController.text,
        expiryDate: expiry,
        adminNotes: _notesController.text,
      );
      
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Solicitação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection('Dados do Solicitante', [
              _buildInfoRow('Nome', widget.request.applicantName),
              _buildInfoRow('Nascimento', widget.request.birthDate),
              _buildInfoRow('Cidade', widget.request.city),
              _buildInfoRow('Instituição', widget.request.institution),
            ]),
            const SizedBox(height: 32),
            const Text('Ações Administrativas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Número da Carteirinha (Se aprovado)',
                hintText: 'Ex: 2024-0001',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações Internas',
                hintText: 'Motivo da recusa ou notas de ajuste',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _updateStatus(RequestStatus.approved),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Aprovar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _updateStatus(RequestStatus.rejected),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    child: const Text('Recusar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _updateStatus(RequestStatus.waitingContact),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.pending),
              child: const Text('Solicitar Ajuste / Contato WhatsApp'),
            ),
          ],
        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
