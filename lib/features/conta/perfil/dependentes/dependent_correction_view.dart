import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/conta/perfil/widgets/my_data_logged_header.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de solicitação de correção de dados do dependente.
///
/// Esta tela é apenas visual nesta fase.
/// Não envia dados, não salva, não conecta com Supabase, Auth, Drive ou banco.
/// Não exibe CPF real, CID real, documento, URL, fileId ou laudo.
/// Não altera status de carteirinha. Não valida dados reais.
/// Ao selecionar um campo corrigível, abre o campo específico logo abaixo.
class DependentCorrectionView extends StatefulWidget {
  const DependentCorrectionView({super.key});

  @override
  State<DependentCorrectionView> createState() =>
      _DependentCorrectionViewState();
}

class _DependentCorrectionViewState extends State<DependentCorrectionView> {
  // -------------------------------------------------------------------
  // Seleção visual dos campos corrigíveis — puramente visual.
  // -------------------------------------------------------------------
  final Map<String, bool> _selecionados = {
    'Nome completo': false,
    'CPF': false,
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

  // Valor atual mockado por campo — nunca exibe dados reais.
  static const Map<String, String> _valorAtual = {
    'Nome completo': 'Exemplo de dependente',
    'CPF': '***.***.***-**',
    'Data de nascimento': 'Não informado',
    'Telefone': 'Não informado',
    'Estado': 'Não informado',
    'Cidade': 'Não informado',
    'Nome do responsável': 'Não informado',
    'Telefone do responsável': 'Não informado',
    'Contato de emergência': 'Não informado',
    'Telefone do contato de emergência': 'Não informado',
    'Gênero': 'Não informado',
    'Raça / Cor': 'Não informado',
    'Tipo sanguíneo': 'Não informado',
    'CID': 'Oculto',
  };

  // Campos que exigem aviso de conferência administrativa.
  static const _camposComAviso = {'CPF', 'CID'};

  // -------------------------------------------------------------------
  // Controllers para campos de texto da Central — dispose obrigatório.
  // -------------------------------------------------------------------
  late final TextEditingController _ctrlNomeCompleto;
  late final TextEditingController _ctrlCpf;
  late final TextEditingController _ctrlDataNascimento;
  late final TextEditingController _ctrlTelefone;
  late final TextEditingController _ctrlNomeResponsavel;
  late final TextEditingController _ctrlTelefoneResponsavel;
  late final TextEditingController _ctrlContatoEmergencia;
  late final TextEditingController _ctrlTelefoneContatoEmergencia;
  late final TextEditingController _ctrlCid;
  late final TextEditingController _ctrlObservacoes;

  // -------------------------------------------------------------------
  // Estado dos dropdowns da Central.
  // -------------------------------------------------------------------
  String? _genero;
  String? _racaCor;
  String? _tipoSanguineo;

  // Estado e Cidade usam IBGE real via CampoEstado/CampoCidade.
  String? _estadoCorrecao;
  String? _cidadeCorrecao;

  @override
  void initState() {
    super.initState();
    _ctrlNomeCompleto = TextEditingController();
    _ctrlCpf = TextEditingController();
    _ctrlDataNascimento = TextEditingController();
    _ctrlTelefone = TextEditingController();
    _ctrlNomeResponsavel = TextEditingController();
    _ctrlTelefoneResponsavel = TextEditingController();
    _ctrlContatoEmergencia = TextEditingController();
    _ctrlTelefoneContatoEmergencia = TextEditingController();
    _ctrlCid = TextEditingController();
    _ctrlObservacoes = TextEditingController();
  }

  @override
  void dispose() {
    _ctrlNomeCompleto.dispose();
    _ctrlCpf.dispose();
    _ctrlDataNascimento.dispose();
    _ctrlTelefone.dispose();
    _ctrlNomeResponsavel.dispose();
    _ctrlTelefoneResponsavel.dispose();
    _ctrlContatoEmergencia.dispose();
    _ctrlTelefoneContatoEmergencia.dispose();
    _ctrlCid.dispose();
    _ctrlObservacoes.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Build principal
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
                    DsBotaoVoltar(onPressed: () => Navigator.pop(context)),
                    const SizedBox(height: 24),

                    // Título e subtítulo
                    Text(
                      'Solicitar correção',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Informe quais dados do dependente precisam ser revisados.',
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card explicativo
                    _buildCardExplicativo(),
                    const SizedBox(height: 32),

                    // Seção: seleção e campos campo a campo
                    _buildSectionTitle(
                      'Quais dados precisam de correção?',
                      PhosphorIconsRegular.checkSquare,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecione um dado para informar o novo valor solicitado.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de itens corrigíveis com campos inline
                    ..._selecionados.keys.map(_buildItemCorrigivel),

                    const SizedBox(height: 32),

                    // Seção: Observações (campo geral opcional)
                    _buildSectionTitle(
                      'Observações',
                      PhosphorIconsRegular.notepad,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opcional. Adicione uma observação se quiser explicar melhor a correção.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCampoObservacoes(),
                    const SizedBox(height: 40),

                    // Botão principal (mockado)
                    DsBotao(
                      label: 'Enviar solicitação',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fluxo visual em construção.'),
                          ),
                        );
                      },
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
    );
  }

  // -------------------------------------------------------------------
  // Card explicativo
  // -------------------------------------------------------------------
  Widget _buildCardExplicativo() {
    return DsCard(
      padding: const EdgeInsets.all(16),
      borderColor: DsCores.correcao.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.info,
            color: DsCores.correcao.accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta solicitação será analisada pela equipe administrativa. '
              'A correção só será aplicada após aprovação.',
              style: DsTipografia.infoBody.copyWith(
                color: DsCores.correcao.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Item corrigível: checkbox + valor atual + campo novo valor (se aberto)
  // -------------------------------------------------------------------
  Widget _buildItemCorrigivel(String campo) {
    final isSelected = _selecionados[campo] ?? false;
    final temAviso = _camposComAviso.contains(campo);
    final valorAtualStr = _valorAtual[campo] ?? 'Não informado';

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
                    if (temAviso) ...[
                      const SizedBox(width: 8),
                      Icon(
                        PhosphorIconsRegular.shieldWarning,
                        size: 16,
                        color: DsCores.dadosProtegidos.accent.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ],
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
            secondChild: _buildPainelCampo(campo, valorAtualStr, temAviso),
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
  Widget _buildPainelCampo(String campo, String valorAtual, bool temAviso) {
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

          // Aviso especial para CPF e CID
          if (temAviso) ...[
            const SizedBox(height: 12),
            _buildAvisoProtegido(campo),
          ],

          const SizedBox(height: 16),

          // Label do novo valor
          Text(
            'Novo valor solicitado',
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
  // Aviso inline para CPF e CID
  // -------------------------------------------------------------------
  Widget _buildAvisoProtegido(String campo) {
    final texto = campo == 'CPF'
        ? 'Correções de CPF podem exigir nova conferência de documento no fluxo administrativo.'
        : 'Correções de CID podem exigir nova conferência de laudo no fluxo administrativo.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DsCores.dadosProtegidos.softBackground,
        borderRadius: BorderRadius.circular(DsRaios.sm),
        border: Border.all(color: DsCores.dadosProtegidos.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.shieldWarning,
            size: 16,
            color: DsCores.dadosProtegidos.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: DsTipografia.bodySmall.copyWith(
                color: DsCores.dadosProtegidos.accent,
              ),
            ),
          ),
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
      case 'Nome completo':
        return CampoNomeCompleto(
          controller: _ctrlNomeCompleto,
          requiredField: false,
          label: 'Nome completo corrigido',
        );

      case 'CPF':
        // CampoCpf — não exibe CPF atual real; campo para novo valor solicitado.
        return CampoCpf(
          controller: _ctrlCpf,
          requiredField: false,
          label: 'CPF corrigido',
        );

      case 'Data de nascimento':
        return CampoDataNascimento(
          controller: _ctrlDataNascimento,
          requiredField: false,
          label: 'Data de nascimento corrigida',
        );

      case 'Telefone':
        return CampoTelefone(
          controller: _ctrlTelefone,
          requiredField: false,
          label: 'Telefone corrigido',
        );

      case 'Nome do responsável':
        return CampoNomeResponsavel(
          controller: _ctrlNomeResponsavel,
          label: 'Nome do responsável corrigido',
        );

      case 'Telefone do responsável':
        return CampoTelefoneResponsavel(
          controller: _ctrlTelefoneResponsavel,
          label: 'Telefone do responsável corrigido',
        );

      case 'Contato de emergência':
        return CampoNomeContatoEmergencia(
          controller: _ctrlContatoEmergencia,
          label: 'Nome do contato de emergência corrigido',
        );

      case 'Telefone do contato de emergência':
        return CampoTelefoneContatoEmergencia(
          controller: _ctrlTelefoneContatoEmergencia,
          label: 'Telefone do contato de emergência corrigido',
        );

      case 'CID':
        // CampoCid — não valida, não sugere diagnóstico, não pede upload.
        return CampoCid(
          controller: _ctrlCid,
          requiredField: false,
          label: 'CID corrigido',
        );

      // --- Campos com Dropdown da Central ---
      case 'Gênero':
        return CampoGenero(
          value: _genero,
          requiredField: false,
          label: 'Gênero corrigido',
          onChanged: (val) => setState(() => _genero = val),
        );

      case 'Raça / Cor':
        return CampoRacaCor(
          value: _racaCor,
          requiredField: false,
          label: 'Raça / Cor corrigida',
          onChanged: (val) => setState(() => _racaCor = val),
        );

      case 'Tipo sanguíneo':
        return CampoTipoSanguineo(
          value: _tipoSanguineo,
          requiredField: false,
          label: 'Tipo sanguíneo corrigido',
          onChanged: (val) => setState(() => _tipoSanguineo = val),
        );

      // --- Estado e Cidade: carregam via IBGE internamente ---
      case 'Estado':
        return CampoEstado(
          value: _estadoCorrecao,
          requiredField: false,
          label: 'Estado corrigido',
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
          label: 'Cidade corrigida',
          onChanged: (val) => setState(() => _cidadeCorrecao = val),
        );

      default:
        // Fallback seguro — nunca deve ser atingido com a lista atual.
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------------
  // Campo de Observações — geral, opcional
  // -------------------------------------------------------------------
  Widget _buildCampoObservacoes() {
    return DsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrlObservacoes,
            maxLines: 4,
            minLines: 3,
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Adicione uma observação se quiser explicar melhor a correção.',
              hintStyle: DsTipografia.body.copyWith(
                color: DsCores.textSecondary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DsRaios.md),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DsRaios.md),
                borderSide: BorderSide(
                  color: DsCores.correcao.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
}
