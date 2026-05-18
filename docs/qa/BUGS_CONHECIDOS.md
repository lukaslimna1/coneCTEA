# Bugs Conhecidos — ConeCTEA

**App:** 0.6.0-dev
**Documentação:** 4.3.0
**Status:** Desenvolvimento
**Atualizado em:** 18/05/2026

---

## Objetivo

Catalogar, rastrear e documentar a resolução técnica dos problemas visuais e bugs conhecidos identificados no ecossistema ConeCTEA.

---

## 1. Bugs Resolvidos na Frente 26A (Responsividade da Home)

A Frente 26A mitigou falhas estruturais de layout e renderização na interface principal nos cenários analisados:

### 1.1 Overflow na Navbar Premium (`PremiumBottomNavBar`)
- **Problema:** Erro de `RenderFlex` momentâneo e tremor visual durando milissegundos ao alternar entre as abas.
- **Causa Técnica:** A animação de transição encolhia a largura do item ativo contendo o rótulo textual para menos de `20px` antes de ocultá-lo totalmente. Isso forçava uma quebra de linha forçada em uma `Row` de altura fixa, estourando os limites do widget.
- **Resolução:** O rótulo foi envolto por `Flexible(fit: FlexFit.loose)` e protegido por um `ClipRect` com `TextOverflow.ellipsis`, forçando a redução graciosa e o desaparecimento do texto sem gerar truncações físicas ou quebra de linha.
- **Commit:** `0ad6c0a` (Status: **Mitigado pela Frente 26A**).

### 1.2 Espaçamento Superior Excessivo (Hero "caído")
- **Problema:** Após a proteção inicial de `SafeArea` contra entalhes de tela, o cabeçalho Hero ("Olá, Nome") e o conteúdo da Home ficaram afastados excessivamente do header/logotipo, gerando um visual esteticamente desagradável.
- **Resolução:** O cálculo vertical foi ajustado de forma dinâmica. A SafeArea agora consome estritamente o `MediaQuery.of(context).padding.top` somado a um clearance fino de `8.0` pixels, trazendo o conteúdo para cima de forma elegante e mantendo a proteção contra entalhes superiores nos emuladores testados.
- **Commit:** `a38ad63` (Status: **Resolvido**).

### 1.3 Vão Inferior no Acesso Rápido (`QuickAccessCard` / Carrossel)
- **Problema:** Um vão excessivo surgia abaixo do botão CTA do `QuickAccessCard`, e consequentemente havia uma folga enorme entre a seção "Acesso Rápido" e "Outros Serviços".
- **Resolução:**
  1. Remoção do widget `Spacer` e da restrição de altura rígida de dentro do `QuickAccessCard` (Commit `14e5e0b`).
  2. Ajuste fino da altura do carrossel pai na `HomeQuickAccessSection` de `168` para `148` (Commit `6353db7`).
- **Status:** **Resolvido**.

---

## 2. Bugs Resolvidos nas Frentes 26B & 26C (Carteirinha e Teclado)

As frentes 26B e 26C focaram na mitigação de falhas e problemas de visualização e layout em aparelhos reais e emulados estreitos e com teclados virtuais ativos.

### 2.1 Overflow na Seção de Detalhes da Carteirinha (`CardsDetailsSection`)
- **Problema:** Erros graves de `RenderFlex` (overflows de layout) na seção informativa logo abaixo da carteirinha digital, identificados principalmente em telas de 360dp de largura (como Samsung A05/A06).
- **Causa Técnica:** O label `"Validade"` e os botões horizontais com textos longos como `"Ver carteirinha"` espremiam os limites laterais da tela quando exibidos em aparelhos com resoluções mais estreitas ou escala de fonte aumentada.
- **Resolução:**
  1. O CTA foi resumido para apenas `"VER"`, recuperando espaço precioso na linha horizontal.
  2. O bloco informativo de `"Validade"` teve seu padding horizontal encurtado para `8dp` e o tamanho do ícone associado reduzido para `14dp`.
  3. Todos os textos dinâmicos foram envolvidos por `Expanded`, `maxLines: 1` e `TextOverflow.ellipsis`. Os botões rápidos foram distribuídos lado a lado envolvidos individualmente por `Expanded`, dividindo uniformemente em 50/50 sem empurrar elementos para fora.
- **Status:** **Resolvido estruturalmente** (Frente 26B.2 / 26B.3-AUD).

