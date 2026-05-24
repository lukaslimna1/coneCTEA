import 'package:flutter/material.dart';

// =============================================================================
// DESIGN SYSTEM V2 — CORES OFICIAIS
//
// Este arquivo é o caminho único de cores da DS V2 do ConeCTEA.
//
// Responsabilidades:
//   DsCorVisual  → Modelo semântico que representa uma área, ação ou contexto
//                  visual do app (ex: conta, segurança, carteirinha).
//   DsCores      → Contém cores estruturais (fundos, textos, bordas, inputs)
//                  e os tokens DsCorVisual para cada intenção visual.
//   DsTokenStatus → Arquivo separado. Representa status persistidos de
//                   carteirinha e solicitação (ativa, em análise, vencida…).
//                   Não usar DsCorVisual para status de carteirinha.
//
// Regra de uso:
//   - Cores estruturais → DsCores.background, DsCores.textPrimary etc.
//   - Intenções visuais → DsCores.sucesso.accent, DsCores.privacidade.border…
//   - Status de carteirinha / solicitação → DsTokenStatus.fromStatus(…)
//   - Não criar outro arquivo de cores para intenções visuais.
// =============================================================================

// -----------------------------------------------------------------------------
// MODELO SEMÂNTICO — DsCorVisual
//
// Representa uma intenção, área ou ação visual do app.
// Cada token possui quatro slots de cor derivados do mesmo accent:
//   accent          → Cor vibrante principal (ícones, bordas ativas, CTAs).
//   softBackground  → Fundo translúcido suave para cards e blocos semânticos.
//   border          → Borda semântica sutil.
//   iconBackground  → Fundo da moldura de ícone (DsMolduraIcone).
//
// Importante:
//   Este modelo NÃO representa status de carteirinha ou solicitação.
//   Para estados administrativos persistidos, usar DsTokenStatus.
// -----------------------------------------------------------------------------

class DsCorVisual {
  /// Chave técnica estável (usada por visualFromKey).
  final String key;

  /// Nome semântico legível para humanos.
  final String semanticName;

  /// Descrição do propósito visual deste token.
  final String description;

  /// Cor vibrante principal.
  final Color accent;

  /// Fundo translúcido suave.
  final Color softBackground;

  /// Borda semântica sutil.
  final Color border;

  /// Fundo para molduras de ícone (DsMolduraIcone).
  final Color iconBackground;

  const DsCorVisual({
    required this.key,
    required this.semanticName,
    required this.description,
    required this.accent,
    required this.softBackground,
    required this.border,
    required this.iconBackground,
  });
}

// =============================================================================
// DsCores — Paleta oficial do Design System V2
// =============================================================================

class DsCores {
  DsCores._();

