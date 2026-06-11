import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'revisao/print_review_mandatory_section.dart';
import 'revisao/print_review_legal_section.dart';
import 'revisao/print_review_preview_box.dart';
import 'revisao/print_review_empty_warning_box.dart';
import 'revisao/print_review_option_tile.dart';
import 'revisao/print_review_extra_contacts_section.dart';
import 'package:conectea/features/carteirinhas/services/print_support_profile_local_service.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_options.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_request.dart';
import 'package:conectea/features/carteirinhas/services/print_card_preferences_local_service.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_params.dart';
import 'package:conectea/features/carteirinhas/models/member_rpc_merge_extension.dart';
import 'package:conectea/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/features/carteirinhas/utils/print_contacts_helper.dart';


/// **PrintReviewInfoSheet**
/// Diálogo modal bottom sheet que permite ao responsável revisar
/// as informações da carteirinha comunitária e selecionar quais dados
/// opcionais e sensíveis serão incluídos na versão para impressão.
class PrintReviewInfoSheet extends StatefulWidget {
  final Member member;
  final DigitalCard activeCard;
  final bool includeProfile;

  const PrintReviewInfoSheet({
    super.key,
    required this.member,
    required this.activeCard,
    required this.includeProfile,
  });

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<PrintCardRequest?> show(
    BuildContext context, {
    required Member member,
    required DigitalCard activeCard,
    required bool includeProfile,
  }) {
    return showModalBottomSheet<PrintCardRequest>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintReviewInfoSheet(
          member: member,
          activeCard: activeCard,
          includeProfile: includeProfile,
        );
      },
    );
  }

  @override
  State<PrintReviewInfoSheet> createState() => _PrintReviewInfoSheetState();
}

class _PrintReviewInfoSheetState extends State<PrintReviewInfoSheet> {
  // Chave global para a validação do formulário
  final _formKey = GlobalKey<FormState>();

  // Servico local e estados do Perfil de Apoio TEA
  final _localService = PrintSupportProfileLocalService();
  final _prefsService = PrintCardPreferencesLocalService();
  PrintSupportProfileDraft? _supportProfileDraft;
  bool _isLoadingSupportProfileDraft = false;
  bool _isProcessing = false;

  // Estado local para checkboxes (Informações opcionais - todas desmarcadas por padrão)
  bool _includeBirthDate = false;
  bool _includeBloodType = false;
  bool _includePhone = false;
  bool _includeCityUf = false;
  bool _includeResponsible = false;
  bool _includeEmergency = false;
  bool _includeRacaCor = false;
  bool _includeGender = false;

  // Estado local para checkboxes (Dados sensíveis - desmarcados por padrão)
  bool _includeCid = false;
  bool _includeCpfMasked = false;

  // Estado local para contatos extras
  final List<Map<String, TextEditingController>> _extraResponsibles = [];
  final List<Map<String, TextEditingController>> _extraEmergencies = [];
  bool _showExtraResponsiblesForm = false;
  bool _showExtraEmergenciesForm = false;

  // Controllers temporários para preenchimento de campos vazios em memória
  late final TextEditingController _tempPhoneController;
  late final TextEditingController _tempCityUfController;
  late final TextEditingController _tempCidController;
  
  // Controllers do Responsável Principal cadastrável temporário
  late final TextEditingController _tempRespNameController;
  late final TextEditingController _tempRespPhoneController;

  // Controllers do Contato de Emergência Principal cadastrável temporário
  late final TextEditingController _tempEmergNameController;
  late final TextEditingController _tempEmergPhoneController;

  // Estados temporários para dropdowns
  String? _tempBloodType;
  String? _tempRacaCor;
  String? _tempGender;

  @override
  void initState() {
    super.initState();
    _tempPhoneController = TextEditingController();
    _tempCityUfController = TextEditingController();
    _tempCidController = TextEditingController();
    
    _tempRespNameController = TextEditingController();
    _tempRespPhoneController = TextEditingController();

    _tempEmergNameController = TextEditingController();
    _tempEmergPhoneController = TextEditingController();

    // Carrega o rascunho local do Perfil de Apoio se solicitado no fluxo
    if (widget.includeProfile) {
      _loadSupportProfileDraft();
    }

    // Carrega preferências de opções de impressão da última vez
    _loadPreferencesDraft();
  }