### 2.2 Sobreposição da Navbar com Teclado Aberto (`PremiumBottomNavBar`)
- **Problema:** Ao tocar nos campos de entrada do formulário de novo dependente, a `PremiumBottomNavBar` era empurrada para cima junto com o teclado Android virtual, cobrindo campos de texto e gerando conflito estético grave, especialmente em celulares com barra física de navegação nativa de 3 botões (como Motorola Edge Curved).
- **Causa Técnica:** A navbar nativa do Flutter respondia dinamicamente à alteração na janela visual induzida pela abertura do teclado (Input Method Editor - IME).
- **Resolução:** O widget foi protegido com detecção nativa de foco de escrita. Ao ler `MediaQuery.viewInsetsOf(context).bottom > 0` (indicando teclado aberto na tela), o componente passa a retornar imediatamente um `SizedBox.shrink()`. Isso oculta temporariamente o menu premium, restaurando o espaço de scroll vertical completo para o formulário. A navbar reaparece de forma transparente e imediata assim que o foco do teclado é encerrado.
- **Status:** **Resolvido** (Frente 26C.2).

### 2.3 Overflows e Legibilidade na Tela de Pedidos e Solicitações (RequestsView)
- **Problema:** Riscos de overflow horizontal na barra de progresso devido ao uso de MediaQuery para calcular largura dinâmica, além de baixa legibilidade no texto de contagem de registros na seção "Histórico" (texto roxo sobre fundo escuro).
- **Causa Técnica:** O cálculo da barra utilizava a largura total da tela física, sem respeitar a margem e padding dos cards premium internos, causando estouro lateral em telas estreitas de 360dp. O contador roxo escuro oferecia baixo contraste de cores.
- **Resolução:**
  1. A barra de progresso foi migrada para usar `LayoutBuilder` coletando a largura exata do container local (`constraints.maxWidth`), permitindo flexibilidade proporcional e mitigando o risco de overflow horizontal em 360dp.
  2. O contador visual foi substituído por um badge Dark Glass translúcido com contorno e texto em branco suave (`white.withValues(alpha: 0.92)`), garantindo alta legibilidade e contraste.
  3. A estrutura do card de solicitação foi organizada verticalmente (pill de status, ícone, título com Expanded/ellipsis, número de protocolo e data em linhas próprias), protegendo o conteúdo.
- **Status:** **Mitigado e Resolvido** (Frente 26D.1)

---

## 3. Histórico Geral de Bugs e Status Atual

| Identificador do Bug | Módulo Afetado | Gravidade | Resolução Técnica | Status Final |
| :--- | :--- | :--- | :--- | :--- |
| `BUG-HOME-001` | `AppTopHeader` | Média | SafeArea adaptativo + clearance de `8.0`. | **RESOLVIDO** |
| `BUG-HOME-002` | `PremiumBottomNavBar` | Alta | `Flexible` + `ClipRect` + `TextOverflow.ellipsis`. | **RESOLVIDO** |
| `BUG-HOME-003` | `QuickAccessCard` | Média | Remoção de `Spacer` e limitação de carrossel para `148`. | **RESOLVIDO** |
| `BUG-HOME-004` | `HomeMembersSection` | Média | Altura dinâmica com `BoxConstraints(minHeight: 64)`. | **RESOLVIDO** |
| `BUG-CARD-001` | `CardsDetailsSection` | Alta | Padding compacto + Expanded + CTA 'VER' de 1 linha. | **RESOLVIDO** |
| `BUG-NAV-001` | `PremiumBottomNavBar` | Alta | Ocultação baseada em MediaQuery.viewInsetsOf quando teclado > 0. | **RESOLVIDO** |
| `BUG-REQ-001` | `RequestsView` | Alta | LayoutBuilder na barra de progresso + Cards verticais + Contador branco. | **RESOLVIDO** |
| `BUG-REQ-002` | `RequestAdminNotesBanner`| Média | Redução do título para "Ajustes solicitados", padding e flexibilidade de linha. | **RESOLVIDO** |
| `BUG-REQ-003` | `AddMemberPage (Drive)` | Alta | Remoção da exclusão do Drive do fluxo do usuário e migração para o fluxo admin. | **RESOLVIDO** |
| `BUG-REQ-004` | `AddMemberPage (Descarte)`| Média | Interceptação de volta + descarte local + tentativa assíncrona de limpeza de uploads novos no Drive. | **MITIGADO** |

---

## 4. Bugs Resolvidos na Frente 26F (Revisão de Dados e Reenvio de Documentos)

