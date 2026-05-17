# Componentes Premium — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

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
- **Características de Responsividade e Blindagem:**
  - **Efeito de Foco Dinâmico:** O item selecionado cresce horizontalmente revelando sua etiqueta de texto, enquanto os demais exibem apenas o ícone.
  - **Prevenção de RenderFlex:** O label do item ativo é envolvido por `Flexible(fit: FlexFit.loose)` e contido por um `ClipRect` com `TextOverflow.ellipsis`. Isso impede falhas de layout quando a largura interpolada cai temporariamente abaixo de `20px` nas transições.
  - **Compatibilidade do Sistema:** Mantém o padding inferior baseado no `MediaQuery.of(context).padding.bottom` para manter a coerência de espaçamento de forma nativa sob os modos de navegação do SO (gestos ou 3 botões).

### 3. QuickAccessCard

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
