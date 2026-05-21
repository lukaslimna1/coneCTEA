import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:conectea/core/servicos/localizacao/localizacao_service.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EditMyDataView extends StatefulWidget {
  const EditMyDataView({super.key});

  @override
  State<EditMyDataView> createState() => _EditMyDataViewState();
}

class _EditMyDataViewState extends State<EditMyDataView> {
  late final TextEditingController _nomeCompletoController;
  late final TextEditingController _nomeSocialController;
  late final TextEditingController _dataNascimentoController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _nomeInstituicaoController;

  // Serviço IBGE — instância local, sem persistência.
  final IbgeLocalizacaoService _ibgeService = IbgeLocalizacaoService();

  // Estados dos dropdowns
  String? _estado;
  String? _cidade;
  String? _genero;
  String? _racaCor;
  String? _indicacaoInstituicao;

  // Listas dinâmicas carregadas via IBGE
  List<String> _estados = [];
  List<String> _cidades = [];

  // Flags de carregamento
  bool _carregandoEstados = false;
  bool _carregandoCidades = false;

  @override
  void initState() {
    super.initState();
    // Campos editáveis iniciados vazios nesta fase visual para não induzir a falsos carregamentos.
    _nomeCompletoController = TextEditingController(text: '');
    _nomeSocialController = TextEditingController(text: '');
    _dataNascimentoController = TextEditingController(text: '');
    _telefoneController = TextEditingController(text: '');
    _nomeInstituicaoController = TextEditingController(text: '');

    _estado = null;
    _cidade = null;
    _genero = null;
    _racaCor = null;
    _indicacaoInstituicao = null;

    _carregarEstados();
  }

  @override
  void dispose() {
    _nomeCompletoController.dispose();
    _nomeSocialController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _nomeInstituicaoController.dispose();
    super.dispose();
  }

  /// Carrega estados do IBGE e converte para lista de siglas (UF).
  Future<void> _carregarEstados() async {
    setState(() => _carregandoEstados = true);
    try {
      final resultado = await _ibgeService.buscarEstados();
      if (mounted) {
        setState(() {
          _estados = resultado.map((e) => e.sigla).toList();
          _carregandoEstados = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoEstados = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar os estados.')),
        );
      }
    }
  }

  /// Carrega cidades do IBGE para a UF selecionada e converte para lista de nomes.
  Future<void> _carregarCidades(String uf) async {
    setState(() {
      _carregandoCidades = true;
      _cidades = [];
    });
    try {
      final resultado = await _ibgeService.buscarCidadesPorUf(uf);
      if (mounted) {
        setState(() {
          _cidades = resultado.map((c) => c.nome).toList();
          _carregandoCidades = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoCidades = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar as cidades.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hint dinâmico para Estado
    final String hintEstado = _carregandoEstados
        ? 'Carregando estados...'
        : 'Selecione o estado';

    // Hint dinâmico para Cidade
    final String hintCidade;
    if (_carregandoCidades) {
      hintCidade = 'Carregando cidades...';
    } else if (_estado == null) {
      hintCidade = 'Escolha o estado';
    } else {
      hintCidade = 'Selecione a cidade';
    }

    return Scaffold(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsBotaoVoltar(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Editar meus dados',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atualize as informações permitidas do seu cadastro.',
                      style: DsTipografia.body.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DsCores.dadosProtegidos.softBackground,
                        borderRadius: BorderRadius.circular(DsRaios.md),
                        border: Border.all(color: DsCores.dadosProtegidos.border),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.shieldCheck, color: DsCores.dadosProtegidos.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'CPF e e-mail são protegidos e precisam de solicitação para correção.',
                              style: DsTipografia.infoBody.copyWith(color: DsCores.dadosProtegidos.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados pessoais', PhosphorIconsRegular.identificationCard),
                    const SizedBox(height: 16),
                    CampoNomeCompleto(controller: _nomeCompletoController),
                    const SizedBox(height: 12),
                    CampoNomeSocial(controller: _nomeSocialController),
                    const SizedBox(height: 12),
                    CampoDataNascimento(controller: _dataNascimentoController),
                    const SizedBox(height: 12),
                    CampoTelefone(controller: _telefoneController),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Localização', PhosphorIconsRegular.mapPin),
                    const SizedBox(height: 16),
                    CampoEstado(
                      value: _estado,
                      items: _estados,
                      hint: hintEstado,
                      enabled: !_carregandoEstados,
                      onChanged: (val) {
                        setState(() {
                          _estado = val;
                          _cidade = null;
                          _cidades = [];
                        });
                        if (val != null && val.isNotEmpty) {
                          _carregarCidades(val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    CampoCidade(
                      value: _cidade,
                      items: _cidades,
                      hint: hintCidade,
                      enabled: _estado != null && !_carregandoCidades,
                      onChanged: (val) {
                        setState(() {
                          _cidade = val;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados complementares', PhosphorIconsRegular.listPlus),
                    const SizedBox(height: 16),
                    CampoGenero(
                      value: _genero,
                      onChanged: (val) {
                        setState(() {
                          _genero = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CampoRacaCor(
                      value: _racaCor,
                      onChanged: (val) {
                        setState(() {
                          _racaCor = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CampoIndicacaoInstituicao(
                      value: _indicacaoInstituicao,
                      onChanged: (val) {
                        setState(() {
                          _indicacaoInstituicao = val;
                        });
                      },
                    ),
                    if (_indicacaoInstituicao == 'Sim') ...[
                      const SizedBox(height: 12),
                      CampoNomeInstituicao(
                        controller: _nomeInstituicaoController,
                      ),
                    ],

                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados protegidos', PhosphorIconsRegular.shieldCheck, color: DsCores.dadosProtegidos),
                    const SizedBox(height: 8),
                    Text(
                      'Para proteger sua conta, esses dados não são alterados diretamente por aqui.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _buildProtectedField('CPF', '***.***.***-**'),
                    const SizedBox(height: 12),
                    _buildProtectedField('E-mail', 'l***@email.com'),
                    const SizedBox(height: 12),
                    DsBotao(
                      label: 'Solicitar correção',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fluxo visual em construção.')),
                        );
                      },
                      variante: DsBotaoVariante.acao,
                      token: DsCores.correcao,
                      icon: PhosphorIconsRegular.paperPlaneRight,
                    ),

                    const SizedBox(height: 48),

                    DsBotao(
                      label: 'Salvar alterações',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tela visual em construção. Nenhum dado foi salvo.')),
                        );
                      },
                      variante: DsBotaoVariante.acao,
                      token: DsCores.conta,
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
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {DsCorVisual color = DsCores.conta}) {
    return Row(
      children: [
        DsMolduraIcone(
          icon: icon,
          accentColor: color.accent,
          size: 32, // Reduzido localmente para equilíbrio em telas de 360dp
          iconSize: 18, // Proporcional ao tamanho reduzido
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: DsTipografia.sectionTitle.copyWith(color: DsCores.textPrimary),
        ),
      ],
    );
  }

  Widget _buildProtectedField(String label, String value) {
    return DsInput(
      label: label,
      controller: TextEditingController(text: value),
      icon: PhosphorIconsRegular.lock,
      readOnly: true,
      enabled: false,
    );
  }
}