  // ---------------------------------------------------------------------------
  // SUPERFÍCIES E GLASS — Night Blue / Dark Glass
  //
  // Fundos e camadas de profundidade da paleta Night Blue.
  // Usar para Scaffold, cards, overlays e glassmorphism.
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFF071326);
  static const Color surface = Color(0xFF0B1D3A);
  static const Color surfaceElevated = Color(0xFF102A4C);
  static const Color surfaceCard = Color(0xFF10315E);
  static const Color surfaceCardHover = Color(0xFF163F72);
  static const Color glass = Color(0x990B1D3A);
  static const Color glassStrong = Color(0xD90B1D3A);

  /// Fundo escuro para molduras de ícone (DsMolduraIcone).
  /// Valor próximo de #020617 — quase preto com leve tint azul noturno.
  static const Color iconFrameBackground = Color(0xFF020617);

  // ---------------------------------------------------------------------------
  // TEXTOS
  //
  // Usar as variantes de acordo com a hierarquia de leitura:
  //   textPrimary   → Títulos, rótulos e conteúdo principal.
  //   textSecondary → Descrições, legendas e textos de apoio.
  //   textMuted     → Placeholders, metadados e textos desabilitados.
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFB8C7E6);
  static const Color textMuted = Color(0xFF9FB2D6);

  // ---------------------------------------------------------------------------
  // BORDAS NEUTRAS
  //
  // Para divisórias, cards neutros e containers sem intenção semântica.
  // Para bordas com intenção semântica, usar DsCorVisual.border do token.
  // ---------------------------------------------------------------------------

  static const Color border = Color(0xFF1E4A7A);
  static const Color borderStrong = Color(0xFF2A5B8F);

  // ---------------------------------------------------------------------------
  // INPUTS
  //
  // Tokens exclusivos para campos de texto, dropdowns e buscas.
  // Não reutilizar inputBorder como borda de card — usar DsCores.border.
  // O inputFocusBorder (#7C3AED) usa violeta intencional para feedback de foco.
  // ---------------------------------------------------------------------------

  static const Color inputBackground = Color(0xA60F172A);
  static const Color inputBorder = Color(0x1AFFFFFF);
  static const Color inputFocusBorder = Color(0xFF7C3AED);
  static const Color inputPlaceholder = Color(0x4DB8C7E6);
  static const Color inputIcon = Color(0xFFFFFFFF);
  static const Color inputSuffixIcon = Color(0x80B8C7E6);

  // ---------------------------------------------------------------------------
  // ÍCONES NEUTROS
  //
  // Para ícones sem intenção semântica específica.
  // Ícones com intenção semântica devem usar DsCorVisual.accent do token.
  // ---------------------------------------------------------------------------

  static const Color iconPrimary = Color(0xFFF8FAFC);
  static const Color iconSecondary = Color(0xFFB8C7E6);
  static const Color iconMuted = Color(0xFF8FA3C7);

  // ===========================================================================
  // INTENÇÕES VISUAIS
  //
  // DsCores é o caminho único de cores estruturais e intenções visuais.
  // Cada DsCorVisual representa uma área, ação ou contexto.
  // DsTokenStatus (arquivo separado) é SOMENTE para status de carteirinha.
  // A cor nunca comunica sozinha: texto, ícone e contexto completam a intenção.
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // CONTA TITULAR E VÍNCULOS
  // Conta, usuário e titular são a mesma pessoa no produto.
  // Dependente é separado da conta titular.
  // ---------------------------------------------------------------------------

  /// Conta do usuário titular/responsável, dados cadastrais, perfil e Meus Dados.
  static const DsCorVisual conta = DsCorVisual(
    key: 'conta',
    semanticName: 'Conta',
    description: 'Conta do usuário titular/responsável, dados comuns e perfil.',
    accent: Color(0xFF22D3EE),
    softBackground: Color(0x1422D3EE),
    border: Color(0x2622D3EE),
    iconBackground: Color(0x1F22D3EE),
  );

  /// Mantido por compatibilidade. Novos usos devem preferir [conta].
  static const DsCorVisual usuario = DsCorVisual(
    key: 'usuario',
    semanticName: 'Usuário',
    description: 'Compatibilidade técnica. Representa o mesmo que [conta].',
    accent: Color(0xFF06B6D4),
    softBackground: Color(0x1406B6D4),
    border: Color(0x2606B6D4),
    iconBackground: Color(0x1F06B6D4),
  );

  /// Dependentes vinculados à conta do titular/responsável.
  static const DsCorVisual dependente = DsCorVisual(
    key: 'dependente',
    semanticName: 'Dependente',
    description: 'Dependentes vinculados à conta titular.',
    accent: Color(0xFF818CF8),
    softBackground: Color(0x14818CF8),
    border: Color(0x26818CF8),
    iconBackground: Color(0x1F818CF8),
  );

  // ---------------------------------------------------------------------------
  // DADOS, SEGURANÇA E PRIVACIDADE
  // Dados protegidos é diferente de segurança.
  // ---------------------------------------------------------------------------

  /// Segurança da conta, senhas, autenticação e proteção de acesso.
  static const DsCorVisual seguranca = DsCorVisual(
    key: 'seguranca',
    semanticName: 'Segurança',
    description: 'Segurança da conta, senhas e autenticação.',
    accent: Color(0xFF60A5FA),
    softBackground: Color(0x1460A5FA),
    border: Color(0x2660A5FA),
    iconBackground: Color(0x1F60A5FA),
  );

  /// LGPD, consentimentos e proteção de dados institucionais.
  static const DsCorVisual privacidade = DsCorVisual(
    key: 'privacidade',
    semanticName: 'Privacidade',
    description: 'LGPD, consentimentos e proteção institucional.',
    accent: Color(0xFF0D9488),
    softBackground: Color(0x140D9488),
    border: Color(0x260D9488),
    iconBackground: Color(0x1F0D9488),
  );

  /// Termos de uso, políticas e consentimentos legais.
  static const DsCorVisual termos = DsCorVisual(
    key: 'termos',
    semanticName: 'Termos',
    description: 'Termos de Uso, políticas e consentimentos legais.',
    accent: Color(0xFFA78BFA),
    softBackground: Color(0x14A78BFA),
    border: Color(0x26A78BFA),
    iconBackground: Color(0x1FA78BFA),
  );

  /// CPF, e-mail e dados bloqueados para edição direta.
  static const DsCorVisual dadosProtegidos = DsCorVisual(
    key: 'dadosProtegidos',
    semanticName: 'Dados Protegidos',
    description: 'Dados sensíveis/bloqueados que não podem ser alterados diretamente.',
    accent: Color(0xFF2DD4BF),
    softBackground: Color(0x142DD4BF),
    border: Color(0x262DD4BF),
    iconBackground: Color(0x1F2DD4BF),
  );

  // ---------------------------------------------------------------------------
  // CARTEIRINHA, SOLICITAÇÕES E CORREÇÃO
  // Correção é ação sensível, não status.
  // Carteirinha aqui é área/produto, os status (ativa, vencida...) ficam no DsTokenStatus.
  // ---------------------------------------------------------------------------

  /// Área da carteirinha comunitária, visualização da identidade.
  static const DsCorVisual carteirinha = DsCorVisual(
    key: 'carteirinha',
    semanticName: 'Carteirinha',
    description: 'Área da carteirinha comunitária (não reflete o status).',
    accent: Color(0xFF14D9D0),
    softBackground: Color(0x1414D9D0),
    border: Color(0x2614D9D0),
    iconBackground: Color(0x1F14D9D0),
  );

  /// Início de solicitação neutra, formulário ou requerimento comum.
  static const DsCorVisual solicitacao = DsCorVisual(
    key: 'solicitacao',
    semanticName: 'Solicitação',
    description: 'Início de solicitações e formulários.',
    accent: Color(0xFF38BDF8),
    softBackground: Color(0x1438BDF8),
    border: Color(0x2638BDF8),
    iconBackground: Color(0x1F38BDF8),
  );

  /// Ação de solicitar correção de dados protegidos (exige análise da equipe).
  static const DsCorVisual correcao = DsCorVisual(
    key: 'correcao',
    semanticName: 'Correção',
    description: 'Ação de correção de dados protegidos.',
    accent: Color(0xFFF97316),
    softBackground: Color(0x14F97316),
    border: Color(0x26F97316),
    iconBackground: Color(0x1FF97316),
  );

  @Deprecated('Use a intenção visual correspondente à área de visualização.')
  /// Visualização de dados informativos (token em observação).
  static const DsCorVisual visualizacao = DsCorVisual(
    key: 'visualizacao',
    semanticName: 'Visualização',
    description: 'Token em observação. Prefira herdar a intenção da área.',
    accent: Color(0xFF7DD3FC),
    softBackground: Color(0x147DD3FC),
    border: Color(0x267DD3FC),
    iconBackground: Color(0x1F7DD3FC),
  );

  // ---------------------------------------------------------------------------
  // SUPORTE, COMUNICAÇÃO E INSTITUCIONAL
  // ---------------------------------------------------------------------------

  /// Ajuda, atendimento e canais oficiais de suporte.
  static const DsCorVisual suporte = DsCorVisual(
    key: 'suporte',
    semanticName: 'Suporte',
    description: 'Canais de suporte, ajuda e contato.',
    accent: Color(0xFF3B82F6),
    softBackground: Color(0x143B82F6),
    border: Color(0x263B82F6),
    iconBackground: Color(0x1F3B82F6),
  );

  /// Avisos, mensagens e comunicações gerais do app.
  static const DsCorVisual comunicacao = DsCorVisual(
    key: 'comunicacao',
    semanticName: 'Comunicação',
    description: 'Comunicações informativas e mensagens gerais.',
    accent: Color(0xFF06B6D4),
    softBackground: Color(0x1406B6D4),
    border: Color(0x2606B6D4),
    iconBackground: Color(0x1F06B6D4),
  );

  /// ConeCTEA, Família TEA Bauru e projetos institucionais.
  static const DsCorVisual institucional = DsCorVisual(
    key: 'institucional',
    semanticName: 'Institucional',
    description: 'Sobre o ConeCTEA e Família TEA Bauru.',
    accent: Color(0xFFA78BFA),
    softBackground: Color(0x14A78BFA),
    border: Color(0x26A78BFA),
    iconBackground: Color(0x1FA78BFA),
  );

  // ---------------------------------------------------------------------------
  // PARCERIAS E BENEFÍCIOS
  // ---------------------------------------------------------------------------

  /// Clube de benefícios, parceiros e rede de apoio.
  static const DsCorVisual clube = DsCorVisual(
    key: 'clube',
    semanticName: 'Clube',
    description: 'Clube Família TEA, parceiros e benefícios exclusivos.',
    accent: Color(0xFFEC4899),
    softBackground: Color(0x14EC4899),
    border: Color(0x26EC4899),
    iconBackground: Color(0x1FEC4899),
  );

  // ---------------------------------------------------------------------------
  // ADMINISTRAÇÃO, RESTRIÇÃO E MANUTENÇÃO
  // ---------------------------------------------------------------------------

  /// Painel administrativo e controle interno.
  static const DsCorVisual admin = DsCorVisual(
    key: 'admin',
    semanticName: 'Administrador',
    description: 'Painel administrativo e gestão interna.',
    accent: Color(0xFF8B5CF6),
    softBackground: Color(0x148B5CF6),
    border: Color(0x268B5CF6),
    iconBackground: Color(0x1F8B5CF6),
  );

  /// Acesso restrito, recurso bloqueado ou indisponível.
  static const DsCorVisual restricao = DsCorVisual(
    key: 'restricao',
    semanticName: 'Restrição',
    description: 'Bloqueios e restrições de acesso a recursos.',
    accent: Color(0xFFFBBF24),
    softBackground: Color(0x14FBBF24),
    border: Color(0x26FBBF24),
    iconBackground: Color(0x1FFBBF24),
  );

  /// Versão do app, ambiente e utilitários técnicos.
  static const DsCorVisual manutencao = DsCorVisual(
    key: 'manutencao',
    semanticName: 'Manutenção',
    description: 'Versão do app e utilitários técnicos.',
    accent: Color(0xFF94A3B8),
    softBackground: Color(0x1494A3B8),
    border: Color(0x2694A3B8),
    iconBackground: Color(0x1F94A3B8),
  );

  // ---------------------------------------------------------------------------
  // FEEDBACK DO SISTEMA
  // O perigo é destrutivo. Para outros fluxos, use tokens neutros/sucesso.
  // ---------------------------------------------------------------------------

  /// Salvo, concluído, feedback positivo.
  static const DsCorVisual sucesso = DsCorVisual(
    key: 'sucesso',
    semanticName: 'Sucesso',
    description: 'Ações concluídas com êxito.',
    accent: Color(0xFF34D399),
    softBackground: Color(0x1434D399),
    border: Color(0x2634D399),
    iconBackground: Color(0x1F34D399),
  );

  /// Atenção, aviso importante ou orientação de cuidado.
  static const DsCorVisual alerta = DsCorVisual(
    key: 'alerta',
    semanticName: 'Alerta',
    description: 'Avisos e orientações de atenção.',
    accent: Color(0xFFF59E0B),
    softBackground: Color(0x14F59E0B),
    border: Color(0x26F59E0B),
    iconBackground: Color(0x1FF59E0B),
  );

  /// Exclusão, remoção, erro grave ou ação destrutiva.
  static const DsCorVisual perigo = DsCorVisual(
    key: 'perigo',
    semanticName: 'Perigo',
    description: 'Erros graves, remoções e exclusões irreversíveis.',
    accent: Color(0xFFEF4444),
    softBackground: Color(0x14EF4444),
    border: Color(0x26EF4444),
    iconBackground: Color(0x1FEF4444),
  );

  /// Padrão neutro para fallback.
  static const DsCorVisual fallback = DsCorVisual(
    key: 'fallback',
    semanticName: 'Padrão',
    description: 'Token neutro de fallback.',
    accent: Color(0xFF94A3B8),
    softBackground: Color(0x1494A3B8),
    border: Color(0x2694A3B8),
    iconBackground: Color(0x1F94A3B8),
  );

  // ---------------------------------------------------------------------------
  // GRADIENTES OFICIAIS
  //
  // Gradientes estruturais da paleta Night Blue.
  // Disponíveis para uso em AppBackground, cards e superfícies de destaque.
  // Verificar se estão em uso antes de aplicar em novas telas.
  //   nightGradient       → Fundo principal do app (topLeft→bottomRight azul noturno).
  //   cardGradient        → Variante para cards com leve profundidade extra.
  //   adminGradient       → Gradiente violeta para superfícies administrativas.
  //   carteirinhaGradient → Gradiente teal para a carteirinha digital.
  // ---------------------------------------------------------------------------

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF102A4C), Color(0xFF0B1D3A), Color(0xFF071326)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF102A4C), Color(0xFF0B1D3A), Color(0xFF08162D)],
  );

  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  );

  static const LinearGradient carteirinhaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14D9D0), Color(0xFF0EA8A1)],
  );

  // ---------------------------------------------------------------------------
  // RESOLUÇÃO SEMÂNTICA — visualFromKey
  //
  // Retorna um DsCorVisual a partir de uma chave técnica livre.
  // Usado para resolver chaves dinâmicas (ex: vindas de strings de rota ou model).
  //
  // Quando usar visualFromKey:
  //   - Quando a chave do token não é conhecida em tempo de compilação.
  //   - Quando um componente recebe uma string de área e precisa do token visual.
  //
  // Quando NÃO usar:
  //   - Quando o token é conhecido → usar DsCores.conta, DsCores.seguranca etc.
  //   - Quando é status de carteirinha → usar DsTokenStatus.fromStatus(…).
  //
  // Aliases removidos / corrigidos nesta versão:
  //   dados / data   → Removidos do grupo de privacidade por ambiguidade.
  //                    Podem representar "meus dados" (conta) ou "proteção de
  //                    dados" (privacidade). Agora caem no fallback para forçar
  //                    o uso de chaves explícitas como conta, dados_protegidos
  //                    ou privacidade.
  //   dependente /
  //   dependent      → Agora retornam [dependente] (token próprio criado).
  //                    Antes apontavam para usuario. Atualizado nesta versão.
  // ---------------------------------------------------------------------------

  static DsCorVisual visualFromKey(String? key) {
    final normalized = _normalize(key);

    switch (normalized) {
      // Conta do titular/responsável da conta.
      // No ConeCTEA, titular, responsável e usuário são a mesma pessoa.
      // Atenção: não criar alias "responsavel" como papel formal sem auditoria.
      case 'conta':
      case 'account':
      case 'perfil':
      case 'profile':
      case 'meus_dados':
      case 'my_data':
      case 'account_data':
      case 'usuario':
      case 'usuário':
      case 'user':
      case 'users':
      case 'membro':
      case 'member':
      case 'titular':
      case 'titular_conta':
      case 'account_owner':
      case 'account_holder':
      case 'owner':
      case 'responsavel':
      case 'responsavel_conta':
      case 'responsavel_pela_conta':
        return conta;

      case 'seguranca':
      case 'segurança':
      case 'security':
        return seguranca;

      case 'privacidade':
      case 'privacy':
        return privacidade;
      // Atenção: dados/data foram removidos deste grupo.
      // São aliases ambíguos e agora caem no fallback.
      // Use 'dados_protegidos' para dados bloqueados ou 'conta' para meus dados.

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

      case 'clube':
      case 'club':
      case 'parceiro':
      case 'parceiros':
      case 'partner':
      case 'partners':
      case 'beneficio':
      case 'benefícios':
      case 'benefits':
      case 'apoiador':
      case 'apoiadores':
      case 'supporter':
      case 'supporters':
        return clube;

      case 'admin':
      case 'administrador':
        return admin;

      // Dependentes vinculados à conta titular.
      // Contexto separado de vínculo familiar — não cai em conta.
      case 'dependente':
      case 'dependent':
      case 'dependentes':
      case 'dependents':
      case 'membro_dependente':
      case 'linked_member':
        return dependente;

      case 'dados_protegidos':
      case 'dado_protegido':
      case 'protected_data':
      case 'sensitive_data':
      case 'dados_sensiveis':
      case 'dado_sensivel':
      case 'cpf_email_protegido':
        return dadosProtegidos;

      case 'correcao':
      case 'correção':
      case 'correction':
      case 'corrigir':
      case 'corrigir_dados':
      case 'data_correction':
      case 'solicitar_correcao':
      case 'solicitar_correção':
        return correcao;

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


  // ---------------------------------------------------------------------------
  // NORMALIZAÇÃO PRIVADA
  //
  // Padroniza chaves para comparação no visualFromKey:
  //   - remove espaços externos;
  //   - converte para minúsculas;
  //   - substitui hífens e espaços por underscores.
  // ---------------------------------------------------------------------------

  static String _normalize(String? key) {
    return (key ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
