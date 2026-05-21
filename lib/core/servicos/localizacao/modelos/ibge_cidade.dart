/// Modelo que representa uma cidade/município retornado pela API do IBGE.
class IbgeCidade {
  final String nome;

  const IbgeCidade({
    required this.nome,
  });

  /// Cria uma instância a partir de um JSON retornado pela API do IBGE.
  factory IbgeCidade.fromJson(Map<String, dynamic> json) {
    return IbgeCidade(
      nome: json['nome']?.toString() ?? '',
    );
  }
}
