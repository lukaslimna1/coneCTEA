# Requests — ConeCTEA

**App:** 0.6.0-dev
**Documentação:** 4.3.0
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

---

## 5.4 Solicitação de Carteirinha (Requests)
O fluxo foi consolidado e modularizado:
*   **Fluxo Direto:** Acesso via Home ou Cards diretamente para `AddMemberPage`.
*   **Validação Real:** Implementada validação algorítmica de CPF (`request_cpf_validator.dart`).
*   **Status Padronizado:** O sistema consome `StatusVisualTokens` para exibir feedbacks visuais apropriados na `RequestsView` e em cards de acompanhamento. O botão "CORRIGIR" (fluxo de revisão) foi unificado no padrão `StatusActionButton`.
*   **Segurança:** Ciclo de segurança imediata executado nas áreas auditadas, com feedbacks seguros ao usuário.
*   **Gestão de Documentos (Frente 24C):** Upload mobile via Google Apps Script (GAS) com suporte a bytes (Web fallback) e path (Mobile). Os logs do `GoogleDriveService` são mascarados (fileId omitido) para proteger a privacidade.
*   **Limpeza Automática (LGPD):** Ao aprovar uma carteirinha, o sistema remove automaticamente os documentos (RG/Laudo) da pasta do Google Drive e os envia para a lixeira. Os campos `document_url` e `medical_report_url` são limpos no banco de dados após o sucesso da operação. Validação oficial em mobile/emulador.
*   **Depreciação:** `MemberSelectionPage` e `NewRequestPage` foram removidas em favor da `AddMemberPage` (`lib/features/requests/add_member_page.dart`).
*   **Refino do Formulário de Dependente (Frente 26C.1):**
    - Separou visualmente as informações de localização e os contatos. Estado e Cidade agora são exibidos em linhas individuais.
    - O contato de emergência e o responsável foram divididos individualmente em campos dedicados para Nome e Número de Telefone.
    - O placeholder do Tipo Sanguíneo foi ajustado para exatamente `"Selecione"`.
    - O widget `RequestDropdownField` (`lib/features/requests/widgets/request_dropdown_field.dart`) foi aprimorado para renderizar adequadamente a dica (hint) quando o valor selecionado é nulo.
    - **Observação técnica importante:** Todas as separações foram efetuadas estritamente na camada de apresentação visual (UX). A lógica de persistência de dados de contatos no backend continua compatível, consolidando o formato `"Nome - Telefone"`, o que dispensou migrations de banco de dados ou alterações no schema Supabase.
*   **Refino Visual da Tela de Pedidos/Solicitações (Frente 26D.1):**
    - A visualização `requests_view.dart` (`lib/features/requests/requests_view.dart`) foi reestruturada para apresentar os cards de solicitação de forma vertical organizada e responsiva.
    - Cada card de solicitação conta agora com uma faixa superior colorida em consonância com a cor do seu status de negócio, aproveitando o `radius: 20` e o `ClipRRect` do card principal sem a necessidade de customizações adicionais.
    - A pill de status foi movida para o topo esquerdo do card e enriquecida com o ícone correspondente do status, com tratamento flexível contra overflows e uso de reticências para textos muito longos.
    - O título foi envolvido por um `Expanded` com limite de 1 linha e ellipsis. Protocolo e data foram dispostos individualmente em linhas próprias de apoio visual.
    - A barra de progresso dinâmico foi migrada do cálculo baseado em `MediaQuery` para o uso de `LayoutBuilder` coletando a largura exata do container local (`constraints.maxWidth`), o que mitigou riscos de estouro lateral (RenderFlex) em viewports estreitas de 360dp.
    - O contador de registros ao lado dos cabeçalhos "EM ANDAMENTO" e "HISTÓRICO" foi ajustado na cor branca sobre uma pill translúcida em estilo Dark Glass, garantindo boa legibilidade e contraste na bancada de desenvolvimento atual.
*   **Revisão Administrativa e Reenvio Seletivo de Documentos (Frente 26F):**
    - **Destravamento Condicional de Campos:** Na tela de edição (`AddMemberPage`), quando uma solicitação retorna do fluxo de análise para revisão do usuário (`reviewing_data` ou `waiting_docs`), apenas os campos e documentos marcados explicitamente pelo administrador são destravados para edição (controlado via `_isFieldEnabled`). Todos os demais campos permanecem bloqueados de forma segura, reduzindo riscos de alterações indesejadas de dados já validados.
    - **Liberação Dinâmica do Campo CID:** O campo do Código Internacional de Doenças (CID) passa a ser desbloqueado dinamicamente no formulário do usuário se, e somente se, o reenvio do Laudo Médico for solicitado pela administração.
    - **Comportamento Visual dos Campos sob Revisão:** Para evitar confusão no reenvio de informações, o formulário apresenta os campos de texto sob revisão como limpos/vazios e os seletores de arquivo limpos, obrigando o usuário a reenviar/redigitar estritamente a nova informação correta solicitada. Os documentos não solicitados permanecem preservados e ocultos para edição.
    - **Persistência Segura nas Tabelas:** O processo de limpeza e sincronização é executado em nível de banco de dados no Supabase, afetando as tabelas `card_requests` (tabela de requisições temporárias) e `members` (tabela de dados efetivos), garantindo consistência técnica em todo o ecossistema e mitigando que URLs desatualizadas ou rejeitadas reapareçam para o usuário final.
