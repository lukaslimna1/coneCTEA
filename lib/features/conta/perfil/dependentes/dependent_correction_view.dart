import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/services/database_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual de solicitação de correção de dados do dependente.
///
/// Exibe dados reais. Ainda não conecta com Supabase para enviar dados.
class DependentCorrectionView extends StatefulWidget {
  final Member member;

  const DependentCorrectionView({super.key, required this.member});

  @override
  State<DependentCorrectionView> createState() =>
      _DependentCorrectionViewState();
}

class _DependentCorrectionViewState extends State<DependentCorrectionView> {
  // -------------------------------------------------------------------
  // Seleção visual dos campos corrigíveis — puramente visual.
  // -------------------------------------------------------------------
  final Map<String, bool> _selecionados = {
    'Nome social': false,
    'Nome completo': false,
    'Data de nascimento': false,
    'Telefone': false,
    'Estado': false,
    'Cidade': false,
    'Nome do responsável': false,
    'Telefone do responsável': false,
    'Contato de emergência': false,
    'Telefone do contato de emergência': false,
    'Gênero': false,
    'Raça / Cor': false,
    'Tipo sanguíneo': false,
    'CID': false,
  };

  // -------------------------------------------------------------------
  // Controllers para campos de texto da Central — dispose obrigatório.
  // -------------------------------------------------------------------
  late final TextEditingController _ctrlNomeSocial;
  late final TextEditingController _ctrlNomeCompleto;
  late final TextEditingController _ctrlDataNascimento;
  late final TextEditingController _ctrlTelefone;
  late final TextEditingController _ctrlNomeResponsavel;
  late final TextEditingController _ctrlTelefoneResponsavel;
  late final TextEditingController _ctrlContatoEmergencia;
  late final TextEditingController _ctrlTelefoneContatoEmergencia;
  late final TextEditingController _ctrlCid;

  // -------------------------------------------------------------------
  // Estado de loading e dropdowns
  // -------------------------------------------------------------------
  bool _isLoading = false;
  bool _removerNomeSocial = false;

  String? _genero;
  String? _racaCor;
  String? _tipoSanguineo;

  // Estado e Cidade usam IBGE real via CampoEstado/CampoCidade.
  String? _estadoCorrecao;
  String? _cidadeCorrecao;

  @override
  void initState() {
    super.initState();
    _ctrlNomeSocial = TextEditingController();
    _ctrlNomeCompleto = TextEditingController();
    _ctrlDataNascimento = TextEditingController();
    _ctrlTelefone = TextEditingController();
    _ctrlNomeResponsavel = TextEditingController();
    _ctrlTelefoneResponsavel = TextEditingController();
    _ctrlContatoEmergencia = TextEditingController();
    _ctrlTelefoneContatoEmergencia = TextEditingController();
    _ctrlCid = TextEditingController();
  }

