// A central padroniza campos cadastrais do produto.
// Estados e cidades devem vir da API pública do IBGE.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/campos_cadastrais/validadores/validadores_cadastrais.dart';
import 'package:conectea/core/servicos/localizacao/localizacao_service.dart';

/// Campo de formulário padronizado tipo Dropdown Pesquisável para Estado.
///
/// Carrega a lista de estados internamente via API pública do IBGE.
/// Telas não precisam passar lista de items — apenas value e onChanged.
/// Não persiste dados, não chama banco, não usa dado de usuário.
class CampoEstado extends StatefulWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final bool requiredField;
  final String? label;
  final String? hint;
  final String? searchHint;
  final String? helperText;
  final String? semanticsLabel;
  final String? Function(String?)? validator;

  const CampoEstado({
    super.key,
    this.value,
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
  State<CampoEstado> createState() => _CampoEstadoState();
}

class _CampoEstadoState extends State<CampoEstado> {
  final IbgeLocalizacaoService _ibgeService = IbgeLocalizacaoService();

  List<String> _estados = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarEstados();
  }

  Future<void> _carregarEstados() async {
    setState(() => _carregando = true);
    try {
      final resultado = await _ibgeService.buscarEstados();
      if (mounted) {
        setState(() {
          _estados = resultado.map((e) => e.sigla).toList();
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar os estados.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String labelTexto =
        '${widget.label ?? 'Estado'}${widget.requiredField ? ' *' : ''}';

    final String hintEfetivo = _carregando
        ? 'Carregando estados...'
        : (widget.hint ?? 'Selecione');

    return DsSearchableDropdown(
      label: labelTexto,
      value: widget.value,
      items: _estados,
      onChanged: widget.onChanged,
      enabled: widget.enabled && !_carregando,
      hint: hintEfetivo,
      searchHint: widget.searchHint ?? 'Buscar estado...',
      helperText: widget.helperText,
      icon: PhosphorIconsRegular.mapTrifold,
      semanticsLabel: widget.semanticsLabel,
      validator: widget.validator ??
          (widget.requiredField
              ? (value) => ValidadoresCadastrais.campoObrigatorio(
                    value,
                    mensagem: 'Estado é obrigatório',
                  )
              : null),
    );
  }
}
