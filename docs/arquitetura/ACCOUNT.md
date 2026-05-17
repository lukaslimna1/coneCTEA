# Central do Usuário (Account) — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento  
**Atualizado em:** 16/05/2026

---

## 5.3 Central do Usuário (Account)
A `AccountView` foi consolidada como o hub de serviços do usuário, dividida em 6 cards principais:
*   **Meus Dados:** acesso à `EditProfileView` modularizada. Exibe o `ConecteaAvatar` oficial com a paleta da conta e iniciais robustas (Primeira letra do nome + Primeira letra do último sobrenome).
*   **Segurança:** gestão de credenciais e troca de senha.
*   **Privacidade:** `ConsentsView` como tela de transparência sobre dados, consentimentos necessários e autorizações futuras.
*   **Ajuda:** `HelpSupportView` com FAQ e canais oficiais.
*   **Institucional:** informações sobre o ConeCTEA e a Família TEA Bauru.
*   **Aplicativo:** informações sobre versão/build e detalhes técnicos do app.

> [!IMPORTANT]
> **Restrições de dados sensíveis:** CPF e e-mail permanecem bloqueados para edição direta e exigem suporte administrativo.
