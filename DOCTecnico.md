# 📘 Documentação Técnica — ConeCTEA
**App:** 0.4.0-dev | **Documentação:** 4.0.0 | **Status:** Desenvolvimento
<br>
**Atualizado em:** 14/05/2026

---

## 1. Visão Técnica
O **ConeCTEA** é um ecossistema mobile-first preparado para evolução contínua, utilizando uma arquitetura modular baseada em funcionalidades (**features**). O projeto foca na separação rigorosa de preocupações, governança de dados sensíveis e blindagem de segurança na interface do usuário. A entrega principal é focada no Android, com um design system premium (Night Blue) que prioriza o conforto visual para usuários neurodivergentes.

---

## 2. Stack Tecnológica
*   **Core:** Flutter 3.41.9 / Dart 3.11.5.
*   **Backend:** Supabase (PostgreSQL + Auth + Realtime + RLS).
*   **Serverless:** Supabase Edge Functions (Deno) para fluxos sensíveis e integrações de backend.
*   **Push Notifications:** OneSignal para alertas em tempo real (inicialização e login implementados).
*   **Automação:** Google Apps Script (GAS) para apoio na gestão documental e integração com Google Drive.
*   **Design & UI:**
    *   Google Fonts (Outfit & Inter).
    *   Phosphor Icons & Flutter SVG.
    *   Shimmer para estados de carregamento.
*   **Utilidades:** `go_router` (navegação), `url_launcher` (links externos), `sensors_plus` (parallax).
*   **Plataforma Alvo:**
    *   Android é a prioridade total do ecossistema.
    *   O Chrome DevTools é utilizado apenas como fallback visual inicial e testes rápidos de layout.
    *   A validação principal ocorre em emuladores Android e perfis Samsung-like (A05/A55).
    *   Testes em dispositivo físico são pontuais e realizados conforme disponibilidade.

---

## 3. Arquitetura e Organização
O projeto utiliza uma estrutura baseada em funcionalidades (**features**), permitindo isolamento de código e facilidade de manutenção.

### 3.1 Estrutura de Pastas (Modularizada)
```text
lib/
├── app/                  # Configurações globais, rotas e tema.
├── core/                 # Base reutilizável, constantes e widgets de UI.
├── features/             # Domínios de negócio isolados.
│   ├── account/          # Central do Usuário (Perfil, Segurança, Suporte, LGPD).
│   │   ├── profile/      # Edição de perfil e widgets específicos.
│   │   ├── security/     # Gestão de credenciais.
│   │   ├── legal/        # Transparência e dados (Consents).
│   │   ├── institutional/# Telas institucionais (Sobre, Família TEA).
│   │   └── support/      # Central de ajuda.
│   ├── admin/            # Dashboard administrativo e scanner.
│   │   ├── widgets/      # Abas de usuários/solicitações e diálogos.
│   │   └── scanner_view.dart
│   ├── auth/             # Fluxos de login, registro e recuperação.
│   │   ├── widgets/      # Componentes modulares do registro.
│   │   └── content/      # Textos e constantes de onboarding.
│   ├── cards/            # Gestão e visualização de carteirinhas.
│   ├── home/             # Dashboard principal e seções dinâmicas.
│   ├── notifications/    # Gestão de alertas e notificações.
│   └── requests/         # Fluxo de submissão de membros.
│       └── add_member_page.dart
├── models/               # Classes de dados.
└── services/             # Lógica de integração (Supabase, Database).

supabase/
└── functions/            # Edge Functions (Ex: recover-email-by-cpf).
```

---

## 4. Design System — Night Blue Premium
O padrão **Night Blue Premium** é a identidade oficial do app, focada em conforto visual para usuários neurodivergentes.

*   **Estética:** Glassmorphism, gradientes profundos, bordas suaves e sombras sutis.
*   **Cores:** Centralizadas em `lib/core/constants/colors.dart` (`AppColors`).
*   **Modularização da Home:** A `HomeView` isola seções estáticas de blocos reativos através do `HomeDynamicContent`.

---

## 5. Fluxos de Negócio

### 5.1 Autenticação e Onboarding (Auth)
O fluxo de autenticação foi refinado visualmente, estabilizado e modularizado:
*   **Login:** Interface com scroll natural, contraste aprimorado em ícones e links, e fundo Night Blue Premium consistente.
*   **Recuperação de Senha:** Fluxo nativo via Supabase Auth com mensagens seguras/neutras e botões no padrão premium.
*   **Recuperação de E-mail (Edge Function):** Implementado fluxo seguro via CPF e Edge Function `recover-email-by-cpf`. A interface foi personalizada com a logo ConeCTEA, Hero `app_logo`, campos com ícones brancos e foco em roxo.
*   **Cadastro (Criar conta):**
    *   Textos otimizados para legibilidade e links em ciano.
    *   Botão "Criar minha conta" em estilo `premiumCard` com `greenAccent`.
    *   Inputs e dropdowns padronizados com ícones brancos.
    *   Seções organizadas por cores semânticas: Dados Pessoais (ciano/oceano), Localização (verde), Segurança (azul claro) e Dados complementares (branco discreto).
