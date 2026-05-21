import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'modelos/ibge_estado.dart';
import 'modelos/ibge_cidade.dart';

/// Serviço de apoio a formulários para busca de Estados e Cidades usando a API pública do IBGE.
///
/// Este serviço não persiste dados locais ou remotos.
class IbgeLocalizacaoService {
  final http.Client _client;

  IbgeLocalizacaoService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca a lista de estados brasileiros da API do IBGE ordenados por nome.
  Future<List<IbgeEstado>> buscarEstados() async {
    try {
      final response = await _client.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is List) {
          final estados = decoded
              .map((item) => IbgeEstado.fromJson(item as Map<String, dynamic>))
              .toList();

          // Ordenação local para garantir a consistência alfabética
          estados.sort((a, b) => a.nome.compareTo(b.nome));
          return estados;
        }
      }
      throw Exception('Resposta inesperada da API (Status: ${response.statusCode})');
    } catch (e) {
      debugPrint('Erro ao buscar estados do IBGE: $e');
      throw Exception('Não foi possível carregar a lista de estados.');
    }
  }

  /// Busca a lista de cidades de uma determinada Unidade Federativa (UF) pela sigla.
  Future<List<IbgeCidade>> buscarCidadesPorUf(String uf) async {
    final cleanUf = uf.trim();
    if (cleanUf.isEmpty) {
      return [];
    }

    try {
      final response = await _client.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$cleanUf/municipios?orderBy=nome'),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is List) {
          final cidades = decoded
              .map((item) => IbgeCidade.fromJson(item as Map<String, dynamic>))
              .toList();

          // Ordenação local para garantir a consistência alfabética
          cidades.sort((a, b) => a.nome.compareTo(b.nome));
          return cidades;
        }
      }
      throw Exception('Resposta inesperada da API (Status: ${response.statusCode})');
    } catch (e) {
      debugPrint('Erro ao buscar cidades do IBGE para a UF $cleanUf: $e');
      throw Exception('Não foi possível carregar a lista de cidades.');
    }
  }
}