  Future<void> _loadPreferencesDraft() async {
    final prefs = await _prefsService.load(widget.member.id);
    if (prefs != null && mounted) {
      setState(() {
        _includeBirthDate = prefs.options.includeBirthDateAndAge;
        _includeBloodType = prefs.options.includeBloodType;
        _includePhone = prefs.options.includePhone;
        _includeCityUf = prefs.options.includeCityUf;
        _includeResponsible = prefs.options.includeResponsible;
        _includeEmergency = prefs.options.includeEmergencyContacts;
        _includeRacaCor = prefs.options.includeRaceColor;
        _includeGender = prefs.options.includeGender;
        _includeCid = prefs.options.includeCid;
        _includeCpfMasked = prefs.options.includeMaskedCpf;

        if (prefs.bloodTypeOverride != null) _tempBloodType = prefs.bloodTypeOverride;
        if (prefs.phoneOverride != null) _tempPhoneController.text = prefs.phoneOverride!;
        if (prefs.cityUfOverride != null) _tempCityUfController.text = prefs.cityUfOverride!;
        if (prefs.raceColorOverride != null) _tempRacaCor = prefs.raceColorOverride;
        if (prefs.genderOverride != null) _tempGender = prefs.genderOverride;
        if (prefs.cidOverride != null) _tempCidController.text = prefs.cidOverride!;

        if (prefs.responsibleNameOverride != null) _tempRespNameController.text = prefs.responsibleNameOverride!;
        if (prefs.responsiblePhoneOverride != null) _tempRespPhoneController.text = prefs.responsiblePhoneOverride!;

        if (prefs.emergencyNameOverride != null) _tempEmergNameController.text = prefs.emergencyNameOverride!;
        if (prefs.emergencyPhoneOverride != null) _tempEmergPhoneController.text = prefs.emergencyPhoneOverride!;

        if (prefs.extraResponsibles.isNotEmpty) {
          _showExtraResponsiblesForm = true;
          _extraResponsibles.clear();
          for (var item in prefs.extraResponsibles) {
            _extraResponsibles.add({
              'name': TextEditingController(text: item.name),
              'phone': TextEditingController(text: item.phone),
            });
          }
        }

        if (prefs.extraEmergencyContacts.isNotEmpty) {
          _showExtraEmergenciesForm = true;
          _extraEmergencies.clear();
          for (var item in prefs.extraEmergencyContacts) {
            _extraEmergencies.add({
              'name': TextEditingController(text: item.name),
              'phone': TextEditingController(text: item.phone),
            });
          }
        }
      });
    }
  }

