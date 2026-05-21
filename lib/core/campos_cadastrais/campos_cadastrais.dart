// A central padroniza campos cadastrais do produto.
// Ela não salva, não busca e não chama serviços.
// DS V2 continua sendo a camada visual pura.
// Lógica de fluxo permanece nas telas/features.

// Barrel file da Central de Campos Cadastrais do ConeCTEA.
// Fornece acesso unificado a opções, formatadores, validadores e todos os campos padronizados.
export 'opcoes/opcoes_cadastrais.dart';
export 'formatadores/formatadores_cadastrais.dart';
export 'validadores/validadores_cadastrais.dart';

// Campos baseados em DsInput
export 'campos/campo_nome_completo.dart';
export 'campos/campo_nome_social.dart';
export 'campos/campo_cpf.dart';
export 'campos/campo_email.dart';
export 'campos/campo_telefone.dart';
export 'campos/campo_data_nascimento.dart';
export 'campos/campo_nome_instituicao.dart';
export 'campos/campo_cid.dart';
export 'campos/campo_nome_responsavel.dart';
export 'campos/campo_telefone_responsavel.dart';
export 'campos/campo_nome_contato_emergencia.dart';
export 'campos/campo_telefone_contato_emergencia.dart';

// Campos baseados em DsDropdown
export 'campos/campo_genero.dart';
export 'campos/campo_raca_cor.dart';
export 'campos/campo_indicacao_instituicao.dart';
export 'campos/campo_tipo_sanguineo.dart';

// Campos baseados em DsSearchableDropdown
export 'campos/campo_estado.dart';
export 'campos/campo_cidade.dart';
