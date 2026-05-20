import 'package:flutter/material.dart';

/// Token visual individual para áreas, intenções e ações que NÃO possuem
/// vínculo direto com status de carteirinha, solicitação ou fluxo administrativo.
///
/// Para status, usar DsTokenStatus.
class DsTokenVisual {
  /// Chave técnica estável do token.
  final String key;

  /// Nome semântico legível.
  final String semanticName;

  /// Descrição detalhada do propósito do token.
  final String description;

  /// Cor vibrante principal de destaque.
  final Color accent;

  /// Cor translúcida suave para selos e superfícies leves.
  final Color softBackground;

  /// Cor sutil de borda.
  final Color border;

  /// Cor de fundo para molduras de ícone.
  final Color iconBackground;

  const DsTokenVisual({
    required this.key,
    required this.semanticName,
    required this.description,
    required this.accent,
    required this.softBackground,
    required this.border,
    required this.iconBackground,
  });
}

/// Tokens visuais e de intenção do Design System V2.
///
/// Usados para áreas e ações gerais do app: Conta, Segurança, Privacidade,
/// Termos, Carteirinha, Suporte, Institucional, Administração etc.
///
/// NÃO usar para status de carteirinha ou solicitação.
class DsTokensVisuais {
  DsTokensVisuais._();

  static const DsTokenVisual conta = DsTokenVisual(
    key: 'conta',
    semanticName: 'Conta',
    description: 'Relacionado à conta do usuário e dados pessoais.',
    accent: Color(0xFF38BDF8),
    softBackground: Color(0x1438BDF8),
    border: Color(0x2638BDF8),
    iconBackground: Color(0x1F38BDF8),
  );

  static const DsTokenVisual seguranca = DsTokenVisual(
    key: 'seguranca',
    semanticName: 'Segurança',
    description: 'Relacionado à segurança da conta, senhas e chaves de acesso.',
    accent: Color(0xFF6366F1),
    softBackground: Color(0x146366F1),
    border: Color(0x266366F1),
    iconBackground: Color(0x1F6366F1),
  );

  static const DsTokenVisual privacidade = DsTokenVisual(
    key: 'privacidade',
    semanticName: 'Privacidade',
    description: 'Relacionado à LGPD e proteção de dados pessoais.',
    accent: Color(0xFF0D9488),
    softBackground: Color(0x140D9488),
    border: Color(0x260D9488),
    iconBackground: Color(0x1F0D9488),
  );

  static const DsTokenVisual termos = DsTokenVisual(
    key: 'termos',
    semanticName: 'Termos',
    description: 'Termos de Uso, políticas e consentimentos.',
    accent: Color(0xFF8B5CF6),
    softBackground: Color(0x148B5CF6),
    border: Color(0x268B5CF6),
    iconBackground: Color(0x1F8B5CF6),
  );

  static const DsTokenVisual carteirinha = DsTokenVisual(
    key: 'carteirinha',
    semanticName: 'Carteirinha',
    description: 'Identificação e emissão da carteirinha digital ConeCTEA.',
    accent: Color(0xFF14D9D0),
    softBackground: Color(0x1414D9D0),
    border: Color(0x2614D9D0),
    iconBackground: Color(0x1F14D9D0),
  );

  static const DsTokenVisual suporte = DsTokenVisual(
    key: 'suporte',
    semanticName: 'Suporte',
    description: 'Canais oficiais de contato, suporte e ajuda.',
    accent: Color(0xFF3B82F6),
    softBackground: Color(0x143B82F6),
    border: Color(0x263B82F6),
    iconBackground: Color(0x1F3B82F6),
  );

  static const DsTokenVisual institucional = DsTokenVisual(
    key: 'institucional',
    semanticName: 'Institucional',
    description: 'Informações sobre o ConeCTEA, Família TEA Bauru e rede social da instituição.',
    accent: Color(0xFFFBBF24),
    softBackground: Color(0x14FBBF24),
    border: Color(0x26FBBF24),
    iconBackground: Color(0x1FFBBF24),
  );

  static const DsTokenVisual visualizacao = DsTokenVisual(
    key: 'visualizacao',
    semanticName: 'Visualização',
    description: 'Visualização de dados informativos e leitura.',
    accent: Color(0xFF38BDF8),
    softBackground: Color(0x1438BDF8),
    border: Color(0x2638BDF8),
    iconBackground: Color(0x1F38BDF8),
  );

  static const DsTokenVisual solicitacao = DsTokenVisual(
    key: 'solicitacao',
    semanticName: 'Solicitação',
    description: 'Início de requerimentos, renovações e formulários.',
    accent: Color(0xFF22D3EE),
    softBackground: Color(0x1422D3EE),
    border: Color(0x2622D3EE),
    iconBackground: Color(0x1F22D3EE),
  );

  static const DsTokenVisual comunicacao = DsTokenVisual(
    key: 'comunicacao',
    semanticName: 'Comunicação',
    description: 'Avisos, notícias e mensagens institucionais.',
    accent: Color(0xFF60A5FA),
    softBackground: Color(0x1460A5FA),
    border: Color(0x2660A5FA),
    iconBackground: Color(0x1F60A5FA),
  );

