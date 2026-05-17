# Auth — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

---

## Autenticação e Onboarding (Auth)

O fluxo de autenticação foi refinado visualmente, estabilizado e modularizado:
*   **Login:** Interface com scroll natural, contraste aprimorado em ícones e links, e fundo Night Blue Premium consistente.
*   **Recuperação de Senha:** Fluxo nativo via Supabase Auth com mensagens seguras/neutras e botões no padrão premium.
*   **Recuperação de E-mail (Edge Function):** Implementado fluxo seguro via CPF e Edge Function `recover-email-by-cpf`. A interface foi personalizada com a logo ConeCTEA, Hero `app_logo`, campos com ícones brancos e foco em roxo.
*   **Cadastro (Criar conta):**
    *   Textos otimizados para legibilidade e links em ciano.
    *   Botão "Criar minha conta" em estilo `premiumCard` com `greenAccent`.
    *   Inputs e dropdowns padronizados com ícones brancos.
    *   Seções organizadas por cores semânticas: Dados Pessoais (ciano/oceano), Localização (verde), Segurança (azul claro) e Dados complementares (branco discreto).
    *   **Cadastro 100% Interno (Sem OTP):** O fluxo de confirmação por e-mail (OTP) foi removido. Após a criação da conta, o app realiza `signOut()` imediato para impedir o login automático, exibe um diálogo de sucesso ("🎉 Parabéns!") e direciona o usuário para o Login manual. A `ConfirmEmailPage` foi desativada.
    *   **Recuperação de Senha:** Fluxo nativo via Supabase Auth preservado.
*   **Modais Legais:** Leitura de Termos de Uso e Política de Privacidade organizada por blocos/cards internos para melhor escaneabilidade.
*   **Consentimentos:** Checkboxes (LGPD) com bordas desmarcadas mais visíveis e estados claros.
*   **Segurança:** Mensagens técnicas conhecidas foram substituídas por feedbacks amigáveis.
*   **Responsividade:** A responsividade global de textos segue como um ponto de atenção para ciclos futuros.
