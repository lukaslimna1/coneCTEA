# Segurança e Dados — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

---

## 6. Segurança e Dados
*   **Blindagem de UI:** Mensagens técnicas conhecidas foram substituídas por feedbacks amigáveis nas áreas auditadas (Auth, Admin, Account, Home, Requests, Notifications).
*   **Higienização de Logs:** Logs sensíveis identificados na auditoria foram higienizados (remoção de IDs, CPFs e códigos brutos de QR Code).
*   **Governança Visual:** A centralização de tokens visuais via `StatusVisualTokens` reduz a duplicação de lógica de cores manuais e evita inconsistências entre Admin, Requests, Home e Carteirinha. Não houve mudança de dados, banco ou regras de negócio durante a padronização.
*   **RLS (Row Level Security):** Políticas granulares no PostgreSQL garantem que usuários acessem apenas seus próprios dados.
*   **Roles:** Hierarquia de acesso controlada (`user`, `admin`, `admin_master`, `admin_dev`).
*   **Privacidade & LGPD:** A `ConsentsView` atua como tela de transparência. A limpeza automática de documentos sensíveis (RG, laudos) após aprovação administrativa é uma medida ativa de governança de dados para minimizar o armazenamento de PII (Personally Identifiable Information).
*   **Logs Seguros:** O `GoogleDriveService` implementa mascaramento de IDs de arquivo e URLs completas, garantindo que logs de depuração não exponham dados sensíveis.

---

## Segurança da conta — estado visual atual

A tela de **Segurança da Conta** (`SecurityView`) foi reformulada para incluir um fluxo visual estruturado de exclusão de conta, mitigando cliques impulsivos ou acidentais que possam causar perda irreparável de histórico de cadastros e carteirinhas.

*   **Modal de Confirmação por Escrita:** Ao acionar a ação de exclusão, o aplicativo apresenta um modal com aviso de alto impacto técnico. O botão final de confirmação permanece desabilitado até que o usuário digite exatamente o termo em maiúsculas: `EXCLUIR CONTA`.
*   **Cenário de Implementação (Mock):** Esta confirmação é puramente de interface (UI). **A ação final de exclusão ainda é visual e não realiza nenhuma exclusão real** de conta ou dados.
*   **Integridade do Backend Preservada:** Não houve alteração técnica em `AuthService`, Supabase Auth, controle de sessões locais, tokens JWT ou tabelas de banco PostgreSQL. A exclusão de contas em ambiente de produção exigirá uma frente técnica futura e independente para gerenciar a transição segura dos dados.

---

## Remoção de dependente — cuidado operacional

Com foco na integridade das informações cadastrais e segurança das crianças, o módulo de gerenciamento de dependentes agora possui proteção de interface no fluxo de exclusão de membros.

*   **Modal de Confirmação por Escrita:** Para acionar a exclusão de um dependente cadastrado a partir de sua tela de detalhes, o usuário deve passar por uma confirmação manual exigindo a digitação textual da palavra: `REMOVER`.
*   **Cenário de Implementação (Mock):** A confirmação final de remoção é simulada visualmente e **ainda não remove nenhum registro de dependente ou documento do banco de dados remoto.**
*   **Requisitos para Implementação Futura:** A consolidação do fluxo real de exclusão física de dependentes no backend do Supabase precisará considerar auditorias rigorosas, incluindo:
    1.  Verificação e descarte das carteirinhas ativas ou suspensas associadas ao dependente;
    2.  Remoção segura e expurgo físico das fotos de perfil e laudos arquivados no Google Drive institucional (via GAS);
    3.  Limpeza síncrona/assíncrona de registros de solicitações de carteirinha e históricos de auditoria;
    4.  Gravação de logs de auditoria de descarte em conformidade com as obrigações e prazos legais da LGPD.
