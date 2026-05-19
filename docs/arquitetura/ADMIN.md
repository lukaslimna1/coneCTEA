# Admin — ConeCTEA

**App:** 0.7.1-dev
**Documentação:** 4.5.0
**Status:** Desenvolvimento
**Atualizado em:** 19/05/2026

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

---

### Usuários e Permissões

O módulo **Usuários e Permissões** faz parte do Painel de Gestão/Admin e concentra a visualização administrativa de perfis e a gestão de cargos internos do ConeCTEA.

A entrada no módulo é controlada por cargo. O `admin` normal visualiza o Hub de Gestão, mas não entra em Usuários e Permissões. O `admin_master` e o `admin_dev` podem acessar o módulo.

A camada de interface aplica uma trava hierárquica para reduzir risco operacional:

- `admin`: não recebe ações de cargo.
- `admin_master`: pode agir somente sobre usuários `user` e `admin`.
- `admin_master`: não pode agir sobre si mesmo, sobre outros `admin_master` ou sobre `admin_dev`.
- `admin_dev`: pode agir sobre outros perfis e cargos, mas não sobre si mesmo pela interface.
- O menu de três pontos é ocultado quando o operador não possui permissão para agir sobre o usuário alvo.

A edição administrativa de cadastro foi reduzida ao escopo de **dados sensíveis**. O `admin_dev` pode abrir a ação **Editar dados sensíveis**, limitada aos campos **e-mail** e **CPF**. Dados comuns como nome, telefone, cidade, estado e gênero devem ser tratados pela área **Dados** do próprio usuário.

O diálogo de dados sensíveis usa aviso de privacidade, CPF protegido por padrão e botão para revelar/ocultar o CPF. O payload enviado para atualização administrativa deve permanecer restrito a `email` e `cpf`.

Esta frente aplicou travas defensivas na interface, mas não substitui validações de backend. Permanecem como pendências futuras: políticas RLS específicas, validações server-side, logs de auditoria administrativa, paginação de perfis e proteção contra remoção do último `admin_master` ou `admin_dev`.

---

### Gestão de Carteirinhas — otimização da fila administrativa

A fila administrativa da Gestão de Carteirinhas usa Realtime em `card_requests` para manter solicitações atualizadas enquanto o módulo está aberto.

Na Frente 27C.2, o enriquecimento N+1 de nomes foi removido. A tabela `card_requests` passou a possuir a coluna `member_name`, preenchida por backfill inicial + triggers de sincronização a partir de `members.name`.

Com isso:
- `getAllCardRequestsStream()` deixou de buscar `members.name` individualmente para cada solicitação;
- a busca administrativa por nome continua local no app;
- o card administrativo continua consumindo `CardRequest.memberName`;
- alterações no nome do membro propagam para a fila administrativa.

A lógica visual da Gestão de Carteirinhas não foi alterada nesta frente.
