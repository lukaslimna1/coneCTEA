import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'revisao/print_review_mandatory_section.dart';
import 'revisao/print_review_legal_section.dart';
import 'revisao/print_review_preview_box.dart';
import 'revisao/print_review_empty_warning_box.dart';
import 'revisao/print_review_option_tile.dart';
import 'revisao/print_review_extra_contacts_section.dart';

/// **PrintReviewInfoSheet**
/// Diálogo modal bottom sheet que permite ao responsável revisar
/// as informações da carteirinha comunitária e selecionar quais dados
/// opcionais e sensíveis serão incluídos na versão para impressão.
class PrintReviewInfoSheet extends StatefulWidget {
  final Member member;
  final bool includeProfile;

  const PrintReviewInfoSheet({
    super.key,
    required this.member,
    required this.includeProfile,
  });

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required Member member,
    required bool includeProfile,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintReviewInfoSheet(
          member: member,
          includeProfile: includeProfile,
        );
      },
    );
  }

  @override
  State<PrintReviewInfoSheet> createState() => _PrintReviewInfoSheetState();
}

class _PrintReviewInfoSheetState extends State<PrintReviewInfoSheet> {
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
                      // BLOCO LEGAL E POLÍTICA
                      // ==========================================
                      const PrintReviewLegalSection(),
                      const SizedBox(height: 8),
                    ],
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
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DsBotao(
                        label: 'Continuar',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.sucesso,
                        onPressed: () => Navigator.pop(context, true),
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
      ),
    );
  }

  Widget _buildResponsiblePreviewArea() {
    if (!_includeResponsible) return const SizedBox.shrink();

    final hasResponsible = widget.member.responsibleName.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 4.0, right: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasResponsible) ...[
            PrintReviewPreviewBox(
              value: widget.member.responsibleName,
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
                  ),
                  const SizedBox(height: 10),
                  CampoTelefoneResponsavel(
                    controller: _tempRespPhoneController,
                    requiredField: false,
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
                  ),
                  const SizedBox(height: 10),
                  CampoTelefoneContatoEmergencia(
                    controller: _tempEmergPhoneController,
                    requiredField: false,
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
}
