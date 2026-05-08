# 🚀 ConeCTEA - Família TEA Bauru

<p align="center">
  <img src="assets/images/logo.png" alt="ConeCTEA Logo" width="120">
  <br>
  <b>Tecnologia, Acolhimento e Inclusão na Palma da Mão.</b>
  <br>
  <i>Desenvolvido com carinho para a rede de apoio <b>Família TEA Bauru</b>.</i>
</p>

---

## 💙 Sobre o Projeto

O **ConeCTEA** não é apenas um aplicativo; é o hub tecnológico da **Família TEA Bauru**. Ele foi projetado para simplificar a vida das famílias atípicas, centralizando a identificação digital (Carteirinha), o gerenciamento de dependentes e o acesso facilitado a serviços e informações essenciais.

Nossa missão é transformar a burocracia em acolhimento, garantindo que cada família tenha suporte e visibilidade.

---

## 🛤️ Jornada de Evolução

A evolução do ConeCTEA é marcada por um compromisso contínuo com a excelência técnica e a sensibilidade humana.

### 🔐 Fase 5: Validação Offline & Segurança QR (v2.8.0 - Atual)
*   **Validação Interna**: Migração de URLs públicas para Tokens internos (`TEA-ID-HEXA`), garantindo que a validação ocorra exclusivamente dentro do ecossistema ConeCTEA.
*   **Scanner Robusto**: Implementação de sistema de leitura de QR Code com extração inteligente de dados, resiliente a variações de formatação e URLs legadas.
*   **Busca Case-Insensitive**: Otimização do backend para reconhecimento de carteirinhas independente de letras maiúsculas/minúsculas.
*   **UX de Scanner**: Feedback visual imediato e logs de auditoria para operadores de acesso.

### 💎 Fase 4: UX & Sincronização Total (v2.7.x)
*   **Busca Inteligente (IBGE)**: Implementação de Autocomplete com `SearchAnchor` para Estados e Cidades, eliminando o "scroll" infinito.
*   **Zero Data Loss**: Sincronização automatizada via SQL Triggers no Supabase, garantindo que perfis nunca fiquem incompletos.
*   **Identidade Fiscal**: Integração do CPF como campo obrigatório no cadastro inicial.

### 🏗️ Fase 3: Dashboard & Performance (v2.6.x)
*   **Admin 2.0**: Novo painel administrativo modular com filtros de status e integração com Google Drive para gestão de documentos.
*   **Visual Shimmer**: Experiência de carregamento fluida e moderna.

### 🔄 Fase 2: Amadurecimento do Backend (v2.5.0)
*   Migração e consolidação total no **Supabase**.
*   Implementação de bloqueios inteligentes de campos para auditoria.

### 📦 Fase 1: Fundação do MVP (v2.0.0)
*   Criação da identidade visual "Premium Dark & Light".
*   Estruturação do fluxo de solicitação de carteirinhas.

---

## 🔮 Roadmap: O Futuro da Inclusão

Nosso compromisso com a Família TEA Bauru vai além do presente. Confira o que estamos construindo:

- [x] **🌍 Validação Híbrida**: Scanner de QR Code funcional para validação rápida de autenticidade (Online/Offline).
- [ ] **🎁 Módulo de Benefícios**: Catálogo interativo de descontos e parcerias em estabelecimentos parceiros em Bauru e região.
- [ ] **🔔 Notificações Ativas**: Alertas inteligentes sobre renovação de laudos e datas de eventos da comunidade.
- [ ] **📄 Exportação PDF**: Geração de via para impressão em alta definição diretamente do aplicativo.
- [ ] **📍 Guia TEA**: Mapa interativo com profissionais e clínicas especializadas com selo de recomendação da Família TEA.

---

## 🛠️ Stack Tecnológica

*   **Front-end**: Flutter (Dart) com Material 3.
*   **Back-end**: Supabase (PostgreSQL, Auth, Storage, Realtime).
*   **Infraestrutura**: Google Cloud / SQL Triggers.
*   **APIs Externas**: IBGE (Localidades).

---

## 🤝 Contribuição e Propósito

Este projeto é mantido em colaboração com a **Família TEA Bauru**. Se você faz parte dessa rede, saiba que cada linha de código foi escrita pensando em facilitar a sua jornada.

> "Acolher, Conscientizar e Fortalecer." — **Família TEA Bauru**

---
<p align="center">
  Desenvolvido por <b>Antigravity</b> para a <b>Família TEA Bauru</b> 💙
</p>
