<p align="center">
  <img src="assets/images/logo.png" alt="ConeCTEA Logo" width="130">
  <br><br>
  <strong>Tecnologia, Acolhimento e Inclusão na Palma da Mão.</strong>
  <br>
  <em>Desenvolvido com carinho para a rede de apoio <strong>Família TEA Bauru</strong>.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Versão-3.0.0-7C3AED" alt="Versão">
  <img src="https://img.shields.io/badge/LGPD-Compliant-10B981" alt="LGPD">
</p>

---

## 💙 Sobre o Projeto

O **ConeCTEA** é o hub tecnológico da **Família TEA Bauru** — uma iniciativa que transforma burocracia em acolhimento. O aplicativo centraliza a identificação digital (carteirinha), o gerenciamento de dependentes e o acesso facilitado a serviços e informações para pessoas com Transtorno do Espectro Autista (TEA) e suas famílias.

> "Acolher, Conscientizar e Fortalecer." — **Família TEA Bauru**

---

## ✨ Funcionalidades Principais

| Área | Funcionalidade |
|---|---|
| 🪪 **Identificação** | Carteirinha Digital com QR Code seguro e validação offline |
| 👨‍👩‍👧 **Dependentes** | Cadastro e gerenciamento de membros da família |
| 📋 **Solicitações** | Fluxo completo de solicitação e acompanhamento de carteirinhas |
| 🛡️ **Admin** | Painel administrativo com filtros, aprovações e gestão de documentos |
| 🔐 **Segurança** | RBAC multinível, RLS no banco, validação de CPF, LGPD compliant |
| 📱 **Scanner** | Leitura de QR Code interno para validação em eventos |
| 🔔 **Notificações** | Push Notifications via OneSignal (mobile) |

---

## 🛤️ Histórico de Versões

### 🎨 v3.1.0 — UI/UX Premium & Conformidade Legal *(atual)*
- **Design System Unificado**: Background `#F6F8FC` (branco azulado) aplicado em todas as telas
- **Acessibilidade**: Contraste de texto elevado para legibilidade máxima (WCAG AA)
- **Alinhamento**: Cards de acesso rápido sempre alinhados à esquerda com scroll horizontal consistente
- **LGPD**: Política de Privacidade completa e Termos de Uso integrados ao app
- **Documentação**: README e DOC Técnico reestruturados

### 🛡️ v3.0.0 — Sistema de Roles & RBAC Multinível
- Cargos diferenciados: `user`, `admin`, `admin_master`, `admin_dev`
- Gestão hierárquica: somente Master e DEV podem atribuir cargos administrativos
- Segurança a nível de banco (RLS) no PostgreSQL

### 🔐 v2.9.0 — Hardening de Segurança
- Validação em tempo real de unicidade para E-mail e CPF
- Algoritmo matemático de validação de CPF no formulário
- Gate de solicitação: bloqueia carteirinha para perfis incompletos
- Fluxo de recuperação de senha via e-mail

### 📡 v2.8.0 — Validação Offline & QR Seguro
- Migração de URLs públicas para tokens internos (`TEA-ID-HEXA`)
- Scanner robusto com `mobile_scanner` e extração inteligente de dados

### 💎 v2.7.x — UX & Sincronização Total
- Autocomplete inteligente (IBGE) para cidades e estados
- Sincronização automática via SQL Triggers no Supabase
- Zero Data Loss na criação de perfis

### 🏗️ v2.6.x — Dashboard Administrativo
- Painel admin modular com filtros de status
- Integração com Google Drive para gestão de documentos

---

## 🔮 Roadmap

- [x] 🌍 Scanner de QR Code funcional
- [x] 🛡️ Hardening de Segurança (CPF, unicidade, RLS)
- [x] 🎨 Design System Premium e LGPD
- [ ] 🎁 Módulo de Benefícios — catálogo de descontos e parcerias
- [ ] 🔔 Notificações Ativas — alertas de renovação de laudo
- [ ] 📄 Exportação PDF — via para impressão em alta definição
- [ ] 🌐 Portal Web Admin — interface complementar ao app

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| **Front-end** | Flutter 3.22+ (Dart) — Material 3 |
| **Navegação** | `go_router` — Rotas declarativas e tipadas |
| **Back-end** | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| **Notificações** | OneSignal (Push Notifications mobile) |
| **Localização** | API IBGE — cidades e estados |
| **Documentos** | Google Drive API (upload e exclusão) |
| **Fontes** | Google Fonts — Inter |

---

## 🗂️ Estrutura do Projeto

```
lib/
├── app/
│   ├── routes.dart          # Roteamento declarativo (go_router)
│   └── theme.dart           # Tema global Material 3
├── core/
│   ├── constants/
│   │   └── colors.dart      # Design System — paleta de cores
│   ├── notifiers/
│   │   └── auth_notifier.dart  # Estado global de autenticação
│   └── widgets/
│       └── bottom_nav.dart  # Navegação inferior
├── features/
│   ├── admin/               # Painel administrativo (RBAC)
│   ├── auth/                # Login, Registro e Recuperação de Senha
│   ├── account/             # Perfil, Segurança, Privacidade, Consentimentos
│   ├── cards/               # Carteirinha Digital (visualização e QR)
│   ├── home/                # Home Screen — orquestrador principal
│   ├── legal/               # Termos de Uso e Política de Privacidade
│   ├── requests/            # Fluxo de Solicitação de Carteirinha
│   └── splash/              # Splash Screen com verificação de auth
├── models/                  # DTOs e serialização (AppUser, Member, DigitalCard, etc.)
├── services/
│   ├── auth_service.dart    # Auth & User Metadata
│   ├── database_service.dart # CRUD & Realtime (Supabase)
│   └── drive_service.dart   # Google Drive API
└── main.dart                # Bootstrap — Supabase + OneSignal
```

---

## 🚀 Como Executar

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/conectea.git
cd conectea

# Instalar dependências
flutter pub get

# Rodar em modo de desenvolvimento
flutter run

# Build para produção (Android)
flutter build apk --release
```

> **Pré-requisito:** Configure as variáveis do Supabase em `main.dart` com sua URL e chave anônima.

---

## 🤝 Contribuição

Este projeto é mantido em colaboração com a **Família TEA Bauru**. Para contribuir, abra uma issue ou pull request.

- 📸 Instagram: [@familiateabauru](https://www.instagram.com/familiateabauru)
- 📍 Bauru — SP, Brasil

---

<p align="center">
  Desenvolvido com 💙 para a <strong>Família TEA Bauru</strong>
  <br>
  <sub>ConeCTEA v3.1.0 — 2026</sub>
</p>
