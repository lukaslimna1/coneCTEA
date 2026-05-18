# Requests — ConeCTEA

**App:** 0.7.0-dev
**Documentação:** 4.4.0
**Status:** Desenvolvimento
**Atualizado em:** 18/05/2026

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
*   **Botão "Fazer mais tarde" e Descarte Seguro (Frente 26G):**
    - **UX de Abandono Sem Envio:** Adiciona o botão secundário `RequestLaterButton` (`lib/features/requests/widgets/request_later_button.dart`) na tela de formulário `AddMemberPage`. O objetivo é dar ao usuário uma saída segura sem a obrigatoriedade de finalizar a edição ou reenvio de imediato. A regra de negócio estabelece que "Fazer mais tarde" não atua como rascunho persistente.
    - **Interceptação de Retorno:** Utiliza o widget `PopScope` para interceptar tanto o clique no botão "Fazer mais tarde" quanto o gesto físico ou botão de voltar nativo do sistema operacional Android/iOS.
    - **Detecção de Alterações Locais:** O método local `_hasUnsavedChanges` na `AddMemberPage` compara dinamicamente o estado atual do formulário com os dados originais carregados (checando controllers de texto, tipo sanguíneo e novos arquivos selecionados no picker da sessão).
    - **Diálogo de Confirmação:** Caso modificações ou uploads de novos arquivos tenham ocorrido, o diálogo `RequestUnsavedChangesDialog` (`lib/features/requests/widgets/request_unsaved_changes_dialog.dart`) é invocado, fornecendo as opções de continuar editando ou sair descartando as edições. Caso não haja alterações locais, a tela é fechada imediatamente sem alertas.
    - **Higiene e Exclusão de Uploads da Sessão:** Em caso de descarte confirmado, o helper modularizado `RequestCleanupHelper` (`lib/features/requests/helpers/request_cleanup_helper.dart`) é acionado em segundo plano para catalogar e efetuar a tentativa assíncrona de exclusão física dos novos arquivos temporários carregados no Google Drive/GAS estritamente durante aquela sessão de edição. Arquivos antigos oficiais já consolidados ou salvos anteriormente permanecem preservados e intocados.
    - **Mitigação de Impacto de Rede:** O fluxo de descarte e saída segura da tela é projetado para ser tolerante a falhas de rede. Erros de delete no Drive/GAS não impedem a saída do usuário e são mitigados silenciosamente, registrando em log local apenas o necessário sem expor IDs confidenciais de dados pessoais. O status do banco no Supabase não sofre alterações e nenhuma notificação é criada ou enviada ao administrador.
*   **Prazos Administrativos de Correção Server-Side (Frente 26H.3):**
    - **Cálculo em Dias Úteis:** Introduz o controle de prazos administrativos estritos em dias úteis operacionais (excluindo sábados e domingos) calculados no servidor via funções de banco de dados (`conectea_add_business_days`), sem interferência do relógio do aparelho do usuário.
    - **Prazos Selecionáveis (Interface do Administrador):** O administrador seleciona dinamicamente a duração do prazo administrativo de correção (7, 15 ou 30 dias úteis operacionais) na interface do painel no momento de processar o retorno da solicitação para revisão. O cálculo e a validação do prazo associado ocorrem no banco por meio da RPC `conectea_admin_deadline`, sem uso de triggers ou policies automáticas nas tabelas de solicitações.
    - **Momento da Expiração:** O prazo limite expira na virada técnica exata para o dia civil subsequente (`00:00:00` do dia seguinte ao limite técnico no fuso `America/Sao_Paulo` de Bauru/SP), oferecendo segurança jurídica e tempo completo para que os usuários realizem as adequações necessárias até o último minuto do prazo.
    - **Limitação Registrada (Feriados):** Feriados não são integrados à regra nesta etapa por razões de complexidade operacional, sendo contabilizados como dias normais na soma de dias úteis.

