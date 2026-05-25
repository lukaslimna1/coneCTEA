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
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_input_field.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_dropdown_field.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_searchable_dropdown.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_upload_field.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_admin_notes_banner.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_success_dialog.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_page_header.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_form_section.dart';
import 'package:conectea/features/carteirinhas/solicitacao/utils/request_cpf_validator.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_later_button.dart';
import 'package:conectea/features/carteirinhas/solicitacao/widgets/request_unsaved_changes_dialog.dart';
import 'package:conectea/features/carteirinhas/solicitacao/helpers/request_cleanup_helper.dart';

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
  final _contatoEmergenciaNomeController = TextEditingController();
  final _contatoEmergenciaTelefoneController = TextEditingController();
  final _responsavelNomeController = TextEditingController();
  final _responsavelTelefoneController = TextEditingController();
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
  final List<String> _uploadedUrlsThisSession = [];

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

  final emergencyPhoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final responsiblePhoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String _composeContact(String name, String phone) {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isNotEmpty && cleanPhone.isNotEmpty) {
      return '$cleanName - $cleanPhone';
    } else if (cleanName.isNotEmpty) {
      return cleanName;
    } else if (cleanPhone.isNotEmpty) {
      return cleanPhone;
    }
    return '';
  }

  Map<String, String> _parseContact(String value) {
    if (value.contains(' - ')) {
      final parts = value.split(' - ');
      return {
        'name': parts[0].trim(),
        'phone': parts.sublist(1).join(' - ').trim(),
      };
    }
    return {'name': value.trim(), 'phone': ''};
  }

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _nomeController.text = m.name;
      _cpfController.text = m.cpf;
      _telefoneController.text = m.phone;

      // Parse do contato de emergência legado
      final parsedEmerg = _parseContact(m.emergencyContact);
      _contatoEmergenciaNomeController.text = parsedEmerg['name'] ?? '';
      _contatoEmergenciaTelefoneController.text = parsedEmerg['phone'] ?? '';

      // Parse do responsável legado
      final parsedResp = _parseContact(m.responsibleName);
      _responsavelNomeController.text = parsedResp['name'] ?? '';
      _responsavelTelefoneController.text = parsedResp['phone'] ?? '';

      _nascimentoController.text = m.dateOfBirth;
      _cidController.text = m.cid;
      _selectedBloodType = m.bloodType.isNotEmpty ? m.bloodType : null;
      _selectedState = m.state.isNotEmpty ? m.state : null;
      _selectedCity = m.city.isNotEmpty ? m.city : null;
      // Inicializar URLs originais do membro considerando o status de reenvio
      final documentEnabled = _isFieldEnabled('Documento com Foto (RG/CNH)');
      final medicalReportEnabled = _isFieldEnabled('Laudo Médico');

      // Se o campo está habilitado para edição em uma correção de pendências, o arquivo anterior é considerado inválido/rejeitado.
      // Portanto, limpamos as variáveis de URL locais para que o widget exiba o estado vazio ("Toque para enviar arquivo").
      _documentUrl = (m.documentUrl.isNotEmpty && !documentEnabled)
          ? m.documentUrl
          : null;
      _medicalReportUrl =
          (m.medicalReportUrl.isNotEmpty && !medicalReportEnabled)
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
    _contatoEmergenciaNomeController.dispose();
    _contatoEmergenciaTelefoneController.dispose();
    _responsavelNomeController.dispose();
    _responsavelTelefoneController.dispose();
    _nascimentoController.dispose();
    _cidController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile({required bool isDocument}) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'heif',
        'txt',
        'doc',
        'docx',
        'odt',
        'rtf',
      ],
    );
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
        _uploadedUrlsThisSession.add(url);
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

    // Validação específica para o fluxo de correção/reenvio de pendências
    if (widget.request != null &&
        (widget.request!.status == 'reviewing_data' ||
            widget.request!.status == 'waiting_docs')) {
      final docRequired = _isFieldEnabled('Documento com Foto (RG/CNH)');
      final reportRequired = _isFieldEnabled('Laudo Médico');

      if (docRequired && _documentUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, anexe o novo Documento com Foto (RG/CNH) pendente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (reportRequired && _medicalReportUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, anexe o novo Laudo Médico pendente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

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
        emergencyContact: _composeContact(
          _contatoEmergenciaNomeController.text,
          _contatoEmergenciaTelefoneController.text,
        ),
        responsibleName: _composeContact(
          _responsavelNomeController.text,
          _responsavelTelefoneController.text,
        ),
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

  bool _hasUnsavedChanges() {
    if (widget.member == null) {
      return _nomeController.text.isNotEmpty ||
          _cpfController.text.isNotEmpty ||
          _telefoneController.text.isNotEmpty ||
          _contatoEmergenciaNomeController.text.isNotEmpty ||
          _contatoEmergenciaTelefoneController.text.isNotEmpty ||
          _responsavelNomeController.text.isNotEmpty ||
          _responsavelTelefoneController.text.isNotEmpty ||
          _nascimentoController.text.isNotEmpty ||
          _cidController.text.isNotEmpty ||
          _selectedBloodType != null ||
          _selectedState != null ||
          _selectedCity != null ||
          _uploadedUrlsThisSession.isNotEmpty;
    }

    final m = widget.member!;
    if (_nomeController.text.trim() != m.name.trim()) return true;
    if (_cpfController.text.trim() != m.cpf.trim()) return true;
    if (_telefoneController.text.trim() != m.phone.trim()) return true;

    final parsedEmerg = _parseContact(m.emergencyContact);
    if (_contatoEmergenciaNomeController.text.trim() !=
        (parsedEmerg['name'] ?? '').trim())
      return true;
    if (_contatoEmergenciaTelefoneController.text.trim() !=
        (parsedEmerg['phone'] ?? '').trim())
      return true;

    final parsedResp = _parseContact(m.responsibleName);
    if (_responsavelNomeController.text.trim() !=
        (parsedResp['name'] ?? '').trim())
      return true;
    if (_responsavelTelefoneController.text.trim() !=
        (parsedResp['phone'] ?? '').trim())
      return true;

    if (_nascimentoController.text.trim() != m.dateOfBirth.trim()) return true;
    if (_cidController.text.trim() != m.cid.trim()) return true;

    final origBlood = m.bloodType.isNotEmpty ? m.bloodType : null;
    if (_selectedBloodType != origBlood) return true;

    final origState = m.state.isNotEmpty ? m.state : null;
    if (_selectedState != origState) return true;

    final origCity = m.city.isNotEmpty ? m.city : null;
    if (_selectedCity != origCity) return true;

    if (_uploadedUrlsThisSession.isNotEmpty) return true;

    return false;
  }

  Future<void> _handleBackAction() async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => const RequestUnsavedChangesDialog(),
      );

      if (shouldDiscard == true) {
        if (mounted) {
          await RequestCleanupHelper.performCleanupAndExit(
            context: context,
            driveService: _driveService,
            uploadedUrls: _uploadedUrlsThisSession,
          );
        }
      }
    } else {
      await RequestCleanupHelper.performCleanupAndExit(
        context: context,
        driveService: _driveService,
        uploadedUrls: _uploadedUrlsThisSession,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF051124),
        body: PremiumAuthBackground(
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: RequestPageHeader(
                    isEditing: widget.member != null,
                    onBackTap: _handleBackAction,
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
                                    (widget.request!.status ==
                                            'reviewing_data' ||
                                        widget.request!.status ==
                                            'waiting_docs'))
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
                                    final isEnabled = _isFieldEnabled('CPF');
                                    if (!isEnabled) return null;

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
                                  validator: (v) {
                                    final isEnabled = _isFieldEnabled(
                                      'Data de Nascimento',
                                    );
                                    if (!isEnabled) return null;
                                    return (v == null || v.length < 10)
                                        ? 'Data incompleta'
                                        : null;
                                  },
                                  enabled: _isFieldEnabled(
                                    'Data de Nascimento',
                                  ),
                                ),
                                const SizedBox(height: 20),

                                RequestSearchableDropdown(
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
                                const SizedBox(height: 20),

                                RequestSearchableDropdown(
                                  label: 'Cidade*',
                                  value: _selectedCity,
                                  items: _cities,
                                  onChanged: (val) =>
                                      setState(() => _selectedCity = val),
                                  icon: PhosphorIconsRegular.navigationArrow,
                                  hint: _isLoadingCities
                                      ? 'Carregando...'
                                      : 'Selecione',
                                  enabled: _isFieldEnabled('Cidade'),
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
                                  label:
                                      'Nome do Contato de Emergência (Opcional)',
                                  controller: _contatoEmergenciaNomeController,
                                  hint: 'Digite o nome do contato',
                                  icon: PhosphorIconsRegular.firstAid,
                                  enabled: _isFieldEnabled(
                                    'Contato de Emergência',
                                  ),
                                ),
                                const SizedBox(height: 20),

                                RequestInputField(
                                  label:
                                      'Número do Contato de Emergência (Opcional)',
                                  controller:
                                      _contatoEmergenciaTelefoneController,
                                  hint: '(00) 00000-0000',
                                  icon: PhosphorIconsRegular.phone,
                                  inputFormatters: [emergencyPhoneMask],
                                  keyboardType: TextInputType.phone,
                                  enabled: _isFieldEnabled(
                                    'Contato de Emergência',
                                  ),
                                ),
                                const SizedBox(height: 20),

                                RequestInputField(
                                  label: 'Nome do Responsável (Opcional)',
                                  controller: _responsavelNomeController,
                                  hint: 'Digite o nome do responsável',
                                  icon: PhosphorIconsRegular.users,
                                  enabled: _isFieldEnabled('Responsável'),
                                ),
                                const SizedBox(height: 20),

                                RequestInputField(
                                  label: 'Número do Responsável (Opcional)',
                                  controller: _responsavelTelefoneController,
                                  hint: '(00) 00000-0000',
                                  icon: PhosphorIconsRegular.phone,
                                  inputFormatters: [responsiblePhoneMask],
                                  keyboardType: TextInputType.phone,
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

                                // Determina se há documentos obrigatórios a reenviar
                                (() {
                                  final isReviewingRequest =
                                      widget.request != null &&
                                      (widget.request!.status ==
                                              'reviewing_data' ||
                                          widget.request!.status ==
                                              'waiting_docs');

                                  final isDocumentRequested =
                                      isReviewingRequest &&
                                      _isFieldEnabled(
                                        'Documento com Foto (RG/CNH)',
                                      );

                                  final isMedicalReportRequested =
                                      isReviewingRequest &&
                                      _isFieldEnabled('Laudo Médico');

                                  final requiredDocumentsCount = [
                                    isDocumentRequested,
                                    isMedicalReportRequested,
                                  ].where((required) => required).length;

                                  final String title;
                                  final String message;

                                  if (requiredDocumentsCount == 1) {
                                    title = 'Documento obrigatório nesta etapa';
                                    message =
                                        'Envie o documento solicitado para que a análise da carteirinha possa continuar.';
                                  } else if (requiredDocumentsCount > 1) {
                                    title =
                                        'Documentos obrigatórios nesta etapa';
                                    message =
                                        'Envie os documentos solicitados para que a análise da carteirinha possa continuar.';
                                  } else {
                                    title =
                                        'Os documentos são opcionais agora.';
                                    message =
                                        'Podemos solicitar documentação complementar durante a análise.';
                                  }

                                  return Container(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          PhosphorIconsRegular.info,
                                          color: AppColors.alertOrange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary
                                                      .withValues(alpha: 0.9),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                message,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.textPrimary
                                                      .withValues(alpha: 0.8),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })(),
                                const SizedBox(height: 20),

                                RequestDropdownField<String>(
                                  label: 'Tipo Sanguíneo (Opcional)',
                                  value: _selectedBloodType,
                                  hint: 'Selecione',
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
                                if (widget.request == null ||
                                    widget.request!.status ==
                                        'reviewing_data' ||
                                    widget.request!.status ==
                                        'waiting_docs') ...[
                                  const SizedBox(height: 12),
                                  RequestLaterButton(
                                    onPressed: _handleBackAction,
                                  ),
                                ],
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 80,
                        ), // Espaço reduzido para evitar overflow em telas menores
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
