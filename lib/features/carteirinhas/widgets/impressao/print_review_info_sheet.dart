import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';


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
                      _buildBlockHeader(
                        title: 'Entram sempre',
                        description: 'Essas informações fazem parte da identificação comunitária e não podem ser removidas.',
                      ),
                      const SizedBox(height: 12),
                      DsCard(
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.35),
                        borderColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBulletItem('Nome completo ou nome social'),
                            const SizedBox(height: 10),
                            _buildBulletItem('TEA-ID'),
                            const SizedBox(height: 10),
                            _buildBulletItem('Validade'),
                            const SizedBox(height: 10),
                            _buildBulletItem('QR Code'),
                            const SizedBox(height: 10),
                            _buildBulletItem('Logos ConeCTEA e Família TEA Bauru'),
                            const SizedBox(height: 10),
                            _buildBulletItem(
                              'Aviso legal da carteirinha comunitária',
                              isImportant: true,
                            ),
                          ],
                        ),
                      ),
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

                            DsCheckbox(
                              value: _includeBirthDate,
                              onChanged: (val) => setState(() => _includeBirthDate = val ?? false),
                              label: _buildCheckboxLabel('Data de nascimento e idade'),
                              token: DsCores.sucesso,
                            ),
                            _buildBirthDatePreviewArea(),
                            DsCheckbox(
                              value: _includeBloodType,
                              onChanged: (val) => setState(() => _includeBloodType = val ?? false),
                              label: _buildCheckboxLabel('Tipo sanguíneo'),
                              token: DsCores.sucesso,
                            ),
                            _buildBloodTypePreviewArea(),
                            DsCheckbox(
                              value: _includePhone,
                              onChanged: (val) => setState(() => _includePhone = val ?? false),
                              label: _buildCheckboxLabel('Telefone da pessoa'),
                              token: DsCores.sucesso,
                            ),
                            _buildPhonePreviewArea(),
                            DsCheckbox(
                              value: _includeCityUf,
                              onChanged: (val) => setState(() => _includeCityUf = val ?? false),
                              label: _buildCheckboxLabel('Cidade / UF'),
                              token: DsCores.sucesso,
                            ),
                            _buildCityUfPreviewArea(),
                            DsCheckbox(
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
                              label: _buildCheckboxLabel('Responsável(is)'),
                              token: DsCores.sucesso,
                            ),
                            _buildResponsiblePreviewArea(),
                            DsCheckbox(
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
                              label: _buildCheckboxLabel('Contato(s) de emergência'),
                              token: DsCores.sucesso,
                            ),
                            _buildEmergencyPreviewArea(),
                            DsCheckbox(
                              value: _includeRacaCor,
                              onChanged: (val) => setState(() => _includeRacaCor = val ?? false),
                              label: _buildCheckboxLabel('Cor / raça'),
                              token: DsCores.sucesso,
                            ),
                            _buildRacaCorPreviewArea(),
                            DsCheckbox(
                              value: _includeGender,
                              onChanged: (val) => setState(() => _includeGender = val ?? false),
                              label: _buildCheckboxLabel('Gênero'),
                              token: DsCores.sucesso,
                            ),
                            _buildGenderPreviewArea(),
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
                            DsCheckbox(
                              value: _includeCpfMasked,
                              onChanged: (val) => setState(() => _includeCpfMasked = val ?? false),
                              label: _buildCheckboxLabel('CPF mascarado'),
                              description: 'Exibe o documento com máscara de segurança.',
                              token: DsCores.sucesso,
                            ),
                            _buildCpfPreviewArea(),
                            DsCheckbox(
                              value: _includeCid,
                              onChanged: (val) => setState(() => _includeCid = val ?? false),
                              label: _buildCheckboxLabel('CID'),
                              description: 'Exibe o Código Internacional de Doenças.',
                              token: DsCores.sucesso,
                            ),
                            _buildCidPreviewArea(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // BLOCO LEGAL E POLÍTICA
                      // ==========================================
                      DsCard(
                        backgroundColor: DsCores.privacidade.softBackground.withValues(alpha: 0.06),
                        borderColor: DsCores.privacidade.border.withValues(alpha: 0.15),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.shieldCheck,
                                  color: DsCores.privacidade.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                                        style: DsTipografia.caption.copyWith(
                                          color: DsCores.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'O PDF será gerado no aparelho. Ao imprimir ou compartilhar, a responsabilidade sobre o uso das informações é do usuário titular, da família ou do responsável.',
                                        style: DsTipografia.caption.copyWith(
                                          color: DsCores.textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildBulletItem(String text, {bool isImportant = false}) {
    final Color bulletColor = isImportant ? DsCores.alerta.accent : DsCores.carteirinha.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pequeno círculo visual customizado com brilho luminoso sutil
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bulletColor,
            boxShadow: [
              BoxShadow(
                color: bulletColor.withValues(alpha: 0.35),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
              fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxLabel(String text) {
    return Text(
      text,
      style: DsTipografia.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildExtraContactsSection({
    required String title,
    required String supportText,
    required List<Map<String, TextEditingController>> list,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 24,
          thickness: 1,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DsTipografia.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DsCores.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supportText,
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: DsCores.sucesso.accent,
                size: 22,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              tooltip: 'Adicionar outro',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.03),
              height: 1,
              thickness: 1,
            ),
          ),
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Outro contato #${index + 1}',
                        style: DsTipografia.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DsCores.textSecondary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemove(index),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: DsCores.perigo.accent,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        tooltip: 'Remover',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DsInput(
                    label: 'Nome completo',
                    controller: list[index]['name'],
                    hint: 'Ex: Maria Silva (Mãe)',
                  ),
                  const SizedBox(height: 8),
                  DsInput(
                    label: 'Telefone',
                    controller: list[index]['phone'],
                    hint: 'Ex: (14) 99999-9999',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyWarningArea({
    required String labelIfEmpty,
    required Widget childField,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 4.0, right: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: DsCores.alerta.accent,
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informação não preenchida. Preencha para incluir na versão impressa.',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          childField,
        ],
      ),
    );
  }

  Widget _buildPreviewArea({
    required bool isVisible,
    required String value,
    required String labelIfEmpty,
    String? customPreviewValue,
  }) {
    if (!isVisible) return const SizedBox.shrink();

    final hasValue = value.trim().isNotEmpty;
    final displayValue = customPreviewValue ?? value;

    if (!hasValue) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6.0, bottom: 12.0, left: 4.0, right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: DsCores.carteirinha.softBackground.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DsRaios.card - 2),
        border: Border.all(
          color: DsCores.carteirinha.border.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: DsCores.carteirinha.accent,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Será impresso:',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: DsTipografia.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDatePreviewArea() {
    if (!_includeBirthDate) return const SizedBox.shrink();

    final hasValue = widget.member.dateOfBirth.trim().isNotEmpty;
    if (hasValue) {
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.dateOfBirth,
        customPreviewValue: _getBirthDatePreview(),
        labelIfEmpty: '',
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6.0, bottom: 12.0, left: 4.0, right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: DsCores.alerta.softBackground.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(DsRaios.card - 2),
        border: Border.all(
          color: DsCores.alerta.border.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: DsCores.alerta.accent,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data de nascimento não preenchida.',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.alerta.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Preencha no seu cadastro futuramente para incluir na versão impressa.',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypePreviewArea() {
    if (!_includeBloodType) return const SizedBox.shrink();

    final hasValue = widget.member.bloodType.trim().isNotEmpty;
    if (hasValue) {
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.bloodType,
        labelIfEmpty: '',
      );
    }

    return _buildEmptyWarningArea(
      labelIfEmpty: 'Tipo sanguíneo não preenchido.',
      childField: CampoTipoSanguineo(
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
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.phone,
        labelIfEmpty: '',
      );
    }

    return _buildEmptyWarningArea(
      labelIfEmpty: 'Telefone da pessoa não preenchido.',
      childField: CampoTelefone(
        controller: _tempPhoneController,
        requiredField: false,
      ),
    );
  }

  Widget _buildCityUfPreviewArea() {
    if (!_includeCityUf) return const SizedBox.shrink();

    final hasValue = widget.member.city.isNotEmpty && widget.member.state.isNotEmpty;
    if (hasValue) {
      return _buildPreviewArea(
        isVisible: true,
        value: '${widget.member.city} / ${widget.member.state}',
        labelIfEmpty: '',
      );
    }

    return _buildEmptyWarningArea(
      labelIfEmpty: 'Cidade ou UF não preenchida.',
      childField: DsInput(
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
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.racaCor!,
        labelIfEmpty: '',
      );
    }

    return _buildEmptyWarningArea(
      labelIfEmpty: 'Cor / raça não preenchida.',
      childField: CampoRacaCor(
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
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.gender!,
        labelIfEmpty: '',
      );
    }

    return _buildEmptyWarningArea(
      labelIfEmpty: 'Gênero não preenchido.',
      childField: CampoGenero(
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
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.cpf,
        customPreviewValue: _getCpfMasked(),
        labelIfEmpty: '',
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6.0, bottom: 12.0, left: 4.0, right: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: DsCores.alerta.softBackground.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(DsRaios.card - 2),
        border: Border.all(
          color: DsCores.alerta.border.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: DsCores.alerta.accent,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CPF não preenchido.',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.alerta.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'O CPF é um dado pessoal sensível e não pode ser preenchido localmente por segurança.',
                  style: DsTipografia.caption.copyWith(
                    color: DsCores.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCidPreviewArea() {
    if (!_includeCid) return const SizedBox.shrink();

    final hasValue = widget.member.cid.trim().isNotEmpty;
    if (hasValue) {
      return _buildPreviewArea(
        isVisible: true,
        value: widget.member.cid,
        labelIfEmpty: '',
      );
    }

    return _buildEmptyWarningArea(
      labelIfEmpty: 'CID não preenchido.',
      childField: CampoCid(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: DsCores.carteirinha.softBackground.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(DsRaios.card - 2),
                border: Border.all(
                  color: DsCores.carteirinha.border.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: DsCores.carteirinha.accent,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Será impresso:',
                          style: DsTipografia.caption.copyWith(
                            color: DsCores.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.member.responsibleName,
                          style: DsTipografia.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: DsCores.alerta.accent,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Responsável não preenchido. Preencha para incluir na versão impressa.',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            _buildExtraContactsSection(
              title: 'Outros responsáveis',
              supportText: 'Contatos adicionais não alteram o cadastro.',
              list: _extraResponsibles,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: DsCores.carteirinha.softBackground.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(DsRaios.card - 2),
                border: Border.all(
                  color: DsCores.carteirinha.border.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.phone_enabled_rounded,
                    color: DsCores.carteirinha.accent,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Será impresso:',
                          style: DsTipografia.caption.copyWith(
                            color: DsCores.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.member.emergencyContact,
                          style: DsTipografia.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: DsCores.alerta.accent,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contato de emergência não preenchido. Preencha para incluir na versão impressa.',
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            _buildExtraContactsSection(
              title: 'Outros contatos',
              supportText: 'Use apenas contatos que façam sentido para a versão impressa.',
              list: _extraEmergencies,
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
