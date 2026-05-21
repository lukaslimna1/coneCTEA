// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

/// Listas constantes de opções para dropdowns cadastrais.
class OpcoesCadastrais {
  /// Opções de confirmação/indicação (Sim ou Não)
  static const List<String> simNao = [
    'Não',
    'Sim',
  ];

  /// Opções de Gênero
  static const List<String> genero = [
    'Feminino',
    'Masculino',
    'Não binário',
    'Outro',
    'Prefiro não informar',
  ];

  /// Opções de Raça ou Cor
  static const List<String> racaCor = [
    'Branca',
    'Preta',
    'Parda',
    'Amarela',
    'Indígena',
    'Prefiro não informar',
  ];

  /// Opções de Tipo Sanguíneo
  static const List<String> tipoSanguineo = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Não sei',
    'Prefiro não informar',
  ];
}
