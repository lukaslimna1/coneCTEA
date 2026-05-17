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
