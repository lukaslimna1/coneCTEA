<p align="center">
  <img src="assets/images/conectea_logo.png" alt="ConeCTEA Logo" width="130">
  <br><br>
  <strong>ConeCTEA</strong><br>
  <em>Tecnologia, Acolhimento e Inclusão na Palma da Mão.</em>
  <br><br>
  <strong>App oficial da Família TEA Bauru para conexão, identificação digital e acompanhamento de solicitações.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.9-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Versão-4.0.0-8B3DFF?logo=flutter" alt="Versão">
  <img src="https://img.shields.io/badge/Segurança-Protegida-success?logo=google-cloud" alt="Segurança">
</p>

---

## 🌟 Visão Geral
O **ConeCTEA** é uma solução tecnológica mobile-first criada para apoiar a comunidade vinculada à **Família TEA Bauru**. O ecossistema organiza a identidade digital dos membros através do design system **Night Blue Premium**, focado em conforto visual para usuários neurodivergentes e governança robusta de dados.

> [!IMPORTANT]
> **Aviso Legal:** A carteirinha emitida pelo ConeCTEA é um documento de identificação **interno** para uso exclusivo nos projetos e parcerias da Família TEA Bauru. Ela **não substitui a CIPTEA oficial** governamental.

## 🚀 Principais Funcionalidades

*   🔐 **Autenticação Modular:** Fluxos de Login, Registro e Recuperação totalmente revisados e protegidos.
*   👤 **Central do Usuário (Account v2):** Experiência organizada em 6 cards principais: Meus Dados, Segurança, Privacidade, Ajuda, Institucional e Aplicativo.
*   🛡️ **Blindagem contra exposição de erros técnicos:** Interface protegida onde erros brutos de banco ou rede não são exibidos ao usuário. Logs sensíveis foram higienizados para preservar a privacidade do ambiente.
*   ⚖️ **Transparência de Dados (LGPD):** Área dedicada à clareza sobre dados necessários, preferências e autorizações. A persistência real com histórico de revogação é um item de roadmap futuro.
*   👨‍👩‍👧 **Fluxo de Membros (Requests):** Cadastro de dependentes com validação real de CPF e acompanhamento de status em tempo real.
*   💎 **Carteirinha Digital Premium:** Identidade visual premium com efeito flip 3D, sensor de movimento e QR Code para validação administrativa.
*   📱 **Tela Cheia Adaptativa:** Visualização defensiva otimizada para os modos Retrato e Paisagem no Android.
*   📢 **Painel Administrativo:** Gestão de solicitações, auditoria de usuários e Scanner de validação integrado.

---

## 💎 Diferenciais do Projeto

*   **Design Night Blue:** Paleta profunda e interfaces suaves desenhadas para reduzir sobrecarga sensorial.
*   **Arquitetura por Features:** Organização modular que isola domínios de negócio, facilitando a manutenção.
*   **Privacidade por Design:** Governança rigorosa via Supabase Row Level Security (RLS).
*   **Android-First:** Validação rigorosa em dispositivos físicos para garantir estabilidade real.

---

## 🗺️ Roadmap de Evolução

### ✅ Concluído (Maturidade Estabilizada)
- **Segurança da UI:** Blindagem de mensagens de erro e higienização de logs.
- **Central do Usuário:** Reestruturação modular da área de conta e perfil.
- **Módulo Auth:** Modularização e refino visual dos fluxos de acesso.
- **Admin & Scanner:** Implementação da visão administrativa e validador de QR Code.
- **Digital Card:** Consolidação da carteirinha modular (Frente/Verso/Motion).

### 🏗️ Próxima Direção (Prioritário)
- **Design System Global:** Padronização final de componentes de UI, cards, botões e inputs.
- **Refino de Layout:** Ajustes na Home, Header e Navbar.
- **Fluxos de Operação:** Melhorias em Solicitações e Notificações.
- **QA & Responsividade:** Testes extensivos no Chrome e em dispositivos Android (emuladores e físicos).

### 🔮 Futuro (Backlog Técnico e Produto)
- **Governança LGPD:** Persistência real de consentimentos com histórico e gestão de versões.
- **Suporte Integrado:** Gestão de chamados de suporte diretamente pelo painel Admin.
- **Hardening Admin:** Edge Functions/RPC para ações sensíveis e Audit Log administrativo.
- **Expansão Institucional:** Módulo de Eventos, Projetos, Consultas e Parceiros.
- **Inteligência de Dados:** Relatórios estatísticos agregados para apoio à associação.
- **Otimização de Serviços:** `LocationService` (IBGE) e desacoplamento via Controllers/Services.
- **Novas Features:** Modo offline básico, Tema Claro e integração com o projeto **"Fada do Dente"**.

---

## 🛠️ Tecnologias Usadas
*   **Frontend:** Flutter & Dart.
*   **Backend:** Supabase (PostgreSQL, Auth, Realtime, RLS).
*   **Serverless:** Supabase Edge Functions (Deno) para fluxos de e-mail.
*   **Push:** OneSignal para notificações (inicialização e login implementados).
*   **Design:** Google Fonts (Outfit), Phosphor Icons, Shimmer.

---

## 📘 Documentação Técnica
Para detalhes sobre arquitetura e fluxos internos, consulte o [DOCTecnico.md](DOCTecnico.md).

---

## 💙 Sobre a Família TEA Bauru
A Família TEA Bauru é uma associação sem fins lucrativos dedicada ao acolhimento e defesa dos direitos das pessoas com autismo em Bauru-SP.

## 👨‍💻 Desenvolvimento
Projeto desenvolvido por **Lucas Lima**.
Portfólio: [lucaslimadigital.vercel.app](https://lucaslimadigital.vercel.app)

---
*ConeCTEA v4.0.0 — 2026*
