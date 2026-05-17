# Requests — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

---

## 5.4 Solicitação de Carteirinha (Requests)
O fluxo foi consolidado e modularizado:
*   **Fluxo Direto:** Acesso via Home ou Cards diretamente para `AddMemberPage`.
*   **Validação Real:** Implementada validação algorítmica de CPF (`request_cpf_validator.dart`).
*   **Status Padronizado:** O sistema consome `StatusVisualTokens` para exibir feedbacks visuais apropriados na `RequestsView` e em cards de acompanhamento. O botão "CORRIGIR" (fluxo de revisão) foi unificado no padrão `StatusActionButton`.
*   **Segurança:** Ciclo de segurança imediata executado nas áreas auditadas, com feedbacks seguros ao usuário.
*   **Gestão de Documentos (Frente 24C):** Upload mobile via Google Apps Script (GAS) com suporte a bytes (Web fallback) e path (Mobile). Os logs do `GoogleDriveService` são mascarados (fileId omitido) para proteger a privacidade.
*   **Limpeza Automática (LGPD):** Ao aprovar uma carteirinha, o sistema remove automaticamente os documentos (RG/Laudo) da pasta do Google Drive e os envia para a lixeira. Os campos `document_url` e `medical_report_url` são limpos no banco de dados após o sucesso da operação. Validação oficial em mobile/emulador.
*   **Depreciação:** `MemberSelectionPage` e `NewRequestPage` foram removidas em favor da [AddMemberPage](file:///h:/Sites/ConeCTEA/lib/features/requests/add_member_page.dart).
*   **Refino do Formulário de Dependente (Frente 26C.1):**
    - Separou visualmente as informações de localização e os contatos. Estado e Cidade agora são exibidos em linhas individuais.
    - O contato de emergência e o responsável foram divididos individualmente em campos dedicados para Nome e Número de Telefone.
    - O placeholder do Tipo Sanguíneo foi ajustado para exatamente `"Selecione"`.
    - O widget [RequestDropdownField](file:///h:/Sites/ConeCTEA/lib/features/requests/widgets/request_dropdown_field.dart) foi aprimorado para renderizar adequadamente a dica (hint) quando o valor selecionado é nulo.
    - **Observação técnica importante:** Todas as separações foram efetuadas estritamente na camada de apresentação visual (UX). A lógica de persistência de dados de contatos no backend continua compatível, consolidando o formato `"Nome - Telefone"`, o que dispensou migrations de banco de dados ou alterações no schema Supabase.
*   **Refino Visual da Tela de Pedidos/Solicitações (Frente 26D.1):**
    - A visualização [requests_view.dart](file:///h:/Sites/ConeCTEA/lib/features/requests/requests_view.dart) foi reestruturada para apresentar os cards de solicitação de forma vertical organizada e responsiva.
    - Cada card de solicitação conta agora com uma faixa superior colorida em consonância com a cor do seu status de negócio, aproveitando o `radius: 20` e o `ClipRRect` do card principal sem a necessidade de customizações adicionais.
    - A pill de status foi movida para o topo esquerdo do card e enriquecida com o ícone correspondente do status, com tratamento flexível contra overflows e uso de reticências para textos muito longos.
    - O título foi envolvido por um `Expanded` com limite de 1 linha e ellipsis. Protocolo e data foram dispostos individualmente em linhas próprias de apoio visual.
    - A barra de progresso dinâmico foi migrada do cálculo baseado em `MediaQuery` para o uso de `LayoutBuilder` coletando a largura exata do container local (`constraints.maxWidth`), o que mitigou riscos de estouro lateral (RenderFlex) em viewports estreitas de 360dp.
    - O contador de registros ao lado dos cabeçalhos "EM ANDAMENTO" e "HISTÓRICO" foi ajustado na cor branca sobre uma pill translúcida em estilo Dark Glass, garantindo boa legibilidade e contraste na bancada de desenvolvimento atual.
