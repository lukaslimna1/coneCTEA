# Edge Functions — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

---

## Supabase Edge Functions
Documentação de funções serverless implementadas:
*   **recover-email-by-cpf:**
    *   **Objetivo:** Recuperação segura de e-mail através do CPF do usuário.
    *   **Segurança:** Utiliza `service_role` exclusivamente no backend. O aplicativo recebe apenas os campos `found` (boolean), `masked_email` (ex: `l***@email.com`) e `email_sent` (se o fluxo de reset foi disparado). O e-mail completo nunca retorna ao frontend.
    *   **Configuração:** `verify_jwt = false` configurado para permitir o início do fluxo por usuários anônimos (pré-login).
    *   **Dependência:** A função deve estar corretamente deployada e ativa no projeto Supabase.
