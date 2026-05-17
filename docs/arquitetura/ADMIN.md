# Admin — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

---

## Painel Administrativo (Admin)

Área restrita para gestão da associação, organizada por abas:
*   **Orquestração:** A `AdminView` gerencia a navegação entre as abas de solicitações e usuários.
*   **Solicitações:** `AdminRequestsTab` lista processos pendentes com filtros de status. Utiliza os novos badges e pills padronizados via `StatusVisualTokens`.
*   **Usuários:** `AdminUsersTab` permite a busca e gestão de permissões.
*   **Scanner:** `ScannerView` higienizada, utilizada para validar a autenticidade das carteirinhas via QR Code.
*   **Padronização de Ações:** Os botões de decisão administrativa (`APROVAR`, `REPROVAR`, `REVISAR DADOS`, `SOLICITAR DOCS`, `SUSPENDER`) no `AdminRequestDetailsSheet` foram migrados para o componente `StatusActionButton`. Eles preservam toda a lógica original de segurança e integração com banco, mas agora seguem a linguagem visual unificada.
*   **Segurança:** Logs sensíveis identificados na auditoria foram higienizados (remoção de IDs ou códigos brutos).
