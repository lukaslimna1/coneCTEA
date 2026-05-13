import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/services/google_drive_service.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/card_request.dart';
import 'package:intl/intl.dart';
import 'package:conectea/core/widgets/premium_auth_background.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';
import 'package:conectea/features/requests/widgets/request_input_field.dart';
import 'package:conectea/features/requests/widgets/request_dropdown_field.dart';
import 'package:conectea/features/requests/widgets/request_searchable_dropdown.dart';
import 'package:conectea/features/requests/widgets/request_upload_field.dart';
import 'package:conectea/features/requests/widgets/request_admin_notes_banner.dart';
import 'package:conectea/features/requests/widgets/request_success_dialog.dart';
import 'package:conectea/features/requests/widgets/request_page_header.dart';
import 'package:conectea/features/requests/widgets/request_form_section.dart';
import 'package:conectea/features/requests/utils/request_cpf_validator.dart';

class AddMemberPage extends StatefulWidget {
  final Member? member;
  final CardRequest? request;
  const AddMemberPage({super.key, this.member, this.request});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  // Controladores de formulário e serviços
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
      final notes = widget.request!.adminNotes;
      if (!notes.contains('Pendência:')) {
        return true; // Desbloqueia tudo se o administrador não usou os checkboxes de pendência
      }
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
      _selectedBloodType = m.bloodType.isNotEmpty ? m.bloodType : null;
      _selectedState = m.state.isNotEmpty ? m.state : null;
      _selectedCity = m.city.isNotEmpty ? m.city : null;
      _documentUrl = m.documentUrl.isNotEmpty ? m.documentUrl : null;
      _medicalReportUrl = m.medicalReportUrl.isNotEmpty
          ? m.medicalReportUrl
          : null;
      if (_selectedState != null) {
        _fetchCities(_selectedState!, resetCity: false);
      }
    }
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _states = data
                .map(
                  (s) => {
                    'id': s['id'],
                    'sigla': s['sigla'],
                    'nome': s['nome'],
                  },
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar estados');
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
        Uri.parse(
          'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$stateSigla/municipios?orderBy=nome',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _cities = data.map((c) => c['nome'].toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar cidades');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCities = false);
      }
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
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final prefix = isDocument ? 'DOC' : 'LAUDO';
    final tokenId = const Uuid().v4().substring(0, 8).toUpperCase();
    final fileName = '${prefix}_MBR_$tokenId.${file.extension}';

    setState(() {
      if (isDocument) {
        _isUploadingDoc = true;
      } else {
        _isUploadingReport = true;
      }
    });

    try {
      final url = await _driveService.uploadFile(
        file: file,
        fileName: fileName,
      );
      if (url != null) {
        if (mounted) {
          setState(() {
            if (isDocument) {
              _documentUrl = url;
              _documentFileName = file.name;
            } else {
              _medicalReportUrl = url;
              _medicalReportFileName = file.name;
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha no upload. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Não foi possível enviar o arquivo agora. Verifique sua conexão e tente novamente.',
            ),
            backgroundColor: Colors.red,
          ),
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
        const SnackBar(
          content: Text('Por favor, selecione Estado e Cidade'),
          backgroundColor: Colors.red,
        ),
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
      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

      // Verifica CPF duplicado apenas ao criar novo ou alterar o CPF atual
      if (!isEditing ||
          (isEditing &&
              widget.member!.cpf.replaceAll(RegExp(r'[^0-9]'), '') !=
                  cleanCpf)) {
        final cpfExists = await _databaseService.isMemberCpfRegistered(
          cleanCpf,
        );
        if (cpfExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Este CPF já possui uma carteirinha cadastrada ou solicitação em andamento.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

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

        // Retorna o status da solicitação associada para 'waiting_approval' após edição
        final requests = await _databaseService.getCardRequests(userId);
        final memberRequest = requests
            .where((r) => r.memberId == member.id)
            .toList();

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
            content: const Text(
              'Não foi possível salvar a solicitação agora. Verifique os dados e tente novamente.',
            ),
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
      builder: (context) => RequestSuccessDialog(protocol: protocol),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051124),
      body: PremiumAuthBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: RequestPageHeader(
                  isEditing: widget.member != null,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      RequestFormSection(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.request != null &&
                                  (widget.request!.status == 'reviewing_data' ||
                                      widget.request!.status == 'waiting_docs'))
                                RequestAdminNotesBanner(
                                  adminNotes: widget.request!.adminNotes,
                                ),

                              const SizedBox(height: 12),

                              RequestInputField(
                                label: 'Nome completo do Beneficiário*',
                                controller: _nomeController,
                                hint: 'Digite o nome completo',
                                icon: PhosphorIconsRegular.user,
                                validator: (v) =>
                                    v!.isEmpty ? 'Campo obrigatório' : null,
                                enabled: _isFieldEnabled('Nome Completo'),
                              ),
                              const SizedBox(height: 20),

                              RequestInputField(
                                label: 'CPF*',
                                controller: _cpfController,
                                hint: '000.000.000-00',
                                icon: PhosphorIconsRegular.identificationCard,
                                inputFormatters: [cpfMask],
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Campo obrigatório';
                                  }
                                  if (!isValidCpf(v)) {
                                    return 'CPF inválido';
                                  }
                                  return null;
                                },
                                enabled: _isFieldEnabled('CPF'),
                              ),
                              const SizedBox(height: 20),

                              RequestInputField(
                                label: 'Data de Nascimento*',
                                controller: _nascimentoController,
                                hint: 'DD/MM/AAAA',
                                icon: PhosphorIconsRegular.calendar,
                                inputFormatters: [dateMask],
                                keyboardType: TextInputType.datetime,
                                validator: (v) =>
                                    v!.length < 10 ? 'Data incompleta' : null,
                                enabled: _isFieldEnabled('Data de Nascimento'),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: RequestSearchableDropdown(
                                      label: 'Estado*',
                                      value: _selectedState,
                                      items: _states
                                          .map((s) => s['sigla'] as String)
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() => _selectedState = val);
                                        _fetchCities(val);
                                      },
                                      icon: PhosphorIconsRegular.mapPin,
                                      enabled: _isFieldEnabled('Estado'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 5,
                                    child: RequestSearchableDropdown(
                                      label: 'Cidade*',
                                      value: _selectedCity,
                                      items: _cities,
                                      onChanged: (val) =>
                                          setState(() => _selectedCity = val),
                                      icon:
                                          PhosphorIconsRegular.navigationArrow,
                                      hint: _isLoadingCities
                                          ? 'Carregando...'
                                          : 'Selecione',
                                      enabled: _isFieldEnabled('Cidade'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              RequestInputField(
                                label: 'Telefone',
                                controller: _telefoneController,
                                hint: '(00) 00000-0000',
                                icon: PhosphorIconsRegular.phone,
                                inputFormatters: [phoneMask],
                                keyboardType: TextInputType.phone,
                                enabled: _isFieldEnabled('Telefone'),
                              ),
                              const SizedBox(height: 20),

                              RequestInputField(
                                label: 'Contato de Emergência (Opcional)',
                                controller: _contatoEmergenciaController,
                                hint: 'Nome e Telefone',
                                icon: PhosphorIconsRegular.firstAid,
                                enabled: _isFieldEnabled(
                                  'Contato de Emergência',
                                ),
                              ),
                              const SizedBox(height: 20),

                              RequestInputField(
                                label: 'Contato do Responsável (Opcional)',
                                controller: _responsavelController,
                                hint: 'Nome e Telefone (se menor)',
                                icon: PhosphorIconsRegular.users,
                                enabled: _isFieldEnabled('Responsável'),
                              ),
                              const SizedBox(height: 20),

                              RequestUploadField(
                                label: 'Documento com Foto (RG/CNH)',
                                fileName: _documentFileName,
                                isUploading: _isUploadingDoc,
                                isUploaded: _documentUrl != null,
                                onTap: () =>
                                    _pickAndUploadFile(isDocument: true),
                                icon: PhosphorIconsRegular.image,
                                enabled: _isFieldEnabled(
                                  'Documento com Foto (RG/CNH)',
                                ),
                              ),
                              const SizedBox(height: 20),

                              RequestUploadField(
                                label: 'Laudo Médico',
                                fileName: _medicalReportFileName,
                                isUploading: _isUploadingReport,
                                isUploaded: _medicalReportUrl != null,
                                onTap: () =>
                                    _pickAndUploadFile(isDocument: false),
                                icon: PhosphorIconsRegular.stethoscope,
                                enabled: _isFieldEnabled('Laudo Médico'),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.alertOrange.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.alertOrange.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      PhosphorIconsRegular.info,
                                      color: AppColors.alertOrange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Os documentos são opcionais agora. Podemos solicitar documentação complementar durante a análise.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textPrimary
                                              .withValues(alpha: 0.8),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              RequestDropdownField<String>(
                                label: 'Tipo Sanguíneo (Opcional)',
                                value: _selectedBloodType,
                                items:
                                    [
                                          'A+',
                                          'A-',
                                          'B+',
                                          'B-',
                                          'AB+',
                                          'AB-',
                                          'O+',
                                          'O-',
                                          'Não sei',
                                          'Prefiro não informar',
                                        ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              t,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedBloodType = val),
                                icon: PhosphorIconsRegular.drop,
                                enabled: _isFieldEnabled('Tipo Sanguíneo'),
                              ),
                              const SizedBox(height: 20),

                              RequestInputField(
                                label: 'CID (Opcional)',
                                controller: _cidController,
                                hint: 'Ex: F84.0',
                                icon: PhosphorIconsRegular.clipboardText,
                                enabled: _isFieldEnabled('Laudo Médico'),
                              ),

                              const SizedBox(height: 40),

                              PremiumButton(
                                text: 'Salvar e Continuar',
                                onPressed: _handleSave,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 140), // Espaço para a ilustração
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
