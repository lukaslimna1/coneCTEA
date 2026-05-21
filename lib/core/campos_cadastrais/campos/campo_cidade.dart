// A central padroniza campos cadastrais do produto.
// Estados e cidades devem vir da API pública do IBGE.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';
import 'package:conectea/core/servicos/localizacao/localizacao_service.dart';

/// Campo de formulário padronizado tipo Dropdown Pesquisável para Cidade.
///
/// Carrega a lista de cidades internamente via API pública do IBGE
/// para a UF informada em [estadoUf].
/// Quando [estadoUf] for nulo, o campo fica desabilitado.
/// Telas não precisam passar lista de items — apenas value, estadoUf e onChanged.
/// Não persiste dados, não chama banco, não usa dado de usuário.
class CampoCidade extends StatefulWidget {
  final String? value;

  /// Sigla da UF selecionada em CampoEstado.
  /// Quando null, o campo fica desabilitado com hint "Escolha o estado".
  final String? estadoUf;

  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? searchHint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoCidade({
    super.key,
    this.value,
    this.estadoUf,
    this.onChanged,
    this.enabled = true,
    this.requiredField = true,
    this.label,
    this.hint,
    this.searchHint,
    this.helperText,
    this.semanticsLabel,
    this.validator,
  });

  @override
  State<CampoCidade> createState() => _CampoCidadeState();
}

class _CampoCidadeState extends State<CampoCidade> {
  final IbgeLocalizacaoService _ibgeService = IbgeLocalizacaoService();

  List<String> _cidades = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    if (widget.estadoUf != null && widget.estadoUf!.isNotEmpty) {
      _carregarCidades(widget.estadoUf!);
    }
  }

  @override
  void didUpdateWidget(CampoCidade oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega cidades se a UF mudou.
    if (widget.estadoUf != oldWidget.estadoUf) {
      setState(() {
        _cidades = [];
        _carregando = false;
      });
      if (widget.estadoUf != null && widget.estadoUf!.isNotEmpty) {
        _carregarCidades(widget.estadoUf!);
      }
    }
  }

  Future<void> _carregarCidades(String uf) async {
    setState(() {
      _carregando = true;
      _cidades = [];
    });
    try {
      final resultado = await _ibgeService.buscarCidadesPorUf(uf);
      if (mounted) {
        setState(() {
          _cidades = resultado.map((c) => c.nome).toList();
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar as cidades.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String labelTexto =
        '${widget.label ?? 'Cidade'}${widget.requiredField ? ' *' : ''}';

    final bool semEstado =
        widget.estadoUf == null || widget.estadoUf!.isEmpty;

    final String hintEfetivo;
    if (semEstado) {
      hintEfetivo = widget.hint ?? 'Escolha o estado';
    } else if (_carregando) {
      hintEfetivo = 'Carregando cidades...';
    } else {
      hintEfetivo = widget.hint ?? 'Selecione';
    }

    final bool habilitado =
        widget.enabled && !semEstado && !_carregando;

    return DsSearchableDropdown(
      label: labelTexto,
      value: widget.value,
      items: _cidades,
      onChanged: widget.onChanged,
      enabled: habilitado,
      hint: hintEfetivo,
      searchHint: widget.searchHint ?? 'Buscar cidade...',
      helperText: widget.helperText,
      icon: PhosphorIconsRegular.mapPin,
      semanticsLabel: widget.semanticsLabel,
      validator: widget.validator ??
          (widget.requiredField
              ? (value) => ValidadoresCadastrais.campoObrigatorio(
                    value,
                    mensagem: 'Cidade é obrigatória',
                  )
              : null),
    );
  }
}
