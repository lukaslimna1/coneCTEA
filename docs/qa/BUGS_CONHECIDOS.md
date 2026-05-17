# Bugs Conhecidos — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

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

---

## Observações

Nenhum bug de responsividade visual, RenderFlex ou overflow resta pendente nas seções principais da Home, da aba de Carteirinhas ou do formulário de solicitações auditados na bancada de desenvolvimento atual. A mitigação visual foi considerada altamente estável sob as condições de teste do ambiente local.
