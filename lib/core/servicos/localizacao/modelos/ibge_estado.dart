/// Modelo que representa um estado retornado pela API do IBGE.
class IbgeEstado {
  final String nome;
  final String sigla;

  const IbgeEstado({
    required this.nome,
    required this.sigla,
  });

  /// Cria uma instância a partir de um JSON retornado pela API do IBGE.
  factory IbgeEstado.fromJson(Map<String, dynamic> json) {
    return IbgeEstado(
      nome: json['nome']?.toString() ?? '',
      sigla: json['sigla']?.toString() ?? '',
    );
  }
}
