import 'package:flutter/material.dart';

/// Representa um token visual individual para elementos e intenções
/// que não possuem vínculo direto com status de fluxo ou solicitações.
class DsTokenVisual {
  /// Nome semântico do token (ex: "Visualização", "Segurança").
  final String semanticName;

  /// Descrição textual detalhando o propósito do token.
  final String description;

  /// Cor vibrante principal de destaque do token.
  final Color accent;

  /// Cor translúcida para fundo do card ou container.
  final Color softBackground;

  /// Cor sutil da borda.
  final Color border;

  /// Cor de fundo para o container do ícone.
  final Color iconBackground;

  const DsTokenVisual({
    required this.semanticName,
    required this.description,
    required this.accent,
    required this.softBackground,
    required this.border,
    required this.iconBackground,
  });
}

/// Centraliza os tokens de comunicação visual e de intenção/ação do Design System V2.
class DsTokensVisuais {
  DsTokensVisuais._();

  static const DsTokenVisual conta = DsTokenVisual(
    semanticName: 'Conta',
    description: 'Relacionado à conta do usuário e dados pessoais.',
    accent: Color(0xFF38BDF8),
    softBackground: Color(0x1438BDF8),
    border: Color(0x2638BDF8),
    iconBackground: Color(0x1F38BDF8),
  );

  static const DsTokenVisual seguranca = DsTokenVisual(
    semanticName: 'Segurança',
    description: 'Relacionado à segurança da conta, senhas e chaves de acesso.',
    accent: Color(0xFF6366F1),
    softBackground: Color(0x146366F1),
    border: Color(0x266366F1),
    iconBackground: Color(0x1F6366F1),
  );

  static const DsTokenVisual privacidade = DsTokenVisual(
    semanticName: 'Privacidade',
    description: 'Conformidade LGPD e dados de proteção da privacidade.',
    accent: Color(0xFF0D9488),
    softBackground: Color(0x140D9488),
    border: Color(0x260D9488),
    iconBackground: Color(0x1F0D9488),
  );

  static const DsTokenVisual termos = DsTokenVisual(
    semanticName: 'Termos',
    description: 'Termos de Uso, Políticas de Privacidade e Termos de Consentimento.',
    accent: Color(0xFF8B5CF6),
    softBackground: Color(0x148B5CF6),
    border: Color(0x268B5CF6),
    iconBackground: Color(0x1F8B5CF6),
  );

  static const DsTokenVisual carteirinha = DsTokenVisual(
    semanticName: 'Carteirinha',
    description: 'Identificação e emissão do cartão digital ConeCTEA.',
    accent: Color(0xFF14D9D0),
    softBackground: Color(0x1414D9D0),
    border: Color(0x2614D9D0),
    iconBackground: Color(0x1F14D9D0),
  );

  static const DsTokenVisual suporte = DsTokenVisual(
    semanticName: 'Suporte',
    description: 'Canais oficiais de contato, suporte e ajuda.',
    accent: Color(0xFF3B82F6),
    softBackground: Color(0x143B82F6),
    border: Color(0x263B82F6),
    iconBackground: Color(0x1F3B82F6),
  );

  static const DsTokenVisual visualizacao = DsTokenVisual(
    semanticName: 'Visualização',
    description: 'Visualização de dados informativos e leitura.',
    accent: Color(0xFF38BDF8),
    softBackground: Color(0x1338BDF8),
    border: Color(0x2638BDF8),
    iconBackground: Color(0x1F38BDF8),
  );

  static const DsTokenVisual solicitacao = DsTokenVisual(
    semanticName: 'Solicitação',
    description: 'Início de novos requerimentos, renovações e formulários.',
    accent: Color(0xFF22D3EE),
    softBackground: Color(0x1222D3EE),
    border: Color(0x2522D3EE),
    iconBackground: Color(0x1F22D3EE),
  );

  static const DsTokenVisual comunicacao = DsTokenVisual(
    semanticName: 'Comunicação',
    description: 'Mural de avisos, notícias e mensagens institucionais.',
    accent: Color(0xFF60A5FA),
    softBackground: Color(0x1360A5FA),
    border: Color(0x2660A5FA),
    iconBackground: Color(0x1F60A5FA),
  );

  static const DsTokenVisual restricao = DsTokenVisual(
    semanticName: 'Restrição',
    description: 'Bloqueios administrativos, perfis travados e recursos limitados.',
    accent: Color(0xFFE11D48),
    softBackground: Color(0x13E11D48),
    border: Color(0x30E11D48),
    iconBackground: Color(0x1FE11D48),
  );

  static const DsTokenVisual manutencao = DsTokenVisual(
    semanticName: 'Manutenção',
    description: 'Utilitários técnicos do desenvolvedor e depuração.',
    accent: Color(0xFFA78BFA),
    softBackground: Color(0x13A78BFA),
    border: Color(0x26A78BFA),
    iconBackground: Color(0x1FA78BFA),
  );

  static const DsTokenVisual admin = DsTokenVisual(
    semanticName: 'Administrador',
    description: 'Ferramentas exclusivas de controle dos administradores.',
    accent: Color(0xFF7C3AED),
    softBackground: Color(0x157C3AED),
    border: Color(0x287C3AED),
    iconBackground: Color(0x207C3AED),
  );

  static const DsTokenVisual usuario = DsTokenVisual(
    semanticName: 'Usuário',
    description: 'Controle de contas gerais de membros e dependentes.',
    accent: Color(0xFF06B6D4),
    softBackground: Color(0x1206B6D4),
    border: Color(0x2506B6D4),
    iconBackground: Color(0x1F06B6D4),
  );

  static const DsTokenVisual sucesso = DsTokenVisual(
    semanticName: 'Sucesso',
    description: 'Fluxo positivo, validações bem-sucedidas ou conquistas.',
    accent: Color(0xFF34D399),
    softBackground: Color(0x1234D399),
    border: Color(0x2534D399),
    iconBackground: Color(0x1F34D399),
  );

  static const DsTokenVisual alerta = DsTokenVisual(
    semanticName: 'Alerta',
    description: 'Atenção, pendência temporária de dados ou orientações importantes.',
    accent: Color(0xFFF59E0B),
    softBackground: Color(0x13F59E0B),
    border: Color(0x30F59E0B),
    iconBackground: Color(0x1FF59E0B),
  );

  static const DsTokenVisual perigo = DsTokenVisual(
    semanticName: 'Perigo',
    description: 'Erros graves, exclusão irreversível de conta ou avisos críticos.',
    accent: Color(0xFFEF4444),
    softBackground: Color(0x13EF4444),
    border: Color(0x30EF4444),
    iconBackground: Color(0x1FEF4444),
  );
}
