import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/member.dart';

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _contatoEmergenciaController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _documentUrlController = TextEditingController();
  final _medicalReportUrlController = TextEditingController();
  final _cidController = TextEditingController();
  String? _selectedBloodType;

  bool _isLoading = false;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _cidadeController.dispose();
    _telefoneController.dispose();
    _contatoEmergenciaController.dispose();
    _responsavelController.dispose();
    _nascimentoController.dispose();
    _documentUrlController.dispose();
    _medicalReportUrlController.dispose();
    _cidController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      DateTime? parsedBirthDate;
      if (_nascimentoController.text.isNotEmpty) {
        try {
          final parts = _nascimentoController.text.split('/');
          if (parts.length == 3) {
            parsedBirthDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }

      final member = Member(
        id: const Uuid().v4(),
        userId: userId,
        name: _nomeController.text.trim(),
        cpf: _cpfController.text,
        city: _cidadeController.text.trim(),
        phone: _telefoneController.text,
        emergencyContact: _contatoEmergenciaController.text,
        responsibleName: _responsavelController.text.trim(),
        dateOfBirth: _nascimentoController.text,
        bloodType: _selectedBloodType ?? '',
        cid: _cidController.text.trim(),
        documentUrl: _documentUrlController.text.trim(),
        medicalReportUrl: _medicalReportUrlController.text.trim(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.addMember(member);

      if (mounted) {
        context.pop(member); // Retorna o membro criado
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar dependente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Novo Dependente',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cadastre quem receberá a carteirinha. Pode ser você mesmo ou um dependente.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              _buildInputField(
                label: 'Nome completo do Beneficiário*',
                controller: _nomeController,
                hint: 'Digite o nome completo',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'CPF*',
                controller: _cpfController,
                hint: '000.000.000-00',
                icon: Icons.badge_outlined,
                inputFormatters: [cpfMask],
                keyboardType: TextInputType.number,
                validator: (v) => v!.length < 14 ? 'CPF incompleto' : null,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Data de Nascimento*',
                controller: _nascimentoController,
                hint: 'DD/MM/AAAA',
                icon: Icons.calendar_today_outlined,
                inputFormatters: [dateMask],
                keyboardType: TextInputType.datetime,
                validator: (v) => v!.length < 10 ? 'Data incompleta' : null,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Cidade | Estado*',
                controller: _cidadeController,
                hint: 'Ex: Bauru - SP',
                icon: Icons.location_on_outlined,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Telefone',
                controller: _telefoneController,
                hint: '(00) 00000-0000',
                icon: Icons.phone_outlined,
                inputFormatters: [phoneMask],
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Contato de Emergência (Opcional)',
                controller: _contatoEmergenciaController,
                hint: 'Nome e Telefone',
                icon: Icons.emergency_outlined,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Contato do Responsável (Opcional)',
                controller: _responsavelController,
                hint: 'Nome e Telefone (se menor)',
                icon: Icons.family_restroom_outlined,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Link do Documento com Foto (RG/CNH)*',
                controller: _documentUrlController,
                hint: 'Cole o link do Google Drive',
                icon: Icons.link_rounded,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Link do Laudo Médico*',
                controller: _medicalReportUrlController,
                hint: 'Cole o link do Google Drive',
                icon: Icons.medical_information_outlined,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdownField(
                      label: 'Tipo Sanguíneo',
                      value: _selectedBloodType,
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                      onChanged: (val) =>
                          setState(() => _selectedBloodType = val),
                      icon: Icons.bloodtype_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildInputField(
                      label: 'CID (Opcional)',
                      controller: _cidController,
                      hint: 'Ex: F84.0',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Salvar e Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, style: GoogleFonts.inter(fontSize: 15)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
