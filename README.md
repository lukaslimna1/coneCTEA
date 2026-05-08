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

### 🛡️ Fase 7: Sistema de Roles & RBAC Multinível (v3.0.0 - Atual)
*   **Cargos Diferenciados**: Implementação de cargos `ADM`, `ADM Master` e `ADM DEV`.
*   **Gestão Hierárquica**: Somente Master e DEV podem atribuir cargos administrativos.
*   **Segurança a Nível de Banco (RLS)**: Proteção direta no PostgreSQL para impedir alterações não autorizadas de permissões.
*   **Acesso Total DEV**: Capacidade de edição manual de perfis para manutenção emergencial via App.

### 🔐 Fase 6: Hardening de Segurança (v2.9.0)
*   **Segurança no Cadastro**: Validação em tempo real de unicidade para E-mail e CPF, evitando duplicidade e inconsistência de dados.
*   **Algoritmo de CPF**: Validação matemática de CPF integrada no formulário de registro.
*   **Gate de Solicitação**: Bloqueio inteligente de solicitações de carteirinha para perfis incompletos, garantindo a qualidade da base de dados.
*   **Recuperação de Senha**: Implementação de fluxo de recuperação via e-mail.

### 🔐 Fase 5: Validação Offline & Segurança QR (v2.8.0)
*   **Validação Interna**: Migração de URLs públicas para Tokens internos (`TEA-ID-HEXA`), garantindo que a validação ocorra exclusivamente dentro do ecossistema ConeCTEA.
*   **Scanner Robusto**: Implementação de sistema de leitura de QR Code com extração inteligente de dados.

### 💎 Fase 4: UX & Sincronização Total (v2.7.x)
*   **Busca Inteligente (IBGE)**: Implementação de Autocomplete com `SearchAnchor` para Estados e Cidades.
*   **Zero Data Loss**: Sincronização automatizada via SQL Triggers no Supabase.

### 🏗️ Fase 3: Dashboard & Performance (v2.6.x)
*   **Admin 2.0**: Novo painel administrativo modular com filtros de status e integração com Google Drive.

---

## 🔮 Roadmap: O Futuro da Inclusão

- [x] **🌍 Validação Híbrida**: Scanner de QR Code funcional.
- [x] **🛡️ Hardening de Segurança**: Validação de CPF e unicidade de dados.
- [ ] **🎁 Módulo de Benefícios**: Catálogo interativo de descontos e parcerias.
- [ ] **🔔 Notificações Ativas**: Alertas inteligentes sobre renovação de laudos.
- [ ] **📄 Exportação PDF**: Geração de via para impressão em alta definição.

---

## 🛠️ Stack Tecnológica

*   **Front-end**: Flutter (Dart) com Material 3.
*   **Back-end**: Supabase (PostgreSQL, Auth, Storage, Realtime).
*   **APIs Externas**: IBGE (Localidades).

---

## 🤝 Contribuição e Propósito

Este projeto é mantido em colaboração com a **Família TEA Bauru**.

> "Acolher, Conscientizar e Fortalecer." — **Família TEA Bauru**

---
<p align="center">
  Desenvolvido por <b>Antigravity</b> para a <b>Família TEA Bauru</b> 💙
</p>
