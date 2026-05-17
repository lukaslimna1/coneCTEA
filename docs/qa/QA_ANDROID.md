# QA Android — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

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
*   **Validação em Hardware Real:**
    *   Testes periódicos realizados em dispositivo físico **Samsung A55**, validando comportamento de `SafeArea`, `NavigationBar` nativa, densidade de pixels e performance de animações (avatares neon e carteirinha digital).
*   **Protocolo Técnico:**
    *   Uso da flag `-no-snapshot-load` nos scripts para garantir um "Cold Boot" limpo e evitar travamentos por snapshots corrompidos.
    *   Atenção redobrada ao abrir múltiplos emuladores, pois os IDs de dispositivo (ex: `emulator-5554`) podem alternar entre os perfis abertos.
