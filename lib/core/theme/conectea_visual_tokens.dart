import 'package:flutter/material.dart';
import 'package:conectea/core/theme/status_visual_tokens.dart';

/// Representa um token visual individual para elementos que não possuem
/// vínculo direto com status de solicitações do fluxo principal.
///
/// O ConeCTEA opera sob duas diretrizes principais de design:
/// 1. Elementos vinculados a status de solicitação (banners, cards de status, pills de fluxo,
///    e botões em estados específicos) DEVEM usar o [StatusVisualTokens].
/// 2. Elementos ou ações gerais de intenção, módulos administrativos e navegação geral
///    sem vínculo direto a status de fluxo DEVEM usar o [ConecteaVisualTokens].
///
/// Status manda quando existe vínculo de estado do fluxo.
/// Intenção/ação manda quando não existe vínculo de status.
class ConecteaVisualToken {
  /// Cor vibrante principal de destaque para o elemento.
  final Color accent;

  /// Cor de fundo translúcida/suave adaptada ao estilo glassmorphism.
  final Color softBackground;

  /// Cor da borda sutil em harmonia com a cor de destaque.
  final Color border;

  /// Cor de fundo do contêiner do ícone em conformidade com o design semântico.
  final Color iconBackground;

  /// Nome legível e semântico do token (ex: "Visualização", "Solicitação").
  final String semanticName;

  /// Descrição detalhada do propósito conceitual do token.
  final String description;

  /// Indicação recomendada de onde e como este token deve ser aplicado.
  final String usage;

  const ConecteaVisualToken({
    required this.accent,
    required this.softBackground,
    required this.border,
    required this.iconBackground,
    required this.semanticName,
    required this.description,
    required this.usage,
  });
}

/// Centraliza os tokens de comunicação visual e de intenção/ação do ConeCTEA.
///
/// Garante que a escolha de cores, bordas e fundos seja governada por semântica,
/// e não decidida de forma ad-hoc ("no olho").
class ConecteaVisualTokens {
  
  // A) Visualização
  // Uso: ver, abrir, acessar, consultar detalhes, visualizar carteirinha.
  static const ConecteaVisualToken visualizacao = ConecteaVisualToken(
    accent: Color(0xFF38BDF8), // Sky Blue brilhante e calmo
    softBackground: Color(0x1338BDF8),
    border: Color(0x2638BDF8),
    iconBackground: Color(0x1F38BDF8),
    semanticName: 'Visualização',
    description: 'Comunica o ato de ver, consultar dados ou abrir informações gerais.',
    usage: 'Botões de ver detalhes, abrir perfis ou consultar dados inalteráveis.',
  );

  // B) Solicitação
  // Uso: solicitar, iniciar pedido, criar requerimento, pedir carteirinha.
  static const ConecteaVisualToken solicitacao = ConecteaVisualToken(
    accent: Color(0xFF22D3EE), // Ciano vibrante ativo
    softBackground: Color(0x1222D3EE),
    border: Color(0x2522D3EE),
    iconBackground: Color(0x1F22D3EE),
    semanticName: 'Solicitação',
    description: 'Comunica a criação de requisições, novos pedidos e requerimentos.',
    usage: 'CTAs de nova solicitação, solicitar renovação ou botão flutuante de criação.',
  );

  // C) Comunicação
  // Uso: mural, avisos, notícias, comunicados.
  static const ConecteaVisualToken comunicacao = ConecteaVisualToken(
    accent: Color(0xFF60A5FA), // Azul informativo
    softBackground: Color(0x1360A5FA),
    border: Color(0x2660A5FA),
    iconBackground: Color(0x1F60A5FA),
    semanticName: 'Comunicação',
    description: 'Comunica a presença de informativos, notícias e mural de novidades.',
    usage: 'Cards de notícias, mural da comunidade e avisos gerais.',
  );

  // D) Suporte
  // Uso: ajuda, atendimento, contato, orientação.
  static const ConecteaVisualToken suporte = ConecteaVisualToken(
    accent: Color(0xFF34D399), // Emerald/Verde calmo de apoio
    softBackground: Color(0x1234D399),
    border: Color(0x2534D399),
    iconBackground: Color(0x1F34D399),
    semanticName: 'Suporte',
    description: 'Comunica ajuda, suporte ao usuário e orientações acolhedoras.',
    usage: 'Botões de fale conosco, seção de dúvidas e orientação de suporte.',
  );

  // E) Segurança
  // Uso: privacidade, senha, LGPD, proteção.
  static const ConecteaVisualToken seguranca = ConecteaVisualToken(
    accent: Color(0xFF6366F1), // Índigo tecnológico
    softBackground: Color(0x136366F1),
    border: Color(0x266366F1),
    iconBackground: Color(0x1F6366F1),
    semanticName: 'Segurança',
    description: 'Comunica proteção de conta, senha forte e conformidade LGPD.',
    usage: 'Modal de LGPD, troca de senhas e dados de proteção da conta.',
  );