  @override
  void dispose() {
    _ctrlNomeSocial.dispose();
    _ctrlNomeCompleto.dispose();
    _ctrlDataNascimento.dispose();
    _ctrlTelefone.dispose();
    _ctrlNomeResponsavel.dispose();
    _ctrlTelefoneResponsavel.dispose();
    _ctrlContatoEmergencia.dispose();
    _ctrlTelefoneContatoEmergencia.dispose();
    _ctrlCid.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Build principal
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return DsLoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: AppBackground(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DsBotaoVoltar(onPressed: () => Navigator.pop(context)),
                      const SizedBox(height: 24),

                      // Título e subtítulo
                      Text(
                        'Alterar dados',
                        style: DsTipografia.pageTitle.copyWith(
                          color: DsCores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione os dados que deseja atualizar para este dependente.',
                        style: DsTipografia.body.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seção: seleção e campos campo a campo
                      _buildSectionTitle(
                        'Quais dados deseja alterar?',
                        PhosphorIconsRegular.checkSquare,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecione um dado para informar o novo valor.',
                        style: DsTipografia.bodySmall.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lista de itens corrigíveis com campos inline
                      ..._selecionados.keys.map(_buildItemCorrigivel),

                      const SizedBox(height: 32),

                      DsBotao(
                        label: 'Salvar alterações',
                        onPressed: _submit,
                        variante: DsBotaoVariante.acao,
                        token: DsCores.correcao,
                        icon: PhosphorIconsRegular.paperPlaneRight,
                      ),
                      const SizedBox(height: 12),
                      DsBotao(
                        label: 'Cancelar',
                        onPressed: () => Navigator.pop(context),
                        variante: DsBotaoVariante.ghost,
                      ),
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

  // -------------------------------------------------------------------
  // Item corrigível: checkbox + valor atual + campo novo valor (se aberto)
  // -------------------------------------------------------------------
  Widget _buildItemCorrigivel(String campo) {
    final isSelected = _selecionados[campo] ?? false;
    final valorAtualStr = _getValorAtual(campo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha do checkbox
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selecionados[campo] = !isSelected),
              borderRadius: BorderRadius.circular(DsRaios.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DsCores.correcao.softBackground
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(DsRaios.md),
                  border: Border.all(
                    color: isSelected
                        ? DsCores.correcao.border
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Checkbox visual animado
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DsCores.correcao.accent.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? DsCores.correcao.accent
                              : Colors.white.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              PhosphorIconsRegular.check,
                              size: 13,
                              color: DsCores.correcao.accent,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        campo,
                        style: DsTipografia.body.copyWith(
                          color: isSelected
                              ? DsCores.correcao.accent
                              : DsCores.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isSelected ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        PhosphorIconsRegular.caretDown,
                        size: 16,
                        color: DsCores.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Painel expandido — valor atual + campo novo valor
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildPainelCampo(campo, valorAtualStr),
            crossFadeState: isSelected
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Painel expandido: valor atual (mockado) + campo específico
  // -------------------------------------------------------------------
  Widget _buildPainelCampo(String campo, String valorAtual) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: DsCores.correcao.softBackground,
        borderRadius: BorderRadius.circular(DsRaios.md),
        border: Border.all(color: DsCores.correcao.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Valor atual
          Text(
            'Valor atual',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valorAtual,
            style: DsTipografia.body.copyWith(
              color: DsCores.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Label do novo valor
          Text(
            'Novo valor',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Campo específico da Central de Campos Cadastrais
          _buildCampoEspecifico(campo),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Campo específico por nome de campo — Central de Campos Cadastrais
  // -------------------------------------------------------------------
  Widget _buildCampoEspecifico(String campo) {
    switch (campo) {
      // --- Campos com TextEditingController ---
      case 'Nome social':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampoNomeSocial(
              controller: _ctrlNomeSocial,
              requiredField: false,
              label: 'Novo nome social',
              enabled: !_removerNomeSocial,
            ),
            if (widget.member.socialName != null && widget.member.socialName!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    _removerNomeSocial = !_removerNomeSocial;
                    if (_removerNomeSocial) {
                      _ctrlNomeSocial.clear();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(DsRaios.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _removerNomeSocial
                              ? DsCores.correcao.accent.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _removerNomeSocial
                                ? DsCores.correcao.accent
                                : Colors.white.withValues(alpha: 0.3),
                            width: _removerNomeSocial ? 2 : 1.5,
                          ),
                        ),
                        child: _removerNomeSocial
                            ? Icon(
                                PhosphorIconsRegular.check,
                                size: 12,
                                color: DsCores.correcao.accent,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Remover nome social',
                          style: DsTipografia.body.copyWith(
                            color: _removerNomeSocial
                                ? DsCores.correcao.accent
                                : DsCores.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  'Use apenas se a pessoa utiliza nome social. Se foi preenchido por engano, você pode remover.',
                  style: DsTipografia.bodySmall.copyWith(
                    color: DsCores.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        );

      case 'Nome completo':
        return CampoNomeCompleto(
          controller: _ctrlNomeCompleto,
          requiredField: false,
          label: 'Novo nome completo',
        );

      case 'Data de nascimento':
        return CampoDataNascimento(
          controller: _ctrlDataNascimento,
          requiredField: false,
          label: 'Nova data de nascimento',
        );

      case 'Telefone':
        return CampoTelefone(
          controller: _ctrlTelefone,
          requiredField: false,
          label: 'Novo telefone',
        );

      case 'Nome do responsável':
        return CampoNomeResponsavel(
          controller: _ctrlNomeResponsavel,
          label: 'Novo nome do responsável',
        );

      case 'Telefone do responsável':
        return CampoTelefoneResponsavel(
          controller: _ctrlTelefoneResponsavel,
          label: 'Novo telefone do responsável',
        );

      case 'Contato de emergência':
        return CampoNomeContatoEmergencia(
          controller: _ctrlContatoEmergencia,
          label: 'Novo contato de emergência',
        );

      case 'Telefone do contato de emergência':
        return CampoTelefoneContatoEmergencia(
          controller: _ctrlTelefoneContatoEmergencia,
          label: 'Novo telefone do contato',
        );

      case 'CID':
        // CampoCid — não valida, não sugere diagnóstico, não pede upload.
        return CampoCid(
          controller: _ctrlCid,
          requiredField: false,
          label: 'Novo CID',
        );

      // --- Campos com Dropdown da Central ---
      case 'Gênero':
        return CampoGenero(
          value: _genero,
          requiredField: false,
          label: 'Novo gênero',
          onChanged: (val) => setState(() => _genero = val),
        );

      case 'Raça / Cor':
        return CampoRacaCor(
          value: _racaCor,
          requiredField: false,
          label: 'Nova raça / cor',
          onChanged: (val) => setState(() => _racaCor = val),
        );

      case 'Tipo sanguíneo':
        return CampoTipoSanguineo(
          value: _tipoSanguineo,
          requiredField: false,
          label: 'Novo tipo sanguíneo',
          onChanged: (val) => setState(() => _tipoSanguineo = val),
        );

      // --- Estado e Cidade: carregam via IBGE internamente ---
      case 'Estado':
        return CampoEstado(
          value: _estadoCorrecao,
          requiredField: false,
          label: 'Novo estado',
          onChanged: (val) => setState(() {
            _estadoCorrecao = val;
            _cidadeCorrecao = null; // Reseta cidade ao trocar estado
          }),
        );

      case 'Cidade':
        return CampoCidade(
          value: _cidadeCorrecao,
          estadoUf: _estadoCorrecao,
          requiredField: false,
          label: 'Nova cidade',
          onChanged: (val) => setState(() => _cidadeCorrecao = val),
        );

      default:
        // Fallback seguro — nunca deve ser atingido com a lista atual.
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------------
  // Título de seção com moldura de ícone
  // -------------------------------------------------------------------
  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    DsCorVisual color = DsCores.correcao,
  }) {
    return Row(
      children: [
        DsMolduraIcone(
          icon: icon,
          accentColor: color.accent,
          size: 32,
          iconSize: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: DsTipografia.sectionTitle.copyWith(
              color: DsCores.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Resgata o valor atual real do Member
  // -------------------------------------------------------------------
  String _getValorAtual(String campo) {
    final m = widget.member;
    switch (campo) {
      case 'Nome social':
        return _val(m.socialName);
      case 'Nome completo':
        return _val(m.name);
      case 'Data de nascimento':
        return _formatDateString(m.dateOfBirth);
      case 'Telefone':
        return _val(m.phone);
      case 'Estado':
        return _val(m.state);
      case 'Cidade':
        return _val(m.city);
      case 'Nome do responsável':
        return m.responsiblePersonName ?? 'Não informado';
      case 'Telefone do responsável':
        return m.responsiblePhone ?? 'Não informado';
      case 'Contato de emergência':
        return m.emergencyPersonName ?? 'Não informado';
      case 'Telefone do contato de emergência':
        return m.emergencyPhone ?? 'Não informado';
      case 'Gênero':
        return m.gender ?? 'Não informado';
      case 'Raça / Cor':
        return m.racaCor ?? 'Não informado';
      case 'Tipo sanguíneo':
        return _val(m.bloodType);
      case 'CID':
        return _val(m.cid);
      default:
        return 'Não informado';
    }
  }

  String _val(String? val) {
    if (val == null || val.trim().isEmpty) return 'Não informado';
    return val;
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Não informado';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  // -------------------------------------------------------------------
  // Lógica de Submissão
  // -------------------------------------------------------------------
  Future<void> _submit() async {
    if (_isLoading) return;
    // 1. Mapeamento dos campos permitidos
    final Map<String, String> chaves = {
      'Nome social': 'social_name',
      'Nome completo': 'name',
      'Data de nascimento': 'birth_date',
      'Telefone': 'phone',
      'Estado': 'state',
      'Cidade': 'city',
      'Nome do responsável': 'responsible_person_name',
      'Telefone do responsável': 'responsible_phone',
      'Contato de emergência': 'emergency_person_name',
      'Telefone do contato de emergência': 'emergency_phone',
      'Gênero': 'gender',
      'Raça / Cor': 'raca_cor',
      'Tipo sanguíneo': 'blood_type',
      'CID': 'cid',
    };

    final reviewData = <String, dynamic>{};

    for (final entry in _selecionados.entries) {
      if (!entry.value) continue;
      final campoUI = entry.key;

      final chaveReal = chaves[campoUI];
      if (chaveReal == null) continue;

      String novoValor = '';

      switch (campoUI) {
        case 'Nome social':
          novoValor = _ctrlNomeSocial.text.trim();
          break;
        case 'Nome completo':
          novoValor = _ctrlNomeCompleto.text.trim();
          break;
        case 'Data de nascimento':
          novoValor = _ctrlDataNascimento.text.trim();
          break;
        case 'Telefone':
          novoValor = _ctrlTelefone.text.trim();
          break;
        case 'Estado':
          novoValor = _estadoCorrecao?.trim() ?? '';
          break;
        case 'Cidade':
          novoValor = _cidadeCorrecao?.trim() ?? '';
          break;
        case 'Nome do responsável':
          novoValor = _ctrlNomeResponsavel.text.trim();
          break;
        case 'Telefone do responsável':
          novoValor = _ctrlTelefoneResponsavel.text.trim();
          break;
        case 'Contato de emergência':
          novoValor = _ctrlContatoEmergencia.text.trim();
          break;
        case 'Telefone do contato de emergência':
          novoValor = _ctrlTelefoneContatoEmergencia.text.trim();
          break;
        case 'Gênero':
          novoValor = _genero?.trim() ?? '';
          break;
        case 'Raça / Cor':
          novoValor = _racaCor?.trim() ?? '';
          break;
        case 'Tipo sanguíneo':
          novoValor = _tipoSanguineo?.trim() ?? '';
          break;
        case 'CID':
          novoValor = _ctrlCid.text.trim();
          break;
      }

      if (campoUI == 'Nome social' && _removerNomeSocial) {
        if (widget.member.socialName != null && widget.member.socialName!.trim().isNotEmpty) {
          reviewData[chaveReal] = null;
        }
      } else if (novoValor.isNotEmpty) {
        // Obter valor atual para evitar mandar a mesma coisa
        final atual = _getValorAtual(campoUI);
        if (novoValor != atual && novoValor != 'Não informado') {
          reviewData[chaveReal] = novoValor;
        }
      }
    }

    final String? currentRespName = widget.member.responsiblePersonName;
    final bool hasCurrentRespName =
        currentRespName != null && currentRespName.trim().isNotEmpty;
    final bool isSendingRespPhone = reviewData.containsKey('responsible_phone');
    final bool isSendingRespName =
        reviewData.containsKey('responsible_person_name') &&
        reviewData['responsible_person_name'].toString().trim().isNotEmpty;

    if (isSendingRespPhone && !hasCurrentRespName && !isSendingRespName) {
      DsFeedback.showSnackBar(
        context: context,
        mensagem: 'Informe o nome do responsável junto com o telefone.',
        tipo: DsFeedbackTipo.alerta,
      );
      return;
    }

    final String? currentEmergName = widget.member.emergencyPersonName;
    final bool hasCurrentEmergName =
        currentEmergName != null && currentEmergName.trim().isNotEmpty;
    final bool isSendingEmergPhone = reviewData.containsKey('emergency_phone');
    final bool isSendingEmergName =
        reviewData.containsKey('emergency_person_name') &&
        reviewData['emergency_person_name'].toString().trim().isNotEmpty;

    if (isSendingEmergPhone && !hasCurrentEmergName && !isSendingEmergName) {
      DsFeedback.showSnackBar(
        context: context,
        mensagem:
            'Informe o nome do contato de emergência junto com o telefone.',
        tipo: DsFeedbackTipo.alerta,
      );
      return;
    }

    if (reviewData.isEmpty) {
      DsFeedback.showSnackBar(
        context: context,
        mensagem: 'Nenhuma alteração foi informada.',
        tipo: DsFeedbackTipo.alerta,
      );
      return;
    }

    final shouldSave = await DsDialog.show<bool>(
      context: context,
      title: 'Confirmar alteração',
      description:
          'Revise os dados antes de continuar. Ao confirmar, as alterações serão salvas na carteirinha do dependente.',
      token: DsCores.sucesso,
      icon: PhosphorIconsRegular.checkCircle,
      primaryAction: const DsDialogAction<bool>(
        label: 'Confirmar alteração',
        value: true,
        variante: DsBotaoVariante.acao,
      ),
      secondaryAction: const DsDialogAction<bool>(
        label: 'Voltar e revisar',
        value: false,
        variante: DsBotaoVariante.ghost,
      ),
    );

    if (shouldSave != true) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      final res = await db.updateDependentCommonData(
        memberId: widget.member.id,
        updates: reviewData,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final success = res['success'] == true;
      if (success) {
        DsFeedback.showSnackBar(
          context: context,
          mensagem: 'Dados atualizados com sucesso.',
          tipo: DsFeedbackTipo.sucesso,
        );
        Navigator.pop(context, true);
      } else {
        final msg = res['error_message'] ?? 'Não foi possível salvar as alterações.';
        DsFeedback.showSnackBar(
          context: context,
          mensagem: msg,
          tipo: DsFeedbackTipo.erro,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      DsFeedback.showSnackBar(
        context: context,
        mensagem: 'Ocorreu um erro inesperado.',
        tipo: DsFeedbackTipo.erro,
      );
    }
  }
}
