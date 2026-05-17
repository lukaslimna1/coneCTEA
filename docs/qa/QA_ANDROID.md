# QA Android — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

---

## Regras de Desenvolvimento e Validação
*   **Idioma:** Toda a comunicação, comentários e documentação em **Português Brasileiro (PT-BR)**.
*   **Validação Android:** Priorizar validação em emuladores Android e perfis Samsung-like. O Chrome DevTools pode ser usado apenas como fallback visual inicial. Testes em hardware real são pontuais.
*   **Padrão de Código:** Proibido o uso de `git add .`. Commits devem ser descritivos e em português.

## Infraestrutura de QA Android Local
O projeto mantém scripts de automação em `tools/qa/android/` para agilizar a validação em diferentes perfis:
*   **Perfis/Emuladores da Bancada Oficial (Frente 25A):**
    *   **Samsung:** A05/A06 (360dp), A15/A16 (360dp), A35/A36 (384dp), A55/A56 (400dp), S24/S25 (360dp), S24 Ultra (480dp), ZFlip (412dp Tall).
    *   **Motorola:** Edge 40 Neo (400dp), Edge Curved (384dp), Razr Open (412dp), Moto G FHD (432dp).
    *   **Xiaomi:** Redmi/POCO 1.5K (438dp).
*   **Scripts de Automação (`tools/qa/android/`):**
    *   Scripts `.bat` padronizados para abertura de AVDs com `-gpu angle_indirect` e `-no-snapshot-load`.
    *   Utilitários inclusos: `listar_avds.bat`, `fechar_emuladores_adb.bat` e `abrir_todos_qa_info.bat`.
    *   Scripts antigos obsoletos foram removidos.
*   **Dispositivos de Referência:**
    *   Perfil **Samsung A55** considerado como referência para visualização do comportamento de `SafeArea`, `NavigationBar` nativa, densidade de pixels e performance de animações (avatares neon e carteirinha digital).
*   **Protocolo Técnico:**
    *   Uso da flag `-no-snapshot-load` nos scripts para garantir um "Cold Boot" limpo e evitar travamentos por snapshots corrompidos.
    *   Atenção redobrada ao abrir múltiplos emuladores, pois os IDs de dispositivo (ex: `emulator-5554`) podem alternar entre os perfis abertos.

---

## Protocolo de Testes de Responsividade (Frente 26A)

Para validar modificações no ecossistema da Home e componentes premium associados, execute os seguintes passos:

1. **Validação de Notches e Entalhes superiores:**
   - Ative a simulação de entalhe (Ex: *Waterfall Cutout* ou *Corner Cutout*) nas opções de desenvolvedor do emulador.
   - Verifique que o `AppTopHeader` permanece posicionado adequadamente e o Hero da Home não sofre deslocamento incorreto.

2. **Simulação de Gestos e Barra de Navegação Física:**
   - Execute o app no perfil **Samsung A05/A06** (360dp) e **ZFlip** (412dp Tall).
   - Alterne o sistema do Android para navegação por **Gestos**. Verifique que os botões de ação e abas não se sobrepõem à barra horizontal de gestos do SO.
   - Alterne de volta para navegação por **3 Botões**. Valide o comportamento estético sob a `PremiumBottomNavBar`.

3. **Carga e Zoom Dinâmicos:**
   - **Cenário recomendado de validação futura:** Configurar o emulador com zoom de exibição de **1.5x**.
   - Navegar pela Home e verificar que a lista horizontal de membros e os cards de atalhos e informações redimensionam adequadamente, mitigando o risco de truncações ou overflows horizontais/verticais.

4. **Protocolo de Testes para Teclado IME e Navbar Oculta (Frente 26C.2):**
   - **Dispositivo recomendado:** Emulador com perfil **Motorola Edge Curved** ou similar, com barra nativa de **3 Botões** configurada.
   - **Passo a Passo:**
     1. Navegar até a página de novo dependente ([AddMemberPage](file:///h:/Sites/ConeCTEA/lib/features/requests/add_member_page.dart)).
     2. Tocar em qualquer campo de entrada de texto (ex: Nome).
     3. Confirmar que o teclado virtual do Android sobe e a `PremiumBottomNavBar` é ocultada de forma instantânea.
     4. Rolar o formulário até o final com o teclado ativo, garantindo que não ocorra RenderFlex ou impedimentos físicos nos campos de Cidade, Estado e botões de contatos.
     5. Dispensar o teclado (pressionando voltar). Validar que a navbar reaparece graciosamente em sua posição correta.

5. **Protocolo de Testes de Detalhes da Carteirinha em Telas Estreitas (Frente 26B.2 / 26B.3-AUD):**
   - **Dispositivo recomendado:** Perfil **Samsung A05/A06** (360dp de largura de tela).
   - **Passo a Passo:**
     1. Navegar até a aba de Carteirinhas ([cards_view.dart](file:///h:/Sites/ConeCTEA/lib/features/cards/cards_view.dart)).
     2. Selecionar o dependente e examinar o componente [CardsDetailsSection](file:///h:/Sites/ConeCTEA/lib/features/cards/widgets/tela_carteirinhas/cards_details_section.dart) logo abaixo do card.
     3. Garantir que o bloco "Validade" e a pill de status administrativo estejam adequadamente alinhados na horizontal, livres de RenderFlex.
     4. Validar se o CTA principal possui exatamente o texto `"VER"` de 1 linha.
     5. No menu de configurações do Android do emulador, aumente o tamanho da fonte do sistema para o nível máximo.
     6. Retorne ao app e confirme que os textos longos exibem reticências (`TextOverflow.ellipsis`) e não extrapolam a linha ou causam estouro de tela.

6. **Protocolo de Testes para Pedidos e Solicitações (Frente 26D.1):**
   - **Dispositivo recomendado:** Perfil **Samsung A05/A06** (360dp de largura de tela) ou **Xiaomi Redmi/POCO** (438dp).
   - **Passo a Passo:**
     1. Navegar até a aba de Pedidos/Solicitações ([requests_view.dart](file:///h:/Sites/ConeCTEA/lib/features/requests/requests_view.dart)).
     2. Validar o alinhamento e a integridade visual da disposição vertical dos cards de solicitação.
     3. Confirmar que a barra de progresso interno (com `LayoutBuilder`) expande e contrai de forma proporcional à largura útil disponível sem ocasionar falhas ou transbordos pretos/amarelos de RenderFlex.
     4. Verificar a legibilidade do texto nos cabeçalhos "EM ANDAMENTO" e "HISTÓRICO" sob luz ambiente simulada brilhante ou no modo escuro.
     5. Testar a funcionalidade de cópia do número de protocolo em múltiplos aparelhos da bancada, validando o contraste da mensagem temporária de sucesso.
