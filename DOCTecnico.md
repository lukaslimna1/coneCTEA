# 📘 Documentação Técnica — ConeCTEA
**Versão:** 4.0.0 | **Atualizado em:** 12/05/2026

---

## 1. Visão Técnica
O **ConeCTEA** é um ecossistema mobile-first preparado para evolução contínua, utilizando uma arquitetura modular que separa preocupações de negócio, interface e dados. O foco principal é a entrega de uma experiência estável no Android, com governança de dados sensíveis e boas práticas de privacidade por design.

---

## 2. Stack Tecnológica
*   **Core:** Flutter 3.41.9 / Dart 3.11.5.
*   **Backend:** Supabase (PostgreSQL + Auth + Realtime + RLS/RPC).
*   **Plataforma Alvo:** Android (Prioridade total). iOS é uma possibilidade futura e não possui versão pronta.
*   **Web:** O projeto **não é um web app**. O uso do Chrome DevTools é restrito a testes rápidos de layout (fallback visual); a validação oficial e final ocorre obrigatoriamente em dispositivos Android reais.

---

## 3. Arquitetura e Organização
O projeto utiliza uma estrutura baseada em funcionalidades (**features**), permitindo isolamento de código e facilidade de manutenção.

### 3.1 Estrutura de Pastas (Modularizada)
```text
lib/
├── app/                  # Configurações globais, rotas (go_router) e tema.
├── core/                 # Base reutilizável, constantes (AppColors) e utils.
│   └── widgets/          # Widgets premium (Night Blue Design System).
├── features/             # Domínios de negócio isolados.
│   ├── account/          # Perfil, segurança e telas institucionais.
│   ├── admin/            # Dashboard administrativo e scanner de validação.
│   ├── auth/             # Fluxos de login, registro e recuperação.
│   ├── cards/            # Gestão e visualização de carteirinhas.
│   │   ├── full_screen_card_page.dart # Tela cheia adaptativa.
│   │   ├── widgets/
│   │   │   ├── carteirinha_digital/   # Componentes da carteira (Front, Back, etc).
│   │   │   └── tela_carteirinhas/     # Componentes da View (Selector, States).
│   ├── home/             # Dashboard do usuário e seções dinâmicas.
│   ├── notifications/    # Gestão de alertas internos.
│   └── requests/         # Fluxo de submissão de membros e documentos.
│       ├── add_member_page.dart       # Fluxo principal de cadastro.
│       ├── requests_view.dart         # Acompanhamento de solicitações.
│       └── utils/                     # Validadores (CPF, etc).
├── models/               # Classes de dados (Data Models).
└── services/             # Lógica de integração (Supabase, Auth, Drive/GAS).
```

---

## 4. Design System — Night Blue Premium
O padrão **Night Blue Premium** é a identidade oficial do app, focada em conforto visual para usuários neurodivergentes.

*   **Estética:** Glassmorphism, gradientes profundos, bordas suaves e sombras sutis.
*   **Cores:** Centralizadas em `lib/core/constants/colors.dart` (`AppColors`).
*   **Modularização da Home:** A `HomeView` isola seções estáticas de blocos reativos através do `HomeDynamicContent`.

---

## 5. Fluxos de Negócio

### 5.1 Solicitação de Carteirinha (Requests)
O fluxo foi consolidado e simplificado:
*   **Fluxo Direto:** Acesso via Home ou Cards diretamente para `AddMemberPage`.
*   **Validação Real:** Implementada validação algorítmica de CPF (`request_cpf_validator.dart`).
*   **Status Legado:** O sistema trata o status `under_review` e exibe feedbacks visuais apropriados na `RequestsView`.
*   **Segurança:** Removidos toques falsos em cards não acionáveis e componentes de carregamento desnecessários (como RefreshIndicator em listas vazias).
*   **Depreciação:** `MemberSelectionPage` e `NewRequestPage` foram removidas do fluxo ativo em favor da `AddMemberPage` modularizada.