  /// Token semântico específico para privacidade e revelar/ocultar dados sensíveis.
  static ConecteaVisualToken get privacidade => seguranca;

  // F) Usuários e Permissões
  // Uso: contas de usuários, controle de cargos e acessos.
  static const ConecteaVisualToken usuariosPermissoes = ConecteaVisualToken(
    accent: Color(0xFF06B6D4), // Cyan/Blue estrutural distinto
    softBackground: Color(0x1206B6D4),
    border: Color(0x2506B6D4),
    iconBackground: Color(0x1F06B6D4),
    semanticName: 'Usuários e Permissões',
    description: 'Comunica gerenciamento de contas, cargos e níveis de acesso.',
    usage: 'Card do Hub de usuários, controle de permissões de cargos admins.',
  );

  // G) Manutenção Técnica
  // Uso: admin_dev, ferramentas de engenharia, manutenção restrita.
  static const ConecteaVisualToken manutencaoTecnica = ConecteaVisualToken(
    accent: Color(0xFFA78BFA), // Roxo dev/violeta vibrante
    softBackground: Color(0x13A78BFA),
    border: Color(0x26A78BFA),
    iconBackground: Color(0x1FA78BFA),
    semanticName: 'Manutenção Técnica',
    description: 'Comunica utilitários internos de desenvolvimento e depuração técnica.',
    usage: 'Módulo de logs dev, depuradores ou console técnico do administrador.',
  );

  // H) Gestão de Carteirinhas
  // Uso: painel administrativo de controle de carteirinhas, renovações e status.
  static const ConecteaVisualToken gestaoCarteirinhas = ConecteaVisualToken(
    accent: Color(0xFF14D9D0), // Ciano institucional do ConeCTEA
    softBackground: Color(0x1214D9D0),
    border: Color(0x2514D9D0),
    iconBackground: Color(0x1F14D9D0),
    semanticName: 'Gestão de Carteirinhas',
    description: 'Comunica o painel administrativo de aprovação e emissão de carteirinhas.',
    usage: 'Card administrativo de solicitações de carteirinhas.',
  );

  // I) Projetos, Programas e Eventos
  // Uso: palestras, ações sociais, oficinas e inscrições gerais.
  static const ConecteaVisualToken projetosProgramasEventos = ConecteaVisualToken(
    accent: Color(0xFFFBBF24), // Amber brilhante
    softBackground: Color(0x13FBBF24),
    border: Color(0x26FBBF24),
    iconBackground: Color(0x1FFBBF24),
    semanticName: 'Projetos, Programas e Eventos',
    description: 'Comunica ações sociais, eventos comunitários e projetos da instituição.',
    usage: 'Card de eventos, palestras e inscrições comunitárias.',
  );

  // J) Consultas com Profissionais
  // Uso: agendamentos e atendimento de especialistas parceiros.
  static const ConecteaVisualToken consultasProfissionais = ConecteaVisualToken(
    accent: Color(0xFF10B981), // Emerald Saúde/Atendimento
    softBackground: Color(0x1210B981),
    border: Color(0x2510B981),
    iconBackground: Color(0x1F10B981),
    semanticName: 'Consultas com Profissionais',
    description: 'Comunica a busca e agendamento de consultas com profissionais de saúde parceiros.',
    usage: 'Card de médicos, dentistas, psicólogos e terapeutas parceiros.',
  );

  // K) Restrição
  // Mapeado a partir do StatusVisualTokens.fromStatus('rejected') para manter consistência semântica de restrição.
  static ConecteaVisualToken get restricao {
    final rejected = StatusVisualTokens.fromStatus('rejected');
    return ConecteaVisualToken(
      accent: rejected.primary,
      softBackground: rejected.pillBackground,
      border: rejected.pillBorder,
      iconBackground: rejected.pillBackground,
      semanticName: 'Restrição',
      description: 'Comunica acessos restritos, bloqueios por cargo ou ações indisponíveis.',
      usage: 'Mensagem de barreira de acesso, badges de restrito ou cards travados.',
    );
  }

  // L) Em Breve
  // Representa um módulo planejado ou indisponível temporariamente.
  static const ConecteaVisualToken emBreve = ConecteaVisualToken(
    accent: Color(0xFF94A3B8), // Slate neutro
    softBackground: Color(0x1094A3B8),
    border: Color(0x1F94A3B8),
    iconBackground: Color(0x1894A3B8),
    semanticName: 'Em Breve',
    description: 'Comunica novos recursos indisponíveis sem sugerir erro ou restrição.',
    usage: 'Cards desabilitados temporariamente por desenvolvimento futuro.',
  );
}
