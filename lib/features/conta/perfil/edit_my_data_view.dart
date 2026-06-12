import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:conectea/features/conta/perfil/widgets/my_data_logged_header.dart';
import 'package:conectea/models/app_user.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CampoModificado {
  final String label;
  final String valorAnterior;
  final String novoValor;
  const CampoModificado({
    required this.label,
    required this.valorAnterior,
    required this.novoValor,
  });
}

class EditMyDataView extends StatefulWidget {
  final AppUser user;
  const EditMyDataView({super.key, required this.user});

  @override
  State<EditMyDataView> createState() => _EditMyDataViewState();
}

class _EditMyDataViewState extends State<EditMyDataView> {
  final _formKey = GlobalKey<FormState>();

  // Controle de saída unificada e proteção de PopScope
  bool _discardConfirmed = false;
  bool _isDiscardDialogOpen = false;

  late final TextEditingController _nomeCompletoController;
  late final TextEditingController _nomeSocialController;
  late final TextEditingController _dataNascimentoController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _nomeInstituicaoController;

  // Estados dos dropdowns
  String? _estado;
  String? _cidade;
  String? _genero;
  String? _racaCor;
  String? _indicacaoInstituicao;

  // Cópias imutáveis originais
  late final String _origNomeCompleto;
  late final String _origNomeSocial;
  late final String _origDataNascimento;
  late final String _origTelefone;
  late final String? _origEstado;
  late final String? _origCidade;
  late final String? _origGenero;
  late final String? _origRacaCor;
  late final String? _origIndicacaoInstituicao;
  late final String _origNomeInstituicao;

  // Checkbox de confirmação no diálogo
  bool _confirmacaoRevisao = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;

    _origNomeCompleto = u.name.trim();
    _origNomeSocial = (u.socialName ?? '').trim();
    _origDataNascimento = _formatDateOfBirthForEdit(u.dateOfBirth);
    _origTelefone = u.phone.trim();
    _origEstado = (u.state != null && u.state!.trim().isNotEmpty)
        ? u.state!.trim()
        : null;
    _origCidade = (u.city != null && u.city!.trim().isNotEmpty)
        ? u.city!.trim()
        : null;
    _origGenero = (u.gender != null && u.gender!.trim().isNotEmpty)
        ? u.gender!.trim()
        : null;
    _origRacaCor = (u.race != null && u.race!.trim().isNotEmpty)
        ? u.race!.trim()
        : null;

    final temInstituicao =
        u.institution != null && u.institution!.trim().isNotEmpty;
    _origIndicacaoInstituicao = temInstituicao ? 'Sim' : 'Não';
    _origNomeInstituicao = temInstituicao ? u.institution!.trim() : '';

    _nomeCompletoController = TextEditingController(text: _origNomeCompleto);
    _nomeSocialController = TextEditingController(text: _origNomeSocial);
    _dataNascimentoController = TextEditingController(
      text: _origDataNascimento,
    );
    _telefoneController = TextEditingController(text: _origTelefone);
    _nomeInstituicaoController = TextEditingController(
      text: _origNomeInstituicao,
    );

    _estado = _origEstado;
    _cidade = _origCidade;
    _genero = _origGenero;
    _racaCor = _origRacaCor;
    _indicacaoInstituicao = _origIndicacaoInstituicao;

    _nomeCompletoController.addListener(_onFieldChanged);
    _nomeSocialController.addListener(_onFieldChanged);
    _dataNascimentoController.addListener(_onFieldChanged);
    _telefoneController.addListener(_onFieldChanged);
    _nomeInstituicaoController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nomeCompletoController.removeListener(_onFieldChanged);
    _nomeSocialController.removeListener(_onFieldChanged);
    _dataNascimentoController.removeListener(_onFieldChanged);
    _telefoneController.removeListener(_onFieldChanged);
    _nomeInstituicaoController.removeListener(_onFieldChanged);

    _nomeCompletoController.dispose();
    _nomeSocialController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _nomeInstituicaoController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  String _formatDateOfBirthForEdit(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    final regExp = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final match = regExp.firstMatch(dateStr.trim());
    if (match != null) {
      final year = match.group(1);
      final month = match.group(2);
      final day = match.group(3);
      return '$day/$month/$year';
    }
    return dateStr.trim();
  }

