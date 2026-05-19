# Admin — ConeCTEA

**App:** 0.7.0-dev
**Documentação:** 4.4.0
**Status:** Desenvolvimento
**Atualizado em:** 18/05/2026

---

## Painel Administrativo (Admin)

Área restrita para gestão da associação, organizada por abas:
*   **Orquestração:** A `AdminView` gerencia a navegação entre as abas de solicitações e usuários.
*   **Solicitações:** `AdminRequestsTab` lista processos pendentes com filtros de status. Utiliza os novos badges e pills padronizados via `StatusVisualTokens`.
*   **Usuários:** `AdminUsersTab` permite a busca e gestão de permissões.
*   **Scanner:** `ScannerView` higienizada, utilizada para validar a autenticidade das carteirinhas via QR Code.
*   **Padronização de Ações:** Os botões de decisão administrativa (`APROVAR`, `REPROVAR`, `REVISAR DADOS`, `SOLICITAR DOCS`, `SUSPENDER`) no `AdminRequestDetailsSheet` foram migrados para o componente `StatusActionButton`. Eles preservam toda a lógica original de segurança e integração com banco, mas agora seguem a linguagem visual unificada.
*   **Segurança:** Logs sensíveis identificados na auditoria foram higienizados (remoção de IDs ou códigos brutos).

---

## Hub de Gestão/Admin

O Painel de Gestão/Admin passa a ser organizado como um Hub modular mobile-first. A tela inicial apresenta áreas administrativas em cards, permitindo que a estrutura do sistema fique visível para cargos atuais e futuros.

Módulos previstos no Hub:
- Gestão de Carteirinhas: módulo ativo atual para solicitações, revisões, documentos, renovações e status.
- Projetos, Programas e Eventos: módulo futuro para palestras, oficinas, ações sociais, inscrições e programas da Família TEA Bauru.
- Consultas com Profissionais: módulo futuro para agendamentos iniciais com dentistas, médicos, advogados e outros profissionais parceiros.
- Usuários e Permissões: módulo existente restrito conforme cargo administrativo, acessível a admin_master e admin_dev.
- Manutenção Técnica: módulo técnico existente restrito a admin_dev.

Regra de acesso:
Todos os cargos administrativos podem visualizar o Hub. A entrada nos módulos é controlada por permissão/cargo. Módulos sem acesso são exibidos como “Acesso restrito”; módulos ainda não implementados são exibidos como “Em breve”.

Nesta etapa, o Hub não altera regras de banco, permissões reais, RLS, fluxos de aprovação, documentos ou prazos administrativos.