  static const DsTokenVisual restricao = DsTokenVisual(
    key: 'restricao',
    semanticName: 'Restrição',
    description: 'Bloqueios administrativos, perfis travados e recursos limitados.',
    accent: Color(0xFFE11D48),
    softBackground: Color(0x14E11D48),
    border: Color(0x30E11D48),
    iconBackground: Color(0x1FE11D48),
  );

  static const DsTokenVisual manutencao = DsTokenVisual(
    key: 'manutencao',
    semanticName: 'Manutenção',
    description: 'Utilitários técnicos, rotinas internas e depuração.',
    accent: Color(0xFFA78BFA),
    softBackground: Color(0x14A78BFA),
    border: Color(0x26A78BFA),
    iconBackground: Color(0x1FA78BFA),
  );

  static const DsTokenVisual admin = DsTokenVisual(
    key: 'admin',
    semanticName: 'Administrador',
    description: 'Ferramentas exclusivas de controle administrativo.',
    accent: Color(0xFF7C3AED),
    softBackground: Color(0x147C3AED),
    border: Color(0x267C3AED),
    iconBackground: Color(0x1F7C3AED),
  );

  static const DsTokenVisual usuario = DsTokenVisual(
    key: 'usuario',
    semanticName: 'Usuário',
    description: 'Controle de contas gerais, membros e dependentes.',
    accent: Color(0xFF06B6D4),
    softBackground: Color(0x1406B6D4),
    border: Color(0x2606B6D4),
    iconBackground: Color(0x1F06B6D4),
  );

  static const DsTokenVisual sucesso = DsTokenVisual(
    key: 'sucesso',
    semanticName: 'Sucesso',
    description: 'Fluxo positivo, validações bem-sucedidas ou conquistas.',
    accent: Color(0xFF34D399),
    softBackground: Color(0x1434D399),
    border: Color(0x2634D399),
    iconBackground: Color(0x1F34D399),
  );

  static const DsTokenVisual alerta = DsTokenVisual(
    key: 'alerta',
    semanticName: 'Alerta',
    description: 'Atenção, pendência temporária ou orientação importante.',
    accent: Color(0xFFF59E0B),
    softBackground: Color(0x14F59E0B),
    border: Color(0x30F59E0B),
    iconBackground: Color(0x1FF59E0B),
  );

  static const DsTokenVisual perigo = DsTokenVisual(
    key: 'perigo',
    semanticName: 'Perigo',
    description: 'Erros graves, exclusões irreversíveis ou avisos críticos.',
    accent: Color(0xFFEF4444),
    softBackground: Color(0x14EF4444),
    border: Color(0x30EF4444),
    iconBackground: Color(0x1FEF4444),
  );

  static const DsTokenVisual fallback = DsTokenVisual(
    key: 'fallback',
    semanticName: 'Padrão',
    description: 'Token visual neutro para contextos não identificados.',
    accent: Color(0xFF94A3B8),
    softBackground: Color(0x1494A3B8),
    border: Color(0x2694A3B8),
    iconBackground: Color(0x1F94A3B8),
  );

  /// Retorna um token visual a partir de uma chave técnica.
  static DsTokenVisual fromKey(String? key) {
    final normalized = _normalize(key);
    switch (normalized) {
      case 'conta':
      case 'account':
      case 'perfil':
      case 'profile':
        return conta;
      case 'seguranca':
      case 'segurança':
      case 'security':
        return seguranca;
      case 'privacidade':
      case 'privacy':
      case 'dados':
      case 'data':
        return privacidade;
      case 'termos':
      case 'terms':
      case 'legal':
      case 'consentimentos':
      case 'consents':
        return termos;
      case 'carteirinha':
      case 'card':
      case 'digital_card':
        return carteirinha;
      case 'suporte':
      case 'support':
      case 'ajuda':
      case 'help':
        return suporte;
      case 'institucional':
      case 'institutional':
      case 'sobre':
      case 'about':
      case 'familia_tea':
      case 'família_tea':
        return institucional;
      case 'visualizacao':
      case 'visualização':
      case 'view':
      case 'read':
        return visualizacao;
      case 'solicitacao':
      case 'solicitação':
      case 'request':
      case 'requests':
      case 'renovacao':
      case 'renovação':
        return solicitacao;
      case 'comunicacao':
      case 'comunicação':
      case 'communication':
      case 'notificacao':
      case 'notificação':
      case 'notification':
      case 'notifications':
        return comunicacao;
      case 'restricao':
      case 'restrição':
      case 'restricted':
      case 'locked':
        return restricao;
      case 'manutencao':
      case 'manutenção':
      case 'maintenance':
      case 'debug':
        return manutencao;
      case 'admin':
      case 'administrador':
        return admin;
      case 'usuario':
      case 'usuário':
      case 'user':
      case 'users':
      case 'membro':
      case 'member':
      case 'dependente':
      case 'dependent':
        return usuario;
      case 'sucesso':
      case 'success':
      case 'ok':
        return sucesso;
      case 'alerta':
      case 'warning':
      case 'attention':
      case 'atencao':
      case 'atenção':
        return alerta;
      case 'perigo':
      case 'danger':
      case 'error':
      case 'erro':
      case 'critical':
        return perigo;
      default:
        return fallback;
    }
  }

  static String _normalize(String? key) {
    return (key ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