### 5.2 Área de Carteirinhas (CardsView)
A visualização de carteirinhas foi totalmente modularizada:
*   **Orquestração:** `CardsView` gerencia streams, seleção de membros e troca de estados.
*   **Estados Extraídos:** Componentes específicos para estados de `empty`, `pending` (aguardando aprovação) e `error`.
*   **Seção de Detalhes:** Ações e informações extras do membro foram isoladas em `cards_details_section.dart`.
*   **Acessibilidade:** O CTA "Cadastrar novo dependente" foi reposicionado para garantir visibilidade fora do seletor de membros.

### 5.3 Carteirinha Digital (DigitalCardWidget)
Componente modular e performático dividido em:
*   `digital_card_widget.dart`: Orquestrador de flip, animação e controle de visibilidade do CPF.
*   `digital_card_front.dart`: Interface frontal com dados principais, avatar/identificação visual, validade e status.
*   `digital_card_back.dart`: Verso contendo QR Code dinâmico, CPF formatado e texto legal.
*   `digital_card_background.dart`: Camada de fundo com gradientes, marca d'água e formas fluidas.
*   `digital_card_motion_wrapper.dart`: Lógica de sensores e efeito parallax.

> [!NOTE]
> **Aviso Legal:** O texto no verso da carteirinha reforça que o documento é de uso interno e não substitui a CIPTEA oficial ou outros documentos de identificação governamentais.

### 5.4 Tela Cheia Adaptativa (FullScreenCardPage)
Implementação de responsividade defensiva:
*   **Portrait:** Usa `SingleChildScrollView` para evitar overflows em telas curtas.
*   **Landscape:** Layout horizontal otimizado com restrições de altura (`BoxConstraints`) e escalonamento via `FittedBox`.
*   **Controles:** Botões laterais em modo landscape possuem rolagem própria para garantir acessibilidade em qualquer resolução.
*   **Nota:** A responsividade global do aplicativo ainda é uma frente futura; apenas a área de carteirinhas foi blindada nesta fase.

---

## 6. Segurança e Dados
*   **RLS (Row Level Security):** Políticas granulares no PostgreSQL garantem isolamento de dados por usuário.
*   **Roles:** Hierarquia de acesso (`user`, `admin`, `admin_master`, `admin_dev`).
*   **Privacidade:** Limpeza de documentos via GAS e armazenamento estruturado apenas de metadados sensíveis.

---

## 7. Regras de Desenvolvimento e Validação
*   **Idioma:** Toda a comunicação, comentários e documentação em **Português Brasileiro (PT-BR)**.
*   **Validação Android:** Priorizar validação em dispositivos físicos Android ou emuladores. O Chrome DevTools pode ser usado apenas como fallback visual inicial e não substitui QA Android real.
*   **Padrão de Código:** Proibido o uso de `git add .`. Commits devem ser descritivos e em português.

---

## 8. Roadmap Técnico

### ✅ Concluído Recentemente
*   Consolidação de fluxos de **Requests** e validação de CPF.
*   Modularização completa da **CardsView** e subcomponentes.
*   Reestruturação da **Carteirinha Digital** (Modularização estrutural).
*   Implementação de layout adaptativo e hardening na **FullScreenCardPage**.

### 🏗️ Próximas Frentes
*   **Auth:** Revisão de `login_page`, `register_page` e fluxos de recuperação de senha/e-mail.
*   **Finalização:** Conclusão de páginas secundárias incompletas.
*   **Padronização Visual:** Unificação de componentes de botões e inputs.
*   **Responsividade Global:** Expansão das defesas de layout para todas as telas do app no Android.
*   **Tema Light:** Desenvolvimento da variante clara do design system.
*   **Projeto Fada do Dente:** Integração do novo módulo de serviços.

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
*Documentação Técnica v4.0.0 — Família TEA Bauru 💙*