*   **Modais Legais:** Leitura de Termos de Uso e Política de Privacidade organizada por blocos/cards internos para melhor escaneabilidade.
*   **Consentimentos:** Checkboxes (LGPD) com bordas desmarcadas mais visíveis e estados claros.
*   **Segurança:** Mensagens técnicas conhecidas foram substituídas por feedbacks amigáveis.
*   **Responsividade:** A responsividade global de textos segue como um ponto de atenção para ciclos futuros.

### 5.2 Painel Administrativo (Admin)
Área restrita para gestão da associação, organizada por abas:
*   **Orquestração:** A `AdminView` gerencia a navegação entre as abas de solicitações e usuários.
*   **Solicitações:** `AdminRequestsTab` lista processos pendentes com filtros de status.
*   **Usuários:** `AdminUsersTab` permite a busca e gestão de permissões.
*   **Scanner:** `ScannerView` higienizada, utilizada para validar a autenticidade das carteirinhas via QR Code.
*   **Segurança:** Logs sensíveis identificados na auditoria foram higienizados (remoção de IDs ou códigos brutos).

### 5.3 Central do Usuário (Account)
A `AccountView` foi consolidada como o hub de serviços do usuário, dividida em 6 cards principais:
*   **Meus Dados:** acesso à `EditProfileView` modularizada.
*   **Segurança:** gestão de credenciais e troca de senha.
*   **Privacidade:** `ConsentsView` como tela de transparência sobre dados, consentimentos necessários e autorizações futuras.
*   **Ajuda:** `HelpSupportView` com FAQ e canais oficiais.
*   **Institucional:** informações sobre o ConeCTEA e a Família TEA Bauru.
*   **Aplicativo:** informações sobre versão/build e detalhes técnicos do app.

> [!IMPORTANT]
> **Restrições de dados sensíveis:** CPF e e-mail permanecem bloqueados para edição direta e exigem suporte administrativo.

### 5.4 Solicitação de Carteirinha (Requests)
O fluxo foi consolidado e modularizado:
*   **Fluxo Direto:** Acesso via Home ou Cards diretamente para `AddMemberPage`.
*   **Validação Real:** Implementada validação algorítmica de CPF (`request_cpf_validator.dart`).
*   **Status Legado:** O sistema trata o status `under_review` e exibe feedbacks visuais apropriados na `RequestsView`.
*   **Segurança:** Ciclo de segurança imediata executado nas áreas auditadas, com feedbacks seguros ao usuário.
*   **Depreciação:** `MemberSelectionPage` e `NewRequestPage` foram removidas em favor da `AddMemberPage`.

### 5.5 Área de Carteirinhas (CardsView)
A visualização de carteirinhas foi totalmente modularizada:
*   **Orquestração:** `CardsView` gerencia streams, seleção de membros e troca de estados.
*   **Estados Extraídos:** Componentes específicos para estados de `empty`, `pending` (aguardando aprovação) e `error`.
*   **Acessibilidade:** O CTA "Cadastrar novo dependente" foi reposicionado para garantir visibilidade fora do seletor de membros.

### 5.6 Carteirinha Digital (DigitalCardWidget)
Componente modular e performático:
*   `digital_card_widget.dart`: Orquestrador de flip, animação e controle de visibilidade do CPF.
*   `digital_card_front.dart`: Interface frontal com dados principais e status.
*   `digital_card_back.dart`: Verso contendo QR Code para validação administrativa e texto legal.
*   `digital_card_background.dart` e `digital_card_motion_wrapper.dart`: Estética premium e parallax.

### 5.7 Tela Cheia Adaptativa (FullScreenCardPage)
Implementação de responsividade defensiva:
*   **Portrait/Landscape:** Layouts otimizados com `SingleChildScrollView` e `FittedBox` para evitar overflows em qualquer resolução Android.

### 5.8 Supabase Edge Functions
Documentação de funções serverless implementadas:
*   **recover-email-by-cpf:**
    *   **Objetivo:** Recuperação segura de e-mail através do CPF do usuário.
    *   **Segurança:** Utiliza `service_role` exclusivamente no backend. O aplicativo recebe apenas os campos `found` (boolean), `masked_email` (ex: `l***@email.com`) e `email_sent` (se o fluxo de reset foi disparado). O e-mail completo nunca retorna ao frontend.
    *   **Configuração:** `verify_jwt = false` configurado para permitir o início do fluxo por usuários anônimos (pré-login).
    *   **Dependência:** A função deve estar corretamente deployada e ativa no projeto Supabase.

---

