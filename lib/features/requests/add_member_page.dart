import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_drive_service.dart';
import '../../models/member.dart';
import '../../models/card_request.dart';
import 'package:intl/intl.dart';

class AddMemberPage extends StatefulWidget {
  final Member? member;
  final CardRequest? request;
  const AddMemberPage({super.key, this.member, this.request});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  // ... existing controllers ...
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _driveService = GoogleDriveService();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _contatoEmergenciaController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _cidController = TextEditingController();
  
  String? _selectedBloodType;
  String? _selectedState;
  String? _selectedCity;
  
  List<Map<String, dynamic>> _states = [];
  List<String> _cities = [];
  bool _isLoadingCities = false;

  String? _documentUrl;
  String? _documentFileName;
  bool _isUploadingDoc = false;

  String? _medicalReportUrl;
  String? _medicalReportFileName;
  bool _isUploadingReport = false;

  bool _isLoading = false;

  bool _isFieldEnabled(String fieldName) {
    if (widget.request == null) return true;
    if (widget.request!.status == 'reviewing_data' || 
        widget.request!.status == 'waiting_docs') {
      final notes = widget.request!.adminNotes ?? '';
      if (!notes.contains('Pendência:')) return true; // Unlock all if admin didn't use checkboxes
      return notes.toLowerCase().contains(fieldName.toLowerCase());
    }
    return false;
  }

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
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _nomeController.text = m.name;
      _cpfController.text = m.cpf;
      _telefoneController.text = m.phone;
      _contatoEmergenciaController.text = m.emergencyContact;
      _responsavelController.text = m.responsibleName;
      _nascimentoController.text = m.dateOfBirth;
      _cidController.text = m.cid;
      _selectedBloodType = m.bloodType;
      _selectedState = m.state;
      _selectedCity = m.city;
      _documentUrl = m.documentUrl.isNotEmpty ? m.documentUrl : null;
      _medicalReportUrl = m.medicalReportUrl.isNotEmpty ? m.medicalReportUrl : null;
      if (_selectedState != null) _fetchCities(_selectedState!, resetCity: false);
    }
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _states = data.map((s) => {
            'id': s['id'],
            'sigla': s['sigla'],
            'nome': s['nome'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar estados: $e');
    }
  }

  Future<void> _fetchCities(String stateSigla, {bool resetCity = true}) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      if (resetCity) {
        _selectedCity = null;
      }
    });
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$stateSigla/municipios?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _cities = data.map((c) => c['nome'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar cidades: $e');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _contatoEmergenciaController.dispose();
    _responsavelController.dispose();
    _nascimentoController.dispose();
    _cidController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile({required bool isDocument}) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final nome = _nomeController.text.trim();
    final prefix = isDocument ? 'DOC' : 'LAUDO';
    final tokenId = const Uuid().v4().substring(0, 8).toUpperCase();
    final fileName = '${prefix}_${tokenId}_${nome.isNotEmpty ? nome.replaceAll(' ', '_') : 'SemNome'}.${file.extension}';

    setState(() {
      if (isDocument) {
        _isUploadingDoc = true;
      } else {
        _isUploadingReport = true;
      }
    });

    try {
      final url = await _driveService.uploadFile(file: file, fileName: fileName);
      if (url != null) {
        setState(() {
          if (isDocument) {
            _documentUrl = url;
            _documentFileName = file.name;
          } else {
            _medicalReportUrl = url;
            _medicalReportFileName = file.name;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha no upload. Tente novamente.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isDocument) {
            _isUploadingDoc = false;
          } else {
            _isUploadingReport = false;
          }
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione Estado e Cidade'), backgroundColor: Colors.red),
      );
      return;
    }

    // Documentos agora são opcionais no cadastro inicial
    /* 
    if (_documentUrl == null || _medicalReportUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe a Foto e o Laudo Médico'), backgroundColor: Colors.red),
      );
      return;
    }
    */

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final isEditing = widget.member != null;

      final member = Member(
        id: isEditing ? widget.member!.id : const Uuid().v4(),
        userId: userId,
        name: _nomeController.text.trim(),
        cpf: _cpfController.text,
        city: _selectedCity!,
        state: _selectedState!,
        phone: _telefoneController.text,
        emergencyContact: _contatoEmergenciaController.text,
        responsibleName: _responsavelController.text.trim(),
        dateOfBirth: _nascimentoController.text,
        bloodType: _selectedBloodType ?? '',
        cid: _cidController.text.trim(),
        documentUrl: _documentUrl ?? '',
        medicalReportUrl: _medicalReportUrl ?? '',
        status: isEditing ? widget.member!.status : 'waiting_approval',
        createdAt: isEditing ? widget.member!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String generatedProtocol = '';
      if (isEditing) {
        await _databaseService.updateMember(member);
        
        // Update associated request status back to waiting_approval
        final requests = await _databaseService.getCardRequests(userId);
        final memberRequest = requests.where((r) => r.memberId == member.id).toList();
        
        if (memberRequest.isNotEmpty) {
          final req = memberRequest.first;
          final updatedRequest = req.copyWith(
            status: 'waiting_approval',
            updatedAt: DateTime.now(),
            documentUrl: member.documentUrl,
            medicalReportUrl: member.medicalReportUrl,
          );
          await _databaseService.updateCardRequest(updatedRequest);
        }
      } else {
        await _databaseService.addMember(member);

        // Criar a solicitação de carteirinha automaticamente
        final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
        final random = const Uuid().v4().substring(0, 4).toUpperCase();
        generatedProtocol = 'REQ-$dateStr-$random';

        final request = CardRequest(
          id: const Uuid().v4(),
          userId: userId,
          memberId: member.id,
          type: 'Emissão Digital',
          status: 'waiting_approval',
          protocol: generatedProtocol,
          adminNotes: '',
          driveFolderUrl: '',
          documentUrl: member.documentUrl,
          medicalReportUrl: member.medicalReportUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.createCardRequest(request);
      }

      if (mounted) {
        if (isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados atualizados com sucesso!')),
          );
          Navigator.pop(context);
        } else {
          _showSuccessDialog(generatedProtocol);
        }
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

  void _showSuccessDialog(String protocol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.statusGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.statusGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Solicitação Enviada!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O dependente foi cadastrado e a solicitação de carteirinha enviada com sucesso.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Text(
                protocol,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Voltar para o Início',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _isValidCPF(String cpf) {
    String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;
    return true;
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
              if (widget.request != null && (widget.request!.status == 'reviewing_data' || widget.request!.status == 'waiting_docs'))
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
                          const SizedBox(width: 8),
                          Text(
                            'Ajuste solicitado pelo Administrador',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.request!.adminNotes,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.orange[900],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

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
                enabled: _isFieldEnabled('Nome Completo'),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'CPF*',
                controller: _cpfController,
                hint: '000.000.000-00',
                icon: Icons.badge_outlined,
                inputFormatters: [cpfMask],
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (!_isValidCPF(v)) return 'CPF inválido';
                  return null;
                },
                enabled: _isFieldEnabled('CPF'),
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
                enabled: _isFieldEnabled('Data de Nascimento'),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSearchableDropdown(
                      label: 'Estado*',
                      value: _selectedState,
                      items: _states.map((s) => s['sigla'] as String).toList(),
                      onChanged: (val) {
                        setState(() => _selectedState = val);
                        _fetchCities(val);
                      },
                      icon: Icons.map_outlined,
                      enabled: _isFieldEnabled('Estado'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: _buildSearchableDropdown(
                      label: 'Cidade*',
                      value: _selectedCity,
                      items: _cities,
                      onChanged: (val) => setState(() => _selectedCity = val),
                      icon: Icons.location_on_outlined,
                      hint: _isLoadingCities ? 'Carregando...' : 'Selecione',
                      enabled: _isFieldEnabled('Cidade'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Telefone',
                controller: _telefoneController,
                hint: '(00) 00000-0000',
                icon: Icons.phone_outlined,
                inputFormatters: [phoneMask],
                keyboardType: TextInputType.phone,
                enabled: _isFieldEnabled('Telefone'),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Contato de Emergência (Opcional)',
                controller: _contatoEmergenciaController,
                hint: 'Nome e Telefone',
                icon: Icons.emergency_outlined,
                enabled: _isFieldEnabled('Contato de Emergência'),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Contato do Responsável (Opcional)',
                controller: _responsavelController,
                hint: 'Nome e Telefone (se menor)',
                icon: Icons.family_restroom_outlined,
                enabled: _isFieldEnabled('Responsável'),
              ),
              const SizedBox(height: 20),

              _buildUploadField(
                label: 'Documento com Foto (RG/CNH)',
                fileName: _documentFileName,
                isUploading: _isUploadingDoc,
                isUploaded: _documentUrl != null,
                onTap: () => _pickAndUploadFile(isDocument: true),
                icon: Icons.badge_outlined,
                enabled: _isFieldEnabled('Documento de Identidade (RG/CNH)'),
              ),
              const SizedBox(height: 20),

              _buildUploadField(
                label: 'Laudo Médico',
                fileName: _medicalReportFileName,
                isUploading: _isUploadingReport,
                isUploaded: _medicalReportUrl != null,
                onTap: () => _pickAndUploadFile(isDocument: false),
                icon: Icons.medical_information_outlined,
                enabled: _isFieldEnabled('Laudo Médico (CID)'),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF9A825), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Os documentos são opcionais agora. Podemos solicitar documentação complementar durante a análise.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF5D4037),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildDropdownField<String>(
                label: 'Tipo Sanguíneo (Opcional)',
                value: _selectedBloodType,
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Não sei', 'Prefiro não informar']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) =>
                    setState(() => _selectedBloodType = val),
                icon: Icons.bloodtype_outlined,
                enabled: _isFieldEnabled('Tipo Sanguíneo'),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'CID (Opcional)',
                controller: _cidController,
                hint: 'Ex: F84.0',
                icon: Icons.assignment_outlined,
                enabled: _isFieldEnabled('Laudo Médico (CID)'),
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
    bool enabled = true,
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
          enabled: enabled,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5), size: 22),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.black.withValues(alpha: 0.03),
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

  
  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String) onChanged,
    bool enabled = true,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.darkBlue,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SearchAnchor(
          builder: (context, controller) {
            return InkWell(
              onTap: enabled ? () => controller.openView() : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: enabled ? Colors.white : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: enabled ? AppColors.primary : Colors.grey, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? hint ?? 'Selecione',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          },
          viewHintText: 'Digite para buscar...',
          viewLeading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          suggestionsBuilder: (context, controller) {
            final keyword = controller.text.toLowerCase();
            final filtered = items
                .where((item) => item.toLowerCase().contains(keyword))
                .toList();

            return filtered.map((item) => ListTile(
              title: Text(item),
              onTap: () {
                controller.closeView(item);
                onChanged(item);
              },
            ));
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    String? hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5), size: 22),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
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

  Widget _buildUploadField({
    required String label,
    required String? fileName,
    required bool isUploading,
    required bool isUploaded,
    required VoidCallback onTap,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: (isUploading || !enabled) ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isUploaded 
                  ? AppColors.primary.withValues(alpha: 0.06) 
                  : (enabled ? Colors.white : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUploaded 
                    ? AppColors.primary 
                    : (enabled ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                width: isUploaded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUploaded ? Icons.check_circle_rounded : icon,
                  color: isUploaded 
                      ? Colors.green 
                      : (enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5)),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isUploading
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text('Enviando...', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                          ],
                        )
                      : Text(
                          isUploaded ? fileName ?? 'Arquivo enviado' : (enabled ? 'Toque para enviar arquivo' : 'Campo bloqueado'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isUploaded ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: isUploaded ? FontWeight.w600 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (!isUploading && enabled)
                  Icon(
                    isUploaded ? Icons.refresh_rounded : Icons.upload_file_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
