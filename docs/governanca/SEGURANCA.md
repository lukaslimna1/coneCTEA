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