  List<CampoModificado> _getModifiedFields() {
    final list = <CampoModificado>[];

    // Nome completo
    final curNome = _nomeCompletoController.text.trim();
    if (curNome != _origNomeCompleto) {
      list.add(
        CampoModificado(
          label: 'Nome completo',
          valorAnterior: _origNomeCompleto.isEmpty
              ? 'Não informado'
              : _origNomeCompleto,
          novoValor: curNome.isEmpty ? 'Não informado' : curNome,
        ),
      );
    }

    // Nome social
    final curSocial = _nomeSocialController.text.trim();
    if (curSocial != _origNomeSocial) {
      list.add(
        CampoModificado(
          label: 'Nome social',
          valorAnterior: _origNomeSocial.isEmpty
              ? 'Não informado'
              : _origNomeSocial,
          novoValor: curSocial.isEmpty ? 'Não informado' : curSocial,
        ),
      );
    }

    // Data de nascimento
    final curNascimento = _dataNascimentoController.text.trim();
    if (curNascimento != _origDataNascimento) {
      list.add(
        CampoModificado(
          label: 'Data de nascimento',
          valorAnterior: _origDataNascimento.isEmpty
              ? 'Não informado'
              : _origDataNascimento,
          novoValor: curNascimento.isEmpty ? 'Não informado' : curNascimento,
        ),
      );
    }

    // Telefone (ignorar formatação)
    final cleanCurPhone = _telefoneController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final cleanOrigPhone = _origTelefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCurPhone != cleanOrigPhone) {
      list.add(
        CampoModificado(
          label: 'Telefone',
          valorAnterior: _origTelefone.isEmpty
              ? 'Não informado'
              : _origTelefone,
          novoValor: _telefoneController.text.trim().isEmpty
              ? 'Não informado'
              : _telefoneController.text.trim(),
        ),
      );
    }

    // Estado
    if ((_estado ?? '') != (_origEstado ?? '')) {
      list.add(
        CampoModificado(
          label: 'Estado',
          valorAnterior: _origEstado ?? 'Não informado',
          novoValor: _estado ?? 'Não informado',
        ),
      );
    }

    // Cidade
    if ((_cidade ?? '') != (_origCidade ?? '')) {
      list.add(
        CampoModificado(
          label: 'Cidade',
          valorAnterior: _origCidade ?? 'Não informado',
          novoValor: _cidade ?? 'Não informado',
        ),
      );
    }

    // Gênero
    if ((_genero ?? '') != (_origGenero ?? '')) {
      list.add(
        CampoModificado(
          label: 'Gênero',
          valorAnterior: _origGenero ?? 'Não informado',
          novoValor: _genero ?? 'Não informado',
        ),
      );
    }

    // Raça / Cor
    if ((_racaCor ?? '') != (_origRacaCor ?? '')) {
      list.add(
        CampoModificado(
          label: 'Raça / Cor',
          valorAnterior: _origRacaCor ?? 'Não informado',
          novoValor: _racaCor ?? 'Não informado',
        ),
      );
    }

    // Instituição / Origem
    final curIndicacao = _indicacaoInstituicao ?? 'Não';
    final origIndicacao = _origIndicacaoInstituicao ?? 'Não';
    final curNomeInst = curIndicacao == 'Sim'
        ? _nomeInstituicaoController.text.trim()
        : '';
    final origNomeInst = origIndicacao == 'Sim' ? _origNomeInstituicao : '';

    if (curIndicacao != origIndicacao || curNomeInst != origNomeInst) {
      final valorAntText = origIndicacao == 'Sim'
          ? 'Sim (${_origNomeInstituicao.isEmpty ? "Não informado" : _origNomeInstituicao})'
          : 'Não';
      final valorNovText = curIndicacao == 'Sim'
          ? 'Sim (${_nomeInstituicaoController.text.trim().isEmpty ? "Não informado" : _nomeInstituicaoController.text.trim()})'
          : 'Não';

      list.add(
        CampoModificado(
          label: 'Instituição / Origem',
          valorAnterior: valorAntText,
          novoValor: valorNovText,
        ),
      );
    }