## 6. Segurança e Dados
*   **Blindagem de UI:** Mensagens técnicas conhecidas foram substituídas por feedbacks amigáveis nas áreas auditadas (Auth, Admin, Account, Home, Requests, Notifications).
*   **Higienização de Logs:** Logs sensíveis identificados na auditoria foram higienizados (remoção de IDs, CPFs e códigos brutos de QR Code).
*   **RLS (Row Level Security):** Políticas granulares no PostgreSQL garantem que usuários acessem apenas seus próprios dados.
*   **Roles:** Hierarquia de acesso controlada (`user`, `admin`, `admin_master`, `admin_dev`).
*   **Privacidade & LGPD:** A `ConsentsView` atua como tela de transparência sobre dados e autorizações. A persistência granular com histórico e revogação digital permanece como roadmap futuro.

---

## 7. Regras de Desenvolvimento e Validação
*   **Idioma:** Toda a comunicação, comentários e documentação em **Português Brasileiro (PT-BR)**.
*   **Validação Android:** Priorizar validação em emuladores Android e perfis Samsung-like. O Chrome DevTools pode ser usado apenas como fallback visual inicial. Testes em hardware real são pontuais.
*   **Padrão de Código:** Proibido o uso de `git add .`. Commits devem ser descritivos e em português.

### 7.1 Infraestrutura de QA Android Local
O projeto mantém scripts de automação em `tools/qa/android/` para agilizar a validação em diferentes perfis:
*   **Perfis/Emuladores do Ciclo Atual:**
    *   `Android_Small_360dp_QA` (Referência de layout compacto).
    *   `Android_Medium_412dp_QA` (Referência de layout médio).
    *   `Samsung_A05_Small` (Perfil de entrada).
    *   `Samsung_A55_Like` (Perfil moderno/premium).
*   **Protocolo Técnico:**
    *   Uso da flag `-no-snapshot-load` nos scripts para garantir um "Cold Boot" limpo e evitar travamentos por snapshots corrompidos.
    *   Atenção redobrada ao abrir múltiplos emuladores, pois os IDs de dispositivo (ex: `emulator-5554`) podem alternar entre os perfis abertos.

---

## 8. Roadmap Técnico

### ✅ Concluído Recentemente (Ciclo de Segurança e Modularização)
*   **Blindagem UI:** Mensagens técnicas conhecidas substituídas por feedbacks amigáveis.
*   **Higienização:** Logs sensíveis identificados na auditoria foram higienizados.
*   **Auth v2:** Modularização do registro e recuperação de e-mail via Edge Functions.
*   **Admin v2:** Painel administrativo por abas e scanner higienizado.
*   **Account v2:** Central do Usuário consolidada com 6 cards principais.
*   **Requests v2:** Fluxo de `AddMemberPage` blindado e simplificado nas áreas auditadas.

### 🏗️ Próxima Direção (Prioridades)
*   **Home, Header & Navbar:** Refino estético completo do cabeçalho, barra de navegação e dashboard principal.
*   **Design System Global:** Padronização final de componentes (botões, inputs, cards) e centralização de estilos.
*   **QA Android:** Manutenção da matriz de emuladores e scripts de automação.
*   **Responsividade de Textos:** Estudo de solução global para escalonamento de fontes.

### ⏳ Futuro / Backlog
*   **Saúde:** Projeto Fada do Dente e integração de serviços.
*   **Push:** Expansão avançada do OneSignal para alertas automáticos.
*   **Geolocalização:** Implementação de `LocationService` (IBGE).
*   **Arquitetura:** Refatoração de lógica para Controllers/Services dedicados.
*   **Suporte:** Canal de suporte interno integrado ao app.
*   **Revisão Jurídica:** Atualização profunda dos textos legais (Termos e Privacidade) e integração com fluxos de GAS/Sheets/Drive para gestão de documentos (laudos, RG, CNH).
*   **Privacidade:** Persistência real e granular de consentimentos com histórico de aceites e revogações.
*   **Admin:** Edge Functions/RPC administrativas e audit log de ações.
*   **Conteúdo:** Módulos de eventos, projetos, parceiros e consultas.
*   **BI:** Relatórios estatísticos agregados para a gestão.
*   **UX:** Tema claro e suporte a modo offline básico.

---

## 9. Checklist de Validação
Antes de finalizar qualquer tarefa:
1.  `flutter analyze` (sem issues).
2.  `flutter build apk --debug` (Sucesso na compilação).
3.  `git diff --check` (Sem erros de formatação).
4.  `git status --short` (Verificar arquivos modificados).
5.  **Teste Visual:** Validar o fluxo afetado em modo Portrait e Landscape (Android).
6.  **Sem Commits/Push Automáticos:** O assistente nunca faz commit ou push sem autorização.

---
*ConeCTEA App 0.4.0-dev | Documentação Técnica 4.0.0 — Família TEA Bauru 💙*
