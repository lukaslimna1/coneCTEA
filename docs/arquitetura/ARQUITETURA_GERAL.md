# Arquitetura Geral — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

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
    *   O Chrome DevTools é utilizado apenas como fallback visual inicial e testes rápidos de layout. Possui limitações conhecidas em operações diretas com Google Apps Script (Drive Delete) devido a restrições de CORS.
    *   A validação principal ocorre em emuladores Android e perfis Samsung-like (A05/A55/S24). Mobile/emulador é o alvo oficial validado para fluxos de documentos.
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
