# Componentes Premium — ConeCTEA

**App:** 0.7.1-dev
**Documentação:** 4.5.0
**Status:** Desenvolvimento
**Atualizado em:** 19/05/2026

---

## Objetivo

Catalogar e padronizar os componentes de interface premium utilizados no ecossistema ConeCTEA.

---

## Componentes

### 1. PremiumStatusDialog

- **Local:** `lib/core/widgets/premium/premium_status_dialog.dart`
- **Padrão Visual:** Night Blue / Lunar Glass.
- **Função:** Componente centralizado para avisos e informativos, substituindo o `AlertDialog` nativo no fluxo “Ver Motivo / Ver Documento Digital”.
- **Características:**
  - Modal puramente informativo.
  - Botão único `Entendido`.
  - Scroll interno para garantir a leitura de justificativas longas.
  - Adaptado para evitar overflow em telas estreitas (360dp).
  - **Restrições:** Não deve conter botão de suporte ou ações de negócio (separação clara entre visual e regras de negócio).

### 2. PremiumBottomNavBar

- **Local:** `lib/core/widgets/premium/premium_bottom_nav_bar.dart`
- **Padrão Visual:** Lunar Glass / Night Blue.
- **Função:** Barra de navegação inferior unificada para alternância rápida entre módulos.
- **Características de Responsividade e Proteção:**
  - **Efeito de Foco Dinâmico:** O item selecionado cresce horizontalmente revelando sua etiqueta de texto, enquanto os demais exibem apenas o ícone.
  - **Prevenção de RenderFlex:** O label do item ativo é envolvido por `Flexible(fit: FlexFit.loose)` e contido por um `ClipRect` com `TextOverflow.ellipsis`. Isso impede falhas de layout quando a largura interpolada cai temporariamente abaixo de `20px` nas transições.
  - **Compatibilidade do Sistema:** Mantém o padding inferior baseado no `MediaQuery.of(context).padding.bottom` para manter a coerência de espaçamento de forma nativa sob os modos de navegação do SO (gestos ou 3 botões).
  - **Ocultação com Teclado Ativo (Frente 26C.2):** O widget monitora a presença do teclado virtual do sistema via `MediaQuery.viewInsetsOf(context).bottom > 0`. Ao detectar o teclado aberto, a navbar retorna temporariamente um `SizedBox.shrink()`. Isso previne que a barra seja empurrada pelo teclado (teclado tipo IME), evitando sobreposições em formulários e mitigando quebras visuais em aparelhos com navegação física ou virtual clássica por 3 botões (como Motorola Edge Curved).

### 3. CardsDetailsSection (Seção de Detalhes)

- **Local:** `lib/features/cards/widgets/tela_carteirinhas/cards_details_section.dart`
- **Padrão Visual:** Lunar Glass / Night Blue.
- **Função:** Exibe os blocos informativos detalhados da carteirinha selecionada (Validade e Status) e os botões de ação ("VER" e "Girar").
- **Características de Responsividade (Frente 26B.2 / 26B.3-AUD):**
  - **Mitigação Samsung A05/A06:** Paddings e espaçamentos internos compactados para o bloco "Validade" (padding horizontal reduzido para `8dp` e ícone para `14dp`).
  - **Botões Horizontais Proporcionais:** Os botões rápidos de ação são dispostos lado a lado envolvidos por widgets `Expanded`, garantindo proporção exata de 50/50 no espaço disponível. O texto do botão de visualização foi sintetizado para exatamente `"VER"` para prevenir overflows horizontais.
  - **Proteção Antiestouro:** Todos os campos dinâmicos e rótulos curtos utilizam `Expanded`, `maxLines: 1` e `TextOverflow.ellipsis`, blindando a seção contra variações de tamanho de fonte do sistema operacional.

### 4. PremiumButton (Botão Premium)

- **Local:** `lib/core/widgets/premium/premium_button.dart`
- **Padrão Visual:** Lunar Glass com gradientes suaves em tons Sapphire / Night Blue.
- **Função:** Botão de ação premium adaptável.
- **Características:**
  - Encapsulamento de segurança contra trunfações tipográficas.
  - Utiliza `Flexible` em sua estrutura interna para lidar de forma elástica com larguras restritas.

### 5. QuickAccessCard

- **Local:** `lib/features/home/widgets/acesso_rapido/quick_access_card.dart`
- **Padrão Visual:** Lunar Glass com borda gradiente sutil.
- **Função:** Card horizontal compacto para ações de atalho rápido na Home.
- **Características de Responsividade:**
  - **Compactação Estrutural:** Reformulado para remover o widget `Spacer` interno e alturas estáticas rígidas que esticavam a seção.
  - **Controle de Respiro:** Utiliza padding interno de `12px` e termina imediatamente após o botão CTA, deixando um respiro simétrico e proporcional nos emuladores testados.

### 4. HomeMembersSection

- **Local:** `lib/features/home/widgets/membros/home_members_section.dart`
- **Padrão Visual:** Carrossel de avatares com efeito Neon.
- **Função:** Seletor principal para alternar o membro visualizado no Documento Digital.
- **Características de Responsividade:**
  - **Mitigação de Zoom:** Reduz o risco de quebras de layout ou truncações de avatares em cenários recomendados de validação futura com zoom ou fontes maiores.

### 7. Card de Pedidos/Solicitações (Frente 26D.1)

