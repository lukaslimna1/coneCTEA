import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/id_request.dart';
import '../../core/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';


class RequestIDScreen extends StatefulWidget {
  final IDRequest? existingRequest;
  const RequestIDScreen({super.key, this.existingRequest});

  @override
  State<RequestIDScreen> createState() => _RequestIDScreenState();
}

class _RequestIDScreenState extends State<RequestIDScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _cityController;
  late final TextEditingController _institutionController;
  late final TextEditingController _rgCpfController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;
  bool _docsUploaded = false;
  final String _googleFormUrl = 'https://forms.gle/exemplo'; // Substituir pela URL real do formulário

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingRequest?.applicantName);
    _birthDateController = TextEditingController(text: widget.existingRequest?.birthDate);
    _cityController = TextEditingController(text: widget.existingRequest?.city);
    _institutionController = TextEditingController(text: widget.existingRequest?.institution);
    _rgCpfController = TextEditingController(text: widget.existingRequest?.rgCpf);
    _phoneController = TextEditingController(text: widget.existingRequest?.phone);
    
    if (widget.existingRequest != null) {
      _docsUploaded = true; // Assume docs were already uploaded if editing
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _cityController.dispose();
    _institutionController.dispose();
    _rgCpfController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_docsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe os documentos via Google Form primeiro.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId == null) throw 'Usuário não autenticado';

      final request = IDRequest(
        id: widget.existingRequest?.id ?? '',
        userId: userId,
        applicantName: _nameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        city: _cityController.text.trim(),
        institution: _institutionController.text.trim(),
        rgCpf: _rgCpfController.text.trim(),
        phone: _phoneController.text.trim(),
        status: RequestStatus.pending, // Volta para pendente após edição
        createdAt: widget.existingRequest?.createdAt ?? DateTime.now(),
        adminNotes: widget.existingRequest?.adminNotes,
        cardNumber: widget.existingRequest?.cardNumber,
        expiryDate: widget.existingRequest?.expiryDate,
        photoUrl: widget.existingRequest?.photoUrl,
        driveLink: widget.existingRequest?.driveLink,
      );

      if (widget.existingRequest != null) {
        await DatabaseService().updateRequest(request);
      } else {
        await DatabaseService().createRequest(request);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingRequest != null ? 'Solicitação atualizada com sucesso!' : 'Solicitação enviada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Carteirinha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preencha os dados abaixo para solicitar sua carteirinha digital.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Pessoa Autista',
                  prefixIcon: Icon(Icons.person, color: AppColors.primary),
                  hintText: 'Nome completo',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Data de Nascimento',
                  prefixIcon: Icon(Icons.calendar_month, color: AppColors.primary),
                  hintText: 'DD/MM/AAAA',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                  hintText: 'Onde você mora',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Instituição (Opcional)',
                  prefixIcon: Icon(Icons.school, color: AppColors.primary),
                  hintText: 'Escola ou centro de apoio',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rgCpfController,
                decoration: const InputDecoration(
                  labelText: 'RG ou CPF',
                  prefixIcon: Icon(Icons.badge, color: AppColors.primary),
                  hintText: 'Número do documento',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp (DDD + Número)',
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                  hintText: '(00) 00000-0000',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              
              // Envio de Documentos via Google Drive/Forms
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Envio de Documentos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Para não ocupar espaço no seu celular e garantir a segurança, usamos o Google Drive para armazenar seus documentos.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse(_googleFormUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Abrir Formulário de Anexos',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _docsUploaded,
                      onChanged: (v) => setState(() => _docsUploaded = v ?? false),
                      title: const Text(
                        'Já finalizei o envio dos arquivos pelo formulário do Google.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: (_isLoading || !_docsUploaded) ? null : _submit,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Enviar Solicitação', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Lembre-se: A validação dos documentos será feita via WhatsApp pela nossa equipe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
