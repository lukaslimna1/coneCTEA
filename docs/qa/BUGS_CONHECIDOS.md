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
- **Resolução:** O rótulo foi envolto por `Flexible(fit: FlexFit.loose)` e blindado por um `ClipRect` com `TextOverflow.ellipsis`, forçando a redução graciosa e o desaparecimento do texto sem gerar truncações físicas ou quebra de linha.
- **Commit:** `0ad6c0a` (Status: **Mitigado pela Frente 26A**).

### 1.2 Espaçamento Superior Excessivo (Hero "caído")
- **Problema:** Após a blindagem inicial de `SafeArea` contra entalhes de tela, o cabeçalho Hero ("Olá, Nome") e o conteúdo da Home ficaram afastados excessivamente do header/logotipo, gerando um visual esteticamente desagradável.
- **Resolução:** O cálculo vertical foi ajustado de forma dinâmica. A SafeArea agora consome estritamente o `MediaQuery.of(context).padding.top` somado a um clearance fino de `8.0` pixels, trazendo o conteúdo para cima de forma elegante e mantendo a proteção contra entalhes superiores nos emuladores testados.
- **Commit:** `a38ad63` (Status: **Resolvido**).

### 1.3 Vão Inferior no Acesso Rápido (`QuickAccessCard` / Carrossel)
- **Problema:** Um vão excessivo surgia abaixo do botão CTA do `QuickAccessCard`, e consequentemente havia uma folga enorme entre a seção "Acesso Rápido" e "Outros Serviços".
- **Resolução:**
  1. Remoção do widget `Spacer` e da restrição de altura rígida de dentro do `QuickAccessCard` (Commit `14e5e0b`).
  2. Ajuste fino da altura do carrossel pai na `HomeQuickAccessSection` de `168` para `148` (Commit `6353db7`).
- **Status:** **Resolvido**.

---

## 2. Histórico Geral de Bugs e Status Atual

| Identificador do Bug | Módulo Afetado | Gravidade | Resolução Técnica | Status Final |
| :--- | :--- | :--- | :--- | :--- |
| `BUG-HOME-001` | `AppTopHeader` | Média | SafeArea adaptativo + clearance de `8.0`. | **RESOLVIDO** |
| `BUG-HOME-002` | `PremiumBottomNavBar` | Alta | `Flexible` + `ClipRect` + `TextOverflow.ellipsis`. | **RESOLVIDO** |
| `BUG-HOME-003` | `QuickAccessCard` | Média | Remoção de `Spacer` e limitação de carrossel para `148`. | **RESOLVIDO** |
| `BUG-HOME-004` | `HomeMembersSection` | Média | Altura dinâmica com `BoxConstraints(minHeight: 64)`. | **RESOLVIDO** |

---

## Observações

Nenhum bug de responsividade visual ou overflow resta pendente nas seções principais da Home (`HomeServicesSection` e `HomeInformationSection` auditadas e consideradas estáveis nos emuladores testados).