A Frente 26F tratou de correções visuais e lógicas críticas identificadas durante o fluxo de reenvio de dados pelo usuário final:

### 4.1 Overflow no Banner de Pendência Administrativa (`RequestAdminNotesBanner`)
- **Problema:** Um erro de overflow de renderização (estouro horizontal da tela) ocorria ao exibir o banner de ajustes administrativos em dispositivos móveis estreitos (360dp de largura), quebrando a estética premium da tela.
- **Causa Técnica:** O título `"Ajuste solicitado pelo Administrador"` era excessivamente longo e tentava se renderizar sem quebra em uma linha rígida sem restrição flexível.
- **Resolução:** O título foi encurtado com moderação para `"Ajustes solicitados"`, o padding lateral do componente foi compactado e todos os elementos de texto e botão foram envolvidos em estruturas flexíveis adequadas (`Expanded`), permitindo dimensionamento seguro mesmo nas menores janelas visuais.
- **Status:** **Resolvido** (Frente 26F-FIX.1A).

### 4.2 Deleção Física Precoce e Inconsistente de Arquivos no Google Drive
- **Problema:** Ao selecionar um novo arquivo no fluxo de correção do formulário (`_pickAndUploadFile`), o sistema excluía fisicamente o arquivo anterior do Google Drive de forma imediata. Se o usuário cancelasse a edição ou fechasse o aplicativo sem pressionar "Salvar", a URL persistida no Supabase apontava para um arquivo inexistente no Drive (link quebrado).
- **Causa Técnica:** A chamada ao método de deleção do Google Drive estava inserida dentro da função de seleção temporária de arquivo local na máquina do usuário final.
- **Resolução:** A lógica de exclusão física precoce em `_pickAndUploadFile` foi totalmente removida. O processo de exclusão de arquivos obsoletos/rejeitados foi transferido com segurança para o lado do administrador. O trigger de remoção agora é disparado seletivamente apenas no momento exato em que o administrador confirma a pendência e envia a solicitação de volta para reenvio de documentos específicos.
- **Status:** **Resolvido** (Frente 26F-DRIVE-FIX.1).

---

---

## 5. Mitigações e Riscos Residuais na Frente 26G (Fazer mais tarde / Saída Segura)

A Frente 26G implementou a interceptação de retorno (nativa e via botão "Fazer mais tarde") com descarte seguro de modificações locais e higiene física remota na `AddMemberPage`:

### 5.1 Risco de Arquivos Órfãos no Google Drive por Abandono da Sessão
- **Risco Técnico:** Ao selecionar novos arquivos para envio de RG ou Laudo no fluxo de cadastro ou correção de pendências, o upload temporário ao Google Drive remoto é imediato na UX do componente. Caso o usuário desistisse do envio tocando em `"Fazer mais tarde"`, fechasse a tela ou fechasse o app, estes novos arquivos já gravados na nuvem ficariam abandonados no Drive institucional como arquivos órfãos sem correspondência lógica no Supabase, comprometendo a limpeza de armazenamento e o princípio de minimização de dados.
- **Mitigação Implementada:** Ao selecionar a ação `"Sair sem Salvar"`, o aplicativo lê as URLs de novos documentos anexados estritamente na sessão ativa e dispara em plano de fundo de forma assíncrona a tentativa de deleção física desses arquivos provisórios no Drive via Google Apps Script. Os documentos antigos já salvos e gravados anteriormente **não sofrem nenhuma alteração ou risco de perda de link**.
- **Risco Residual:** Na ocorrência de encerramentos inesperados do sistema (ex: falta de bateria, queda completa de conexão de rede de dados no meio da fila de descarte, ou travamento do sistema operacional), a chamada de deleção remota assíncrona pode não se completar com êxito, deixando arquivos residuais sem associação na pasta remota. Este comportamento faz parte das limitações estruturais de comunicação em rede móvel. Trata-se de um risco residual sob constante observação e monitoramento, sem ações corretivas imediatas necessárias.

---

## Observações

Todas as inconsistências de responsividade visual, RenderFlex, overflow ou riscos de perda lógica na integridade de arquivos conhecidas foram analisadas em bancada de desenvolvimento e mitigadas. A auditoria técnica e os testes manuais em ambiente de laboratório indicam que os comportamentos de interface atendem aos critérios de aceitação e de UX estabelecidos para o ecossistema ConeCTEA, priorizando a mitigação contínua de inconsistências operacionais e de rede sem assumir invulnerabilidade absoluta.