- **Local:** `lib/features/requests/requests_view.dart` (métodos internos do widget)
- **Padrão Visual:** Lunar Glass / Night Blue com acento cromático superior de status.
- **Função:** Card estruturado verticalmente para acompanhamento detalhado de solicitações do usuário.
- **Características de Responsividade e Legibilidade:**
  - **Acento Superior de Status:** Faixa colorida de `4px` colada ao topo do card de acordo com o status (`tokens.primary`), aproveitando de forma limpa o arredondamento de bordas (`radius: 20` e `ClipRRect`) do `PremiumCard` sem a necessidade de customizações extras.
  - **Estrutura Vertical Simétrica:** Organização vertical do conteúdo (pill de status com ícone, título com Expanded e ellipsis, protocolo copiável, data e barra de progresso) para leitura fluida e confortável em viewports estreitas de 360dp.
  - **Cálculo de Progresso Adaptativo:** A barra de progresso dinâmico utiliza `LayoutBuilder` com `constraints.maxWidth` em vez do cálculo global por `MediaQuery`, garantindo que o `AnimatedContainer` se expanda de forma proporcional aos limites físicos do card, eliminando riscos de estouro de RenderFlex lateral em 360dp.
  - **Contador com Badge Dark Glass:** Os badges numéricos dos cabeçalhos das seções foram ajustados para a cor branca suave (`white.withValues(alpha: 0.92)`) sobre uma pill de contorno roxo discreto e fundo Dark Glass, oferecendo excelente contraste sob luz ambiente ou variações de brilho na bancada de testes.

### 8. ConecteaVisualTokens

- **Local:** `lib/core/theme/conectea_visual_tokens.dart`
- **Padrão Visual:** Night Blue Premium (tons Sapphire, Esmeralda, Ciano, Âmbar, Violeta).
- **Função:** Camada centralizada de design semântico e intenções visuais para cards, módulos e ações do Hub que não possuem correspondência direta com o status do banco.
- **Diferença entre tokens:**
  - `StatusVisualTokens`: elementos que possuem vínculo direto com status real do fluxo do banco (ex.: aprovado, rejeitado, pendente).
  - `ConecteaVisualTokens`: elementos sem vínculo direto com status do fluxo, como módulos do Hub, acessos rápidos e rotinas de manutenção.
- **Configurações e cores semânticas estabelecidas:**
  - Gestão de Carteirinhas: `ativo` (ciano/teal institucional, sem uso de roxo/violeta, preservando roxo/violeta para Manutenção Técnica/dev).
  - Projetos/Programas/Eventos: `emBreve` (neutro/slate, comunicando recurso futuro sem aparência de erro ou restrição).
  - Consultas com Profissionais: `emBreve` (neutro/slate, comunicando recurso futuro sem aparência de erro ou restrição).
  - Usuários e Permissões: quando bloqueado, `acessoRestrito` com ruby/rejected/restrição, alinhado à semântica de bloqueio/acesso não permitido; quando acessível, consome o token de usuários/permissões (acessível a admin_master e admin_dev).
  - Manutenção Técnica: `manutencaoTecnica` (roxo/violeta técnico, alinhado à identidade dev; módulo técnico existente restrito a admin_dev).

### 9. ConecteaRoleBadge

- **Local:** `lib/core/widgets/premium/conectea_role_badge.dart`
- **Padrão Visual:** Lunar Glassmorphism elástico.
- **Função:** Componente global responsável por renderizar emblemas de cargo administrativo de forma adaptativa.
- **Variantes de uso:**
  - **Variante Compacta (Home):** exibe apenas o ícone e um texto muito curto em fonte reduzida, integrado de forma discreta ao fluxo de saudação no cabeçalho.
  - **Variante Expandida (Hub de Gestão):** exibe ícone, texto destacado em caixa alta e fundo estilizado em glassmorphism elástico, ocupando posição de destaque acima do título do painel, garantindo respiro e alinhamento visual.
- **Regras de cores dos cargos:**
  - Cargo `admin_dev` (desenvolvedor e suporte técnico): consome o tom roxo/violeta técnico (`ConecteaVisualTokens.manutencaoTecnica.accent`).
  - Cargo `admin` e `admin_master`: consomem tons voltados à administração e coordenação geral.

### Menu de permissões e dados sensíveis

O menu de ações de usuários administrativos segue o padrão **Night Blue/Dark Glass** e deve comunicar visualmente a hierarquia dos cargos.

As opções de cargo usam cores e ícones alinhados aos badges administrativos do app:

- `Usuário`: semântica neutra/slate, representando perfil comum.
- `Administrador`: semântica administrativa operacional.
- `ADM Master`: semântica de coordenação/gestão elevada.
- `ADM DEV`: semântica técnica/dev, usando roxo/violeta reservado para manutenção e desenvolvimento.

O roxo/violeta técnico não deve ser usado como cor genérica de menu. Ele é reservado para `admin_dev`, manutenção técnica e rotinas de desenvolvimento.

A ação **Editar dados sensíveis** não é uma ação de cargo. Ela deve usar semântica de privacidade/segurança, com visual próprio, ícone coerente e separação visual das opções de cargo.

O diálogo **Editar dados sensíveis** segue o padrão Dark Glass, com aviso de privacidade, campos em Dark Glass e CPF protegido por padrão. O CPF deve iniciar oculto, com botão de revelar/ocultar usando semântica de privacidade. O diálogo deve evitar fundos azuis chapados herdados do tema global.

Quando o teclado virtual abre em telas estreitas, o layout administrativo deve ser scrollável e tolerante à redução de altura, evitando `RenderFlex overflow`.