  /// Carrega o rascunho de Perfil de Apoio TEA local de forma silenciosa
  Future<void> _loadSupportProfileDraft() async {
    setState(() {
      _isLoadingSupportProfileDraft = true;
    });
    try {
      final draft = await _localService.loadDraft(widget.member.id);
      if (mounted) {
        setState(() {
          _supportProfileDraft = draft;
        });
      }
    } catch (_) {
      // Captura silenciosa e segura em caso de erros de leitura
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSupportProfileDraft = false;
        });
      }
    }
  }

  void _addExtraResponsible() {
    setState(() {
      _extraResponsibles.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
      });
    });
  }

  void _removeExtraResponsible(int index) {
    setState(() {
      final item = _extraResponsibles.removeAt(index);
      item['name']?.dispose();
      item['phone']?.dispose();
    });
  }

  void _addExtraEmergency() {
    setState(() {
      _extraEmergencies.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
      });
    });
  }

  void _removeExtraEmergency(int index) {
    setState(() {
      final item = _extraEmergencies.removeAt(index);
      item['name']?.dispose();
      item['phone']?.dispose();
    });
  }

  @override
  void dispose() {
    _tempPhoneController.dispose();
    _tempCityUfController.dispose();
    _tempCidController.dispose();
    _tempRespNameController.dispose();
    _tempRespPhoneController.dispose();
    _tempEmergNameController.dispose();
    _tempEmergPhoneController.dispose();

    for (final item in _extraResponsibles) {
      item['name']?.dispose();
      item['phone']?.dispose();
    }
    for (final item in _extraEmergencies) {
      item['name']?.dispose();
      item['phone']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      decoration: BoxDecoration(
        color: DsCores.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DsRaios.card),
          topRight: Radius.circular(DsRaios.card),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alça de arraste visual (Drag Handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 20, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Área de Conteúdo Rolável
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Cabeçalho e Título
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsBold.listChecks,
                            color: DsCores.carteirinha.accent,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Revisar informações da impressão',
                              style: DsTipografia.sectionTitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Subtítulo descritivo
                      Text(
                        'Confira quais dados entram obrigatoriamente e escolha quais informações opcionais deseja incluir.',
                        style: DsTipografia.infoBody,
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // Bloco 1 — DADOS OBRIGATÓRIOS
                      // ==========================================
                      const PrintReviewMandatorySection(),
                      const SizedBox(height: 24),

                      // ==========================================
                      // Bloco 2 — INFORMAÇÕES OPCIONAIS
                      // ==========================================
                      _buildBlockHeader(
                        title: 'Você escolhe se deseja incluir',
                        description: 'Marque apenas o que for confortável e relevante para impressão.',
                      ),
                      const SizedBox(height: 12),
                      
                      // Nota conceitual de preenchimento pendente
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: DsCores.carteirinha.softBackground.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(DsRaios.card),
                            border: Border.all(
                              color: DsCores.carteirinha.border.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIconsRegular.info,
                                color: DsCores.carteirinha.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Se uma informação selecionada ainda não estiver preenchida, a próxima etapa poderá solicitar o preenchimento antes de gerar o PDF.',
                                  style: DsTipografia.caption.copyWith(
                                    color: DsCores.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DsCard(
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.35),
                        borderColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Column(
                          children: [
                            PrintReviewOptionTile(
                              title: 'Data de nascimento e idade',
                              value: _includeBirthDate,
                              onChanged: (val) => setState(() => _includeBirthDate = val ?? false),
                              child: _buildBirthDatePreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Tipo sanguíneo',
                              value: _includeBloodType,
                              onChanged: (val) => setState(() => _includeBloodType = val ?? false),
                              child: _buildBloodTypePreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Telefone da pessoa',
                              value: _includePhone,
                              onChanged: (val) => setState(() => _includePhone = val ?? false),
                              child: _buildPhonePreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Cidade / UF',
                              value: _includeCityUf,
                              onChanged: (val) => setState(() => _includeCityUf = val ?? false),
                              child: _buildCityUfPreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Responsável(is)',
                              value: _includeResponsible,
                              onChanged: (val) {
                                setState(() {
                                  _includeResponsible = val ?? false;
                                  if (!_includeResponsible) {
                                    _showExtraResponsiblesForm = false;
                                    for (final item in _extraResponsibles) {
                                      item['name']?.dispose();
                                      item['phone']?.dispose();
                                    }
                                    _extraResponsibles.clear();
                                  }
                                });
                              },
                              child: _buildResponsiblePreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Contato(s) de emergência',
                              value: _includeEmergency,
                              onChanged: (val) {
                                setState(() {
                                  _includeEmergency = val ?? false;
                                  if (!_includeEmergency) {
                                    _showExtraEmergenciesForm = false;
                                    for (final item in _extraEmergencies) {
                                      item['name']?.dispose();
                                      item['phone']?.dispose();
                                    }
                                    _extraEmergencies.clear();
                                  }
                                });
                              },
                              child: _buildEmergencyPreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Cor / raça',
                              value: _includeRacaCor,
                              onChanged: (val) => setState(() => _includeRacaCor = val ?? false),
                              child: _buildRacaCorPreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'Gênero',
                              value: _includeGender,
                              onChanged: (val) => setState(() => _includeGender = val ?? false),
                              child: _buildGenderPreviewArea(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // Bloco 3 — DADOS SENSÍVEIS
                      // ==========================================
                      _buildBlockHeader(
                        title: 'Dados sensíveis',
                        description: 'Essas informações podem expor dados pessoais ou de saúde. Marque apenas se for realmente necessário para a impressão.',
                      ),
                      const SizedBox(height: 12),
                      DsCard(
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.35),
                        borderColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Column(
                          children: [
                            PrintReviewOptionTile(
                              title: 'CPF mascarado',
                              description: 'Exibe o documento com máscara de segurança.',
                              value: _includeCpfMasked,
                              onChanged: (val) => setState(() => _includeCpfMasked = val ?? false),
                              child: _buildCpfPreviewArea(),
                            ),
                            PrintReviewOptionTile(
                              title: 'CID',
                              description: 'Exibe o Código Internacional de Doenças.',
                              value: _includeCid,
                              onChanged: (val) => setState(() => _includeCid = val ?? false),
                              child: _buildCidPreviewArea(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // Bloco 4 — PERFIL DE APOIO TEA (Condicional)
                      // ==========================================
                      if (widget.includeProfile) ...[
                        _buildSupportProfileSection(),
                        const SizedBox(height: 24),
                      ],

                      // ==========================================
                      // BLOCO LEGAL E POLÍTICA
                      // ==========================================
                      const PrintReviewLegalSection(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

              // ==========================================
              // BOTÕES DE AÇÃO FIXOS NO RODAPÉ
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DsBotao(
                        label: 'Voltar',
                        variante: DsBotaoVariante.secundario,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DsBotao(
                        label: 'Continuar',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.sucesso,
                        isLoading: _isProcessing,
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() == false) {
                                  return;
                                }

                                final bool hasNewCid = _includeCid &&
                                    widget.member.cid.trim().isEmpty &&
                                    _tempCidController.text.trim().isNotEmpty &&
                                    _tempCidController.text.trim().length <= 20;

                                final rpcRespParams = PrintContactsHelper.buildRpcParams(
                                  structuredName: widget.member.responsiblePersonName,
                                  structuredPhone: widget.member.responsiblePhone,
                                  inputName: _tempRespNameController.text,
                                  inputPhone: _tempRespPhoneController.text,
                                  isIncluded: _includeResponsible,
                                );
                                final bool hasNewResponsible = rpcRespParams['name'] != null || rpcRespParams['phone'] != null;

                                final rpcEmergParams = PrintContactsHelper.buildRpcParams(
                                  structuredName: widget.member.emergencyPersonName,
                                  structuredPhone: widget.member.emergencyPhone,
                                  inputName: _tempEmergNameController.text,
                                  inputPhone: _tempEmergPhoneController.text,
                                  isIncluded: _includeEmergency,
                                );
                                final bool hasNewEmergency = rpcEmergParams['name'] != null || rpcEmergParams['phone'] != null;

                                final bool hasNewBloodType = _includeBloodType &&
                                    widget.member.bloodType.trim().isEmpty &&
                                    _tempBloodType != null &&
                                    _tempBloodType!.trim().isNotEmpty &&
                                    _tempBloodType != 'Não sei' &&
                                    _tempBloodType != 'Prefiro não informar' &&
                                    const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(_tempBloodType);

                                final bool hasNewPhone = _includePhone &&
                                    widget.member.phone.trim().isEmpty &&
                                    _tempPhoneController.text.trim().isNotEmpty &&
                                    ValidadoresCadastrais.telefone(_tempPhoneController.text.trim()) == null;

                                final bool hasNewRacaCor = _includeRacaCor &&
                                    (widget.member.racaCor == null || widget.member.racaCor!.trim().isEmpty) &&
                                    _tempRacaCor != null &&
                                    _tempRacaCor!.trim().isNotEmpty &&
                                    OpcoesCadastrais.racaCor.contains(_tempRacaCor);

                                final bool hasNewGender = _includeGender &&
                                    (widget.member.gender == null || widget.member.gender!.trim().isEmpty) &&
                                    _tempGender != null &&
                                    _tempGender!.trim().isNotEmpty &&
                                    OpcoesCadastrais.genero.contains(_tempGender);

                                final bool hasAnyNewField = hasNewBloodType ||
                                    hasNewPhone ||
                                    hasNewRacaCor ||
                                    hasNewGender ||
                                    hasNewCid ||
                                    hasNewResponsible ||
                                    hasNewEmergency;

                                Member currentMember = widget.member;

                                if (hasAnyNewField) {
                                  setState(() {
                                    _isProcessing = true;
                                  });

                                  try {
                                    final dbService = DatabaseService();
                                    final params = FillEmptyMemberOptionalFieldsParams(
                                      memberId: widget.member.id,
                                      bloodType: hasNewBloodType ? _tempBloodType : null,
                                      phone: hasNewPhone ? _tempPhoneController.text.trim() : null,
                                      racaCor: hasNewRacaCor ? _tempRacaCor : null,
                                      gender: hasNewGender ? _tempGender : null,
                                      cid: hasNewCid ? _tempCidController.text.trim() : null,
                                      responsiblePersonName: rpcRespParams['name'],
                                      responsiblePhone: rpcRespParams['phone'],
                                      emergencyPersonName: rpcEmergParams['name'],
                                      emergencyPhone: rpcEmergParams['phone'],
                                    );

                                    final result = await dbService.fillEmptyMemberOptionalFields(params);
                                    currentMember = currentMember.mergeRpcResult(result);

                                    if (result.preservedFields.isNotEmpty) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Algumas informações já estavam atualizadas no cadastro e foram preservadas.'),
                                        ),
                                      );
                                    }
                                  } on PostgrestException catch (e) {
                                    if (!context.mounted) return;
                                    _handleError(e, context);
                                    return;
                                  } on FormatException catch (e) {
                                    if (!context.mounted) return;
                                    _handleError(e, context);
                                    return;
                                  } on StateError catch (e) {
                                    if (!context.mounted) return;
                                    _handleError(e, context);
                                    return;
                                  } on ArgumentError catch (e) {
                                    if (!context.mounted) return;
                                    _handleError(e, context);
                                    return;
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    _handleError(e, context);
                                    return;
                                  }
                                }

                                final request = _buildRequestFromState(currentMember);

                                final preferencesOptions = PrintCardOptions(
                                  includeBirthDateAndAge: _includeBirthDate,
                                  includeMaskedCpf: _includeCpfMasked,
                                  includeBloodType: _includeBloodType,
                                  includeCid: _includeCid,
                                  includePhone: _includePhone,
                                  includeCityUf: _includeCityUf,
                                  includeResponsible: _includeResponsible,
                                  includeEmergencyContacts: _includeEmergency,
                                  includeRaceColor: _includeRacaCor,
                                  includeGender: _includeGender,
                                  includeProfile: widget.includeProfile,
                                );

                                // Verifica se há algo marcado para salvar nas preferências
                                final hasAnyOptionSelected = preferencesOptions.includeBirthDateAndAge ||
                                    preferencesOptions.includeMaskedCpf ||
                                    preferencesOptions.includeBloodType ||
                                    preferencesOptions.includeCid ||
                                    preferencesOptions.includePhone ||
                                    preferencesOptions.includeCityUf ||
                                    preferencesOptions.includeResponsible ||
                                    preferencesOptions.includeEmergencyContacts ||
                                    preferencesOptions.includeRaceColor ||
                                    preferencesOptions.includeGender;

                                final hasOverridesOrExtras = request.bloodTypeOverride != null ||
                                    request.phoneOverride != null ||
                                    request.cityUfOverride != null ||
                                    request.raceColorOverride != null ||
                                    request.genderOverride != null ||
                                    request.cidOverride != null ||
                                    request.responsibleNameOverride != null ||
                                    request.responsiblePhoneOverride != null ||
                                    request.emergencyNameOverride != null ||
                                    request.emergencyPhoneOverride != null ||
                                    request.extraResponsibles.isNotEmpty ||
                                    request.extraEmergencyContacts.isNotEmpty;

                                if (hasAnyOptionSelected || hasOverridesOrExtras) {
                                  final draft = PrintCardPreferencesDraft(
                                    options: preferencesOptions,
                                    extraResponsibles: request.extraResponsibles,
                                    extraEmergencyContacts: request.extraEmergencyContacts,
                                    bloodTypeOverride: request.bloodTypeOverride,
                                    phoneOverride: request.phoneOverride,
                                    cityUfOverride: request.cityUfOverride,
                                    raceColorOverride: request.raceColorOverride,
                                    genderOverride: request.genderOverride,
                                    cidOverride: request.cidOverride,
                                    responsibleNameOverride: request.responsibleNameOverride,
                                    responsiblePhoneOverride: request.responsiblePhoneOverride,
                                    emergencyNameOverride: request.emergencyNameOverride,
                                    emergencyPhoneOverride: request.emergencyPhoneOverride,
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  await _prefsService.save(widget.member.id, draft);
                                } else {
                                  // Se tudo estiver vazio/padrão, apaga as preferências antigas
                                  await _prefsService.delete(widget.member.id);
                                }

                                if (!context.mounted) return;
                                setState(() {
                                  _isProcessing = false;
                                });
                                Navigator.pop(context, request);
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockHeader({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DsTipografia.cardTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: DsTipografia.caption.copyWith(
            color: DsCores.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }


  Widget _buildBirthDatePreviewArea() {
    if (!_includeBirthDate) return const SizedBox.shrink();

    final hasValue = widget.member.dateOfBirth.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: _getBirthDatePreview(),
      );
    }

    return const PrintReviewEmptyWarningBox(
      message: 'Data de nascimento não preenchida.',
      helperText: 'Preencha no seu cadastro futuramente para incluir na versão impressa.',
      isContainer: true,
    );
  }

  Widget _buildBloodTypePreviewArea() {
    if (!_includeBloodType) return const SizedBox.shrink();

    final hasValue = widget.member.bloodType.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: widget.member.bloodType,
      );
    }

    return PrintReviewEmptyWarningBox(
      message: 'Informação não preenchida. Preencha para incluir na versão impressa.',
      child: CampoTipoSanguineo(
        value: _tempBloodType,
        requiredField: false,
        onChanged: (val) {
          setState(() {
            _tempBloodType = val;
          });
        },
      ),
    );
  }

  Widget _buildPhonePreviewArea() {
    if (!_includePhone) return const SizedBox.shrink();

    final hasValue = widget.member.phone.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: widget.member.phone,
      );
    }

    return PrintReviewEmptyWarningBox(
      message: 'Informação não preenchida. Preencha para incluir na versão impressa.',
      child: CampoTelefone(
        controller: _tempPhoneController,
        requiredField: false,
      ),
    );
  }

  Widget _buildCityUfPreviewArea() {
    if (!_includeCityUf) return const SizedBox.shrink();

    final hasValue = widget.member.city.isNotEmpty && widget.member.state.isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: '${widget.member.city} / ${widget.member.state}',
      );
    }

    return PrintReviewEmptyWarningBox(
      message: 'Informação não preenchida. Preencha para incluir na versão impressa.',
      child: DsInput(
        label: 'Cidade / UF (Opcional)',
        controller: _tempCityUfController,
        hint: 'Ex: Bauru / SP',
        icon: PhosphorIconsRegular.mapPin,
      ),
    );
  }

  Widget _buildRacaCorPreviewArea() {
    if (!_includeRacaCor) return const SizedBox.shrink();

    final hasValue = widget.member.racaCor != null && widget.member.racaCor!.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: widget.member.racaCor!,
      );
    }

    return PrintReviewEmptyWarningBox(
      message: 'Informação não preenchida. Preencha para incluir na versão impressa.',
      child: CampoRacaCor(
        value: _tempRacaCor,
        requiredField: false,
        onChanged: (val) {
          setState(() {
            _tempRacaCor = val;
          });
        },
      ),
    );
  }

  Widget _buildGenderPreviewArea() {
    if (!_includeGender) return const SizedBox.shrink();

    final hasValue = widget.member.gender != null && widget.member.gender!.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: widget.member.gender!,
      );
    }

    return PrintReviewEmptyWarningBox(
      message: 'Informação não preenchida. Preencha para incluir na versão impressa.',
      child: CampoGenero(
        value: _tempGender,
        requiredField: false,
        onChanged: (val) {
          setState(() {
            _tempGender = val;
          });
        },
      ),
    );
  }

  Widget _buildCpfPreviewArea() {
    if (!_includeCpfMasked) return const SizedBox.shrink();

    final hasValue = widget.member.cpf.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: _getCpfMasked(),
      );
    }

    return const PrintReviewEmptyWarningBox(
      message: 'CPF não preenchido.',
      helperText: 'O CPF é um dado pessoal sensível e não pode ser preenchido localmente por segurança.',
      isContainer: true,
    );
  }
  String? _validateRespName(String? value) {
    return PrintContactsHelper.validateName(value, isIncluded: _includeResponsible, structuredName: widget.member.responsiblePersonName);
  }

  String? _validateRespPhone(String? value) {
    return PrintContactsHelper.validatePhone(value, isIncluded: _includeResponsible, structuredPhone: widget.member.responsiblePhone);
  }

  String? _validateEmergName(String? value) {
    return PrintContactsHelper.validateName(value, isIncluded: _includeEmergency, structuredName: widget.member.emergencyPersonName);
  }

  String? _validateEmergPhone(String? value) {
    return PrintContactsHelper.validatePhone(value, isIncluded: _includeEmergency, structuredPhone: widget.member.emergencyPhone);
  }

  String? _validateCid(String? value) {
    if (!_includeCid || widget.member.cid.trim().isNotEmpty) {
      return null;
    }
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Informe o CID para incluir na impressão.';
    }
    if (trimmed.length > 20) {
      return 'Digite apenas o código do CID, com até 20 caracteres.';
    }
    return null;
  }

  Widget _buildCidPreviewArea() {
    if (!_includeCid) return const SizedBox.shrink();

    final hasValue = widget.member.cid.trim().isNotEmpty;
    if (hasValue) {
      return PrintReviewPreviewBox(
        value: widget.member.cid,
      );
    }

    return PrintReviewEmptyWarningBox(
      message: 'Informação não preenchida. Preencha para incluir na versão impressa.',
      child: CampoCid(
        controller: _tempCidController,
        requiredField: false,
        validator: _validateCid,
      ),
    );
  }

  Widget _buildResponsiblePreviewArea() {
    if (!_includeResponsible) return const SizedBox.shrink();

    final state = PrintContactsHelper.getUiState(
      structuredName: widget.member.responsiblePersonName,
      structuredPhone: widget.member.responsiblePhone,
      legacyComposed: widget.member.responsibleName,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 4.0, right: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.uiState == PrintContactUiState.bothLocked) ...[
            PrintReviewPreviewBox(
              value: widget.member.effectiveResponsiblePersonName,
            ),
            const SizedBox(height: 8),
            PrintReviewPreviewBox(
              value: widget.member.effectiveResponsiblePhone,
            ),
          ] else if (state.uiState == PrintContactUiState.nameLockedPhoneEditable) ...[
            PrintReviewPreviewBox(
              value: widget.member.effectiveResponsiblePersonName,
            ),
            const SizedBox(height: 12),
            PrintReviewEmptyWarningBox(
              message: 'Telefone não preenchido.',
              child: CampoTelefoneResponsavel(
                controller: _tempRespPhoneController,
                requiredField: false,
                validator: _validateRespPhone,
              ),
            ),
          ] else if (state.uiState == PrintContactUiState.legacyLocked) ...[
            PrintReviewPreviewBox(
              value: widget.member.responsibleLegacyDisplayValue,
            ),
          ] else ...[
            PrintReviewEmptyWarningBox(
              message: 'Responsável não preenchido. Preencha para incluir na versão impressa.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CampoNomeResponsavel(
                    controller: _tempRespNameController,
                    requiredField: false,
                    validator: _validateRespName,
                  ),
                  const SizedBox(height: 10),
                  CampoTelefoneResponsavel(
                    controller: _tempRespPhoneController,
                    requiredField: false,
                    validator: _validateRespPhone,
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          if (!_showExtraResponsiblesForm) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deseja incluir outro responsável?',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DsBotao(
                  label: 'Adicionar outro',
                  variante: DsBotaoVariante.acao,
                  token: DsCores.sucesso,
                  icon: Icons.add_rounded,
                  fullWidth: false,
                  onPressed: () {
                    setState(() {
                      _showExtraResponsiblesForm = true;
                      if (_extraResponsibles.isEmpty) {
                        _addExtraResponsible();
                      }
                    });
                  },
                ),
              ],
            ),
          ] else ...[
            PrintReviewExtraContactsSection(
              title: 'Outros responsáveis',
              supportText: 'Contatos adicionais não alteram o cadastro.',
              contacts: _extraResponsibles,
              onAdd: _addExtraResponsible,
              onRemove: (idx) {
                _removeExtraResponsible(idx);
                if (_extraResponsibles.isEmpty) {
                  setState(() {
                    _showExtraResponsiblesForm = false;
                  });
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyPreviewArea() {
    if (!_includeEmergency) return const SizedBox.shrink();

    final hasEmergency = widget.member.emergencyContact.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 4.0, right: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasEmergency) ...[
            PrintReviewPreviewBox(
              value: widget.member.emergencyContact,
              icon: Icons.phone_enabled_rounded,
            ),
          ] else ...[
            PrintReviewEmptyWarningBox(
              message: 'Contato de emergência não preenchido. Preencha para incluir na versão impressa.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CampoNomeContatoEmergencia(
                    controller: _tempEmergNameController,
                    requiredField: false,
                    validator: _validateEmergName,
                  ),
                  const SizedBox(height: 10),
                  CampoTelefoneContatoEmergencia(
                    controller: _tempEmergPhoneController,
                    requiredField: false,
                    validator: _validateEmergPhone,
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          if (!_showExtraEmergenciesForm) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deseja incluir outro contato?',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DsBotao(
                  label: 'Adicionar outro',
                  variante: DsBotaoVariante.acao,
                  token: DsCores.sucesso,
                  icon: Icons.add_rounded,
                  fullWidth: false,
                  onPressed: () {
                    setState(() {
                      _showExtraEmergenciesForm = true;
                      if (_extraEmergencies.isEmpty) {
                        _addExtraEmergency();
                      }
                    });
                  },
                ),
              ],
            ),
          ] else ...[
            PrintReviewExtraContactsSection(
              title: 'Outros contatos',
              supportText: 'Use apenas contatos que façam sentido para a versão impressa.',
              contacts: _extraEmergencies,
              onAdd: _addExtraEmergency,
              onRemove: (idx) {
                _removeExtraEmergency(idx);
                if (_extraEmergencies.isEmpty) {
                  setState(() {
                    _showExtraEmergenciesForm = false;
                  });
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  String _getBirthDatePreview() {
    final dob = widget.member.dateOfBirth.trim();
    if (dob.isEmpty) return '';
    try {
      DateTime? dt;
      if (dob.contains('/')) {
        final parts = dob.split('/');
        if (parts.length == 3) {
          dt = DateTime.parse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
        }
      } else if (dob.contains('-')) {
        dt = DateTime.parse(dob);
      }
      if (dt != null) {
        final today = DateTime.now();
        int age = today.year - dt.year;
        if (today.month < dt.month || (today.month == dt.month && today.day < dt.day)) {
          age--;
        }
        final formattedDate = dob.contains('/') ? dob : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        return '$formattedDate · $age anos';
      }
    } catch (_) {}
    return dob;
  }

  String _getCpfMasked() {
    final cpf = widget.member.cpf.trim();
    if (cpf.isEmpty) return '';
    final clean = cpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.***.***-${clean.substring(9, 11)}';
    }
    return 'CPF mascarado será exibido na impressão.';
  }

  void _handleError(Object error, BuildContext context) {
    if (!context.mounted) return;
    setState(() {
      _isProcessing = false;
    });

    final String message;
    if (error is PostgrestException) {
      message = 'Não foi possível atualizar as informações agora. Tente novamente.';
    } else if (error is FormatException || error is StateError || error is ArgumentError) {
      if (kDebugMode) {
        print('Falha interna ao consolidar informações opcionais.');
      }
      message = 'Não foi possível concluir esta operação agora. Tente novamente.';
    } else {
      if (kDebugMode) {
        print('Falha interna ao consolidar informações opcionais.');
      }
      message = 'Não foi possível concluir esta operação agora. Tente novamente.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  /// Constrói o objeto de requisição da impressão contendo todas as escolhas
  /// de dados opcionais, dados sensíveis, contatos extras e overrides do formulário.
  PrintCardRequest _buildRequestFromState(Member member) {
    // Filtrar e converter contatos extras desconsiderando os que estão totalmente em branco
    final List<PrintContactInfo> cleanResponsibles = [];
    for (final item in _extraResponsibles) {
      final name = item['name']?.text.trim() ?? '';
      final phone = item['phone']?.text.trim() ?? '';
      if (name.isNotEmpty || phone.isNotEmpty) {
        cleanResponsibles.add(PrintContactInfo(name: name, phone: phone));
      }
    }

    final List<PrintContactInfo> cleanEmergencies = [];
    for (final item in _extraEmergencies) {
      final name = item['name']?.text.trim() ?? '';
      final phone = item['phone']?.text.trim() ?? '';
      if (name.isNotEmpty || phone.isNotEmpty) {
        cleanEmergencies.add(PrintContactInfo(name: name, phone: phone));
      }
    }

    // Coletar overrides temporários informados na Bottom Sheet de revisão
    // REGRA DA TAREFA 3: Não passar 'Prefiro não informar' ou 'Não sei' como overrides, e desativar flags correspondentes.

    // 1. Tipo Sanguíneo
    String? bloodTypeOverride;
    bool includeBloodType = _includeBloodType;
    final finalBloodType = member.bloodType.isNotEmpty ? member.bloodType : (_tempBloodType ?? '');
    if (finalBloodType == 'Não sei' || finalBloodType == 'Prefiro não informar' || finalBloodType.trim().isEmpty) {
      includeBloodType = false;
    } else if (member.bloodType.trim().isEmpty) {
      bloodTypeOverride = _tempBloodType?.trim();
    }

    // 2. Telefone
    String? phoneOverride;
    if (_includePhone && member.phone.trim().isEmpty) {
      phoneOverride = _tempPhoneController.text.trim();
    }

    // 3. Cidade / UF
    String? cityUfOverride;
    if (_includeCityUf && (member.city.trim().isEmpty || member.state.trim().isEmpty)) {
      cityUfOverride = _tempCityUfController.text.trim();
    }

    // 4. Raça / Cor
    String? raceColorOverride;
    bool includeRaceColor = _includeRacaCor;
    final finalRacaCor = (member.racaCor != null && member.racaCor!.isNotEmpty) ? member.racaCor! : (_tempRacaCor ?? '');
    if (finalRacaCor == 'Prefiro não informar' || finalRacaCor.trim().isEmpty) {
      includeRaceColor = false;
    } else if (member.racaCor == null || member.racaCor!.trim().isEmpty) {
      raceColorOverride = _tempRacaCor?.trim();
    }

    // 5. Gênero
    String? genderOverride;
    bool includeGender = _includeGender;
    final finalGender = (member.gender != null && member.gender!.isNotEmpty) ? member.gender! : (_tempGender ?? '');
    if (finalGender == 'Prefiro não informar' || finalGender.trim().isEmpty) {
      includeGender = false;
    } else if (member.gender == null || member.gender!.trim().isEmpty) {
      genderOverride = _tempGender?.trim();
    }

    String? cidOverride;
    if (_includeCid && member.cid.trim().isEmpty) {
      cidOverride = _tempCidController.text.trim();
    }

    String? responsibleNameOverride;
    String? responsiblePhoneOverride;
    if (_includeResponsible && member.responsibleName.trim().isEmpty) {
      responsibleNameOverride = _tempRespNameController.text.trim();
      responsiblePhoneOverride = _tempRespPhoneController.text.trim();
    }

    String? emergencyNameOverride;
    String? emergencyPhoneOverride;
    if (_includeEmergency && member.emergencyContact.trim().isEmpty) {
      emergencyNameOverride = _tempEmergNameController.text.trim();
      emergencyPhoneOverride = _tempEmergPhoneController.text.trim();
    }

    final options = PrintCardOptions(
      includeBirthDateAndAge: _includeBirthDate,
      includeMaskedCpf: _includeCpfMasked,
      includeBloodType: includeBloodType,
      includeCid: _includeCid,
      includePhone: _includePhone,
      includeCityUf: _includeCityUf,
      includeResponsible: _includeResponsible,
      includeEmergencyContacts: _includeEmergency,
      includeRaceColor: includeRaceColor,
      includeGender: includeGender,
      includeProfile: widget.includeProfile,
    );

    return PrintCardRequest(
      member: member,
      activeCard: widget.activeCard,
      options: options,
      includeProfile: widget.includeProfile,
      extraResponsibles: cleanResponsibles,
      extraEmergencyContacts: cleanEmergencies,
      bloodTypeOverride: bloodTypeOverride?.isNotEmpty == true ? bloodTypeOverride : null,
      phoneOverride: phoneOverride?.isNotEmpty == true ? phoneOverride : null,
      cityUfOverride: cityUfOverride?.isNotEmpty == true ? cityUfOverride : null,
      raceColorOverride: raceColorOverride?.isNotEmpty == true ? raceColorOverride : null,
      genderOverride: genderOverride?.isNotEmpty == true ? genderOverride : null,
      cidOverride: cidOverride?.isNotEmpty == true ? cidOverride : null,
      responsibleNameOverride: responsibleNameOverride?.isNotEmpty == true ? responsibleNameOverride : null,
      responsiblePhoneOverride: responsiblePhoneOverride?.isNotEmpty == true ? responsiblePhoneOverride : null,
      emergencyNameOverride: emergencyNameOverride?.isNotEmpty == true ? emergencyNameOverride : null,
      emergencyPhoneOverride: emergencyPhoneOverride?.isNotEmpty == true ? emergencyPhoneOverride : null,
    );
  }

  /// Constrói a seção visual informativa do Perfil de Apoio TEA
  Widget _buildSupportProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBlockHeader(
          title: 'Perfil de Apoio TEA',
          description: 'Essas informações ficam salvas apenas neste aparelho e ajudam a preparar a versão impressa com mais contexto.',
        ),
        const SizedBox(height: 12),
        DsCard(
          backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.35),
          borderColor: Colors.white.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(16.0),
          child: Builder(
            builder: (context) {
              if (_isLoadingSupportProfileDraft) {
                return Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: DsCores.carteirinha.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Verificando rascunho local...',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                  ],
                );
              }

              final draft = _supportProfileDraft;
              final hasContent = draft != null && draft.hasAnyContent;

              if (hasContent) {
                final preenchidos = <String>[];
                if (draft.includePreferredName && draft.preferredName.trim().isNotEmpty) preenchidos.add('nome preferido');
                if (draft.includeAbout && draft.about.trim().isNotEmpty) preenchidos.add('sobre mim');
                if (draft.includeCommunication && (draft.commSpeech ||
                    draft.commGestures ||
                    draft.commPictograms ||
                    draft.commApps ||
                    draft.communicationNotes.trim().isNotEmpty)) {
                  preenchidos.add('comunicação');
                }
                if (draft.includeLikes && draft.likes.any((e) => e.trim().isNotEmpty)) {
                  preenchidos.add('preferências');
                }
                if (draft.includeIrritations && draft.irritations.any((e) => e.trim().isNotEmpty)) {
                  preenchidos.add('irritações');
                }
                if (draft.includeCuriosities && draft.abilities.any((e) => e.trim().isNotEmpty)) {
                  preenchidos.add('curiosidades');
                }
                if (draft.includeSupportTips && draft.supportTips.any((e) => e.trim().isNotEmpty)) {
                  preenchidos.add('dicas de apoio');
                }
                if (draft.includeSupportLevel && draft.supportLevel.trim().isNotEmpty) {
                  preenchidos.add('nível de suporte');
                }
                if ((draft.includeFoodLikes && draft.foodLikes.any((e) => e.trim().isNotEmpty)) ||
                    (draft.includeFoodDislikes && draft.foodDislikes.any((e) => e.trim().isNotEmpty))) {
                  preenchidos.add('alimentação');
                }
                if (draft.includeMedications && draft.medications.any((e) => e.trim().isNotEmpty)) {
                  preenchidos.add('medicações');
                }
                if (draft.includeAllergies && draft.allergies.any((e) => e.trim().isNotEmpty)) {
                  preenchidos.add('alergias');
                }
                if (draft.includeOtherImportantInfo && draft.otherImportantInfo.trim().isNotEmpty) {
                  preenchidos.add('outras informações');
                }

                final String resumoSecoes = preenchidos.isNotEmpty
                    ? 'Seções preenchidas: ${preenchidos.join(", ")}.'
                    : 'Nenhuma seção preenchida.';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Perfil de Apoio preenchido neste aparelho.',
                            style: DsTipografia.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DsCores.sucesso.accent,
                            ),
                          ),
                        ),
                        DsSelo.fromCorVisual(
                          label: 'Local no aparelho',
                          token: DsCores.privacidade,
                          compact: true,
                        ),
                      ],
                    ),
                    if (draft.preferredName.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Como gosta de ser chamado(a): ${draft.preferredName}',
                        style: DsTipografia.bodySmall.copyWith(
                          color: DsCores.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      resumoSecoes,
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dados locais, não enviados ao banco.',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              }

              // Caso sem rascunho ou vazio
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhum Perfil de Apoio preenchido ainda.',
                    style: DsTipografia.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DsCores.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Você poderá preencher essas informações opcionais na próxima etapa.',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dados locais, não enviados ao banco.',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