    return list;
  }

  bool _hasChanges() {
    return _getModifiedFields().isNotEmpty;
  }

  Widget _buildAntesLabel(String campo) {
    final mods = _getModifiedFields();
    final mod = mods.firstWhere(
      (m) => m.label == campo,
      orElse: () =>
          const CampoModificado(label: '', valorAnterior: '', novoValor: ''),
    );
    if (mod.label.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          'Antes: ${mod.valorAnterior}',
          style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<bool> _showDiscardConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: DsCard(
                padding: EdgeInsets.zero,
                radius: 20,
                borderColor: DsCores.alerta.border,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsRegular.warningCircle,
                        color: DsCores.alerta.accent,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Descartar alterações?',
                        style: DsTipografia.cardTitle.copyWith(
                          color: DsCores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você fez alterações que ainda não foram salvas. Deseja realmente sair e descartar as mudanças?',
                        style: DsTipografia.bodySmall.copyWith(
                          color: DsCores.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: DsBotao(
                              label: 'Continuar',
                              onPressed: () => Navigator.pop(context, false),
                              variante: DsBotaoVariante.ghost,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DsBotao(
                              label: 'Sair',
                              onPressed: () => Navigator.pop(context, true),
                              variante: DsBotaoVariante.acao,
                              token: DsCores.alerta,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _requestExit() async {
    if (!_hasChanges() || _discardConfirmed) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (_isDiscardDialogOpen) return;

    _isDiscardDialogOpen = true;
    final descartar = await _showDiscardConfirmDialog();
    _isDiscardDialogOpen = false;

    if (descartar && mounted) {
      setState(() {
        _discardConfirmed = true;
      });
      Navigator.pop(context);
    }
  }

  void _handleRevisarAlteracoes() {
    if (!_hasChanges()) return;
    if (_formKey.currentState?.validate() ?? false) {
      _showReviewDialog();
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final modified = _getModifiedFields();
              final temDadosImportantes = modified.any(
                (m) =>
                    m.label == 'Nome completo' ||
                    m.label == 'Data de nascimento',
              );

              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: DsCard(
                    padding: EdgeInsets.zero,
                    radius: 24,
                    borderColor: DsCores.conta.border,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DsCores.conta.accent.withValues(alpha: 0.1),
                                DsCores.conta.accent.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DsCores.conta.softBackground,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: DsCores.conta.border,
                                  ),
                                ),
                                child: Icon(
                                  PhosphorIconsRegular.fileText,
                                  color: DsCores.conta.accent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Confirmar alterações',
                                style: DsTipografia.cardTitle.copyWith(
                                  color: DsCores.textPrimary,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Corpo
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Resumo das mudanças:',
                                  style: DsTipografia.bodySmall.copyWith(
                                    color: DsCores.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...modified.map(
                                  (mod) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '• ${mod.label}: ${mod.valorAnterior} → ${mod.novoValor}',
                                      style: DsTipografia.bodySmall.copyWith(
                                        color: DsCores.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                if (temDadosImportantes) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: DsCores.alerta.softBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: DsCores.alerta.border,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.warning,
                                          color: DsCores.alerta.accent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Esta alteração modifica dados importantes de identificação da conta. Revise com atenção antes de confirmar.',
                                            style: DsTipografia.bodySmall
                                                .copyWith(
                                                  color: DsCores.textPrimary,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                DsCheckbox(
                                  value: _confirmacaoRevisao,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _confirmacaoRevisao = val ?? false;
                                    });
                                  },
                                  label: Text(
                                    'Confirmo que revisei os dados acima e desejo aplicar estas alterações.',
                                    style: DsTipografia.bodySmall.copyWith(
                                      color: DsCores.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  token: DsCores.conta,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                        // Botoes
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            children: [
                              DsBotao(
                                label: 'Confirmar e salvar',
                                onPressed: _confirmacaoRevisao
                                    ? () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Confirmação concluída. O salvamento será conectado na próxima etapa.',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                variante: DsBotaoVariante.acao,
                                token: DsCores.conta,
                              ),
                              const SizedBox(height: 8),
                              DsBotao(
                                label: 'Cancelar',
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                variante: DsBotaoVariante.ghost,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      setState(() {
        _confirmacaoRevisao = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges() || _discardConfirmed,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: AppBackground(
          child: Column(
            children: [
              const MyDataLoggedHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsBotaoVoltar(onPressed: _requestExit),
                        const SizedBox(height: 24),
                        Text(
                          'Editar meus dados',
                          style: DsTipografia.pageTitle.copyWith(
                            color: DsCores.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Atualize as informações permitidas do seu cadastro.',
                          style: DsTipografia.body.copyWith(
                            color: DsCores.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildSectionTitle(
                          'Dados pessoais',
                          PhosphorIconsRegular.identificationCard,
                        ),
                        const SizedBox(height: 16),
                        CampoNomeCompleto(controller: _nomeCompletoController),
                        _buildAntesLabel('Nome completo'),
                        const SizedBox(height: 12),
                        CampoNomeSocial(controller: _nomeSocialController),
                        _buildAntesLabel('Nome social'),
                        const SizedBox(height: 12),
                        CampoDataNascimento(
                          controller: _dataNascimentoController,
                        ),
                        _buildAntesLabel('Data de nascimento'),
                        const SizedBox(height: 12),
                        CampoTelefone(controller: _telefoneController),
                        _buildAntesLabel('Telefone'),

                        const SizedBox(height: 32),

                        _buildSectionTitle(
                          'Localização',
                          PhosphorIconsRegular.mapPin,
                        ),
                        const SizedBox(height: 16),
                        CampoEstado(
                          value: _estado,
                          onChanged: (val) {
                            setState(() {
                              _estado = val;
                              _cidade = null;
                            });
                          },
                        ),
                        _buildAntesLabel('Estado'),
                        const SizedBox(height: 12),
                        CampoCidade(
                          value: _cidade,
                          estadoUf: _estado,
                          onChanged: (val) {
                            setState(() {
                              _cidade = val;
                            });
                          },
                        ),
                        _buildAntesLabel('Cidade'),

                        const SizedBox(height: 32),

                        _buildSectionTitle(
                          'Dados complementares',
                          PhosphorIconsRegular.listPlus,
                        ),
                        const SizedBox(height: 16),
                        CampoGenero(
                          value: _genero,
                          onChanged: (val) {
                            setState(() {
                              _genero = val;
                            });
                          },
                        ),
                        _buildAntesLabel('Gênero'),
                        const SizedBox(height: 12),
                        CampoRacaCor(
                          value: _racaCor,
                          onChanged: (val) {
                            setState(() {
                              _racaCor = val;
                            });
                          },
                        ),
                        _buildAntesLabel('Raça / Cor'),
                        const SizedBox(height: 12),
                        CampoIndicacaoInstituicao(
                          value: _indicacaoInstituicao,
                          onChanged: (val) {
                            setState(() {
                              _indicacaoInstituicao = val;
                            });
                          },
                        ),
                        _buildAntesLabel('Instituição / Origem'),
                        if (_indicacaoInstituicao == 'Sim') ...[
                          const SizedBox(height: 12),
                          CampoNomeInstituicao(
                            controller: _nomeInstituicaoController,
                            requiredField: _indicacaoInstituicao == 'Sim',
                            validator: (value) {
                              if (_indicacaoInstituicao == 'Sim' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Nome da instituição é obrigatório';
                              }
                              return null;
                            },
                          ),
                        ],

                        _buildSummaryCard(),

                        const SizedBox(height: 48),

                        DsBotao(
                          label: _hasChanges()
                              ? 'Revisar alterações'
                              : 'Salvar alterações',
                          onPressed: _hasChanges()
                              ? _handleRevisarAlteracoes
                              : null,
                          variante: DsBotaoVariante.acao,
                          token: DsCores.conta,
                        ),
                        const SizedBox(height: 12),
                        DsBotao(
                          label: 'Cancelar',
                          onPressed: _requestExit,
                          variante: DsBotaoVariante.ghost,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final modified = _getModifiedFields();
    if (modified.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        DsCard(
          borderColor: DsCores.conta.border,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alterações realizadas',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...modified.map(
                  (mod) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mod.label,
                          style: DsTipografia.bodySmall.copyWith(
                            color: DsCores.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                mod.valorAnterior,
                                style: DsTipografia.body.copyWith(
                                  color: DsCores.textSecondary,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                PhosphorIconsRegular.arrowRight,
                                size: 16,
                                color: DsCores.conta.accent,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                mod.novoValor,
                                style: DsTipografia.body.copyWith(
                                  color: DsCores.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (mod != modified.last) ...[
                          const SizedBox(height: 12),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    DsCorVisual color = DsCores.conta,
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
        Text(
          title,
          style: DsTipografia.sectionTitle.copyWith(color: DsCores.textPrimary),
        ),
      ],
    );
  }
}
