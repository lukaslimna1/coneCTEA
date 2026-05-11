# 📘 Documentação Técnica — ConeCTEA
**Versão:** 3.5.0 | **Atualizado em:** 11/05/2026

---

## 1. Visão Técnica
O **ConeCTEA** é um ecossistema mobile-first preparado para evolução contínua, utilizando uma arquitetura modular que separa preocupações de negócio, interface e dados. O foco principal é a entrega de uma experiência estável no Android, com governança de dados sensíveis e boas práticas de privacidade por design.

---

## 2. Stack Tecnológica
*   **Core:** Flutter 3.41.9 / Dart 3.11.5.
*   **Backend:** Supabase (PostgreSQL + Auth + Realtime + RLS/RPC).
*   **Plataforma Alvo:** Android (Prioridade total). iOS é uma possibilidade futura.
*   **Web:** O projeto **não é um web app**. O uso do Chrome é restrito a testes rápidos de layout; a validação oficial ocorre em dispositivos Android.

---

## 3. Arquitetura e Organização
O projeto utiliza uma estrutura baseada em funcionalidades (**features**), permitindo isolamento de código e facilidade de manutenção.

### 3.1 Estrutura de Pastas Atualizada
```text
lib/
├── app/                  # Configurações globais, rotas (go_router) e tema.
├── core/                 # Base reutilizável, constantes (AppColors) e utils.
│   └── widgets/          # Widgets premium (Night Blue Design System).
├── features/             # Domínios de negócio isolados.
│   ├── account/          # Perfil, segurança e telas institucionais (novo local).
│   ├── admin/            # Dashboard administrativo e scanner de validação.
│   ├── auth/             # Fluxos de login, registro e recuperação.
│   ├── cards/            # Visualização de carteirinhas.
│   ├── home/             # Dashboard do usuário e seções dinâmicas.
│   ├── notifications/    # Gestão de alertas internos.
│   └── requests/         # Fluxo de submissão de membros e documentos.
├── models/               # Classes de dados (Data Models).
└── services/             # Lógica de integração (Supabase, Auth, Drive/GAS).
```

---

## 4. Design System — Night Blue Premium
O padrão **Night Blue Premium** é a identidade oficial do app, focada em conforto visual para usuários neurodivergentes.

*   **Estética:** Glassmorphism, gradientes profundos, bordas suaves e sombras sutis.
*   **Cores:** Centralizadas em `lib/core/constants/colors.dart` (`AppColors`).
*   **Modularização da Home:** A `HomeView` foi refatorada para isolar seções estáticas de blocos reativos. O widget `HomeDynamicContent` centraliza os `StreamBuilders`, evitando rebuilds desnecessários no restante da tela.

---

## 5. Fluxos de Negócio

### 5.1 Solicitação de Carteirinha
1.  **Cadastro de Membro:** O usuário fornece dados cadastrais necessários.
2.  **Apoio Documental:** Quando necessário, documentos de apoio são enviados por fluxo externo integrado ao Google Drive/GAS, sem armazenamento pesado direto no app. O app prioriza armazenamento leve, mantendo apenas dados textuais estruturados no Supabase.
3.  **Processamento Externo:** O GAS processa e organiza os arquivos após a análise administrativa, apoiando boas práticas de privacidade e limpeza dos dados.
4.  **Ciclo de Status:** `waiting_approval` ➡️ `under_review` ➡️ `active` (ou `rejected`/`waiting_docs`).

### 5.2 Segurança Supabase
*   **RLS (Row Level Security):** Políticas granulares no PostgreSQL garantem que usuários acessem apenas seus próprios dados.
*   **Proteção Admin:** Remoção de fallbacks de administração no código cliente. A verificação de roles é feita via RPC (`get_admin_notification_targets`) e políticas de banco, protegendo perfis administrativos contra manipulação.
*   **Roles:** `user`, `admin`, `admin_master`, `admin_dev`.

---

## 6. Banco de Dados (PostgreSQL)
Tabelas principais:
*   `profiles`: Dados mestre dos usuários (CPF, Role, Contato).
*   `members`: Dependentes/Titulares vinculados a um perfil.
*   `card_requests`: Histórico e estado das solicitações de carteirinha.
*   `digital_cards`: Dados técnicos das carteirinhas emitidas (número, QR token, validade).
*   `notifications`: Registro de alertas e comunicações do sistema.

---

## 7. Notificações
*   **Internas:** Gerenciadas via tabela no banco e exibidas no Mural.
*   **Push (Mobile):** Integração com OneSignal. **Regra Crítica:** Chaves REST sensíveis nunca são expostas no código cliente; o disparo real é delegado a Edge Functions ou serviços de backend.

---

## 8. HomeView Modular (Pós-Fase 13)
A estrutura atual da `HomeView` segue o padrão de **Orquestração de Estado**:
*   A View principal coordena os Streams e Callbacks.
*   `HomeDynamicContent` encapsula a pirâmide de `StreamBuilders` (membros, requests, cards).
*   Widgets extraídos (Header, Banners, Sections) recebem dados prontos, melhorando a performance de renderização.
*   **Nota Técnica:** A descentralização total dos streams foi evitada para manter a estabilidade e sincronismo dos estados vinculados entre si.

---

## 9. Regras de Desenvolvimento
*   **Idioma:** Comentários e documentação em **Português Brasileiro (PT-BR)**.
*   **Validação:** Testar obrigatoriamente em emulador ou dispositivo físico **Android**.
*   **Privacidade:** Proibido armazenar dados sensíveis em logs ou variáveis não protegidas.
*   **Qualidade:** Rodar `flutter analyze` e formatar o código antes de qualquer submissão.

---

## 10. Roadmap Técnico

### 🏗️ Fase 14 (Próximo Passo)
*   **Auditoria de Requests:** Revisão profunda da pasta `lib/features/requests`.
*   **Modularização de Formulários:** Extração de lógica de validação e controllers.
*   **Revisão Administrativa:** Melhorias no fluxo de aprovação e filtros de auditoria.

### 🚀 Evolução
*   **Edge Functions:** Migração dos disparos OneSignal para funções server-side.
*   **Acessibilidade Premium:** Implementação de suporte a leitores de tela e contrastes dinâmicos.
*   **Projeto Fada do Dente:** Preparação da base de dados para o novo módulo de integração.
*   **Build de Release:** Otimização do tamanho do APK e preparação para distribuição.

---

## 11. Checklist de Validação
Antes de finalizar qualquer tarefa, o desenvolvedor deve garantir:
1.  `flutter analyze` (Sem erros ou warnings críticos).
2.  `flutter build apk --debug` (Sucesso na compilação).
3.  `git diff --check` (Sem espaços em branco ou conflitos).
4.  **Teste Visual:** Verificação manual da Home e fluxo afetado no Android.

---
*Documentação Técnica v3.5.0 — Família TEA Bauru 💙*
