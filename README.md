# ConeCTEA 📱

App de identificação digital, solicitações e acompanhamento individual para a comunidade TEA.

## 🧩 Stack Oficial
- **Core**: Flutter + Dart
- **Backend**: Firebase (Auth, Firestore, Hosting)
- **Design**: Material 3 + Google Fonts (Inter)

## 🚀 Versão 2.0.0 (MVP+) - Premium UI Overhaul & Firebase Migration
- [x] Migração completa de Supabase para Firebase (Auth e Firestore)
- [x] **Home Screen Redesign**: Interface premium com foco em legibilidade e UX.
- [x] **Digital ID Stack**: Visualização de carteirinhas em estilo wallet (empilhadas e inclinadas).
- [x] **Member Selector**: Seletor moderno com iniciais dinâmicas e indicadores de status em tempo real.
- [x] **Request Tracker**: Acompanhamento visual de solicitações com barra de progresso.
- [x] **Branding**: Otimização da logo e AppBar para máxima elegibilidade.
- [x] **Privacy-First**: Padronização de avatares com iniciais, removendo fotos de perfil.

## 📜 Histórico de Versões

### **v1.3.0 - Workflow de Status & Ações do Usuário** (Maio/2026)
*   **Novo Sistema de Status**: Padronização do enum `RequestStatus`.
*   **Sistema de Ações Inteligentes**: Botões dinâmicos com emojis (📄 Enviar documentação, 📞 Falar com suporte).
*   **Privacidade & Transparência**: Notas de privacidade na interface.

### **v1.2.0 - Redesign Frontal & Foco no Membro** (Maio/2026)
*   **Reposicionamento de Branding**: Logo movida para o canto superior direito.
*   **Layout de Dados em Linha Inteira**: Campos Nº Registro e CPF/RG ocupando largura total.

### **v1.1.7 - Simulação Web & Estabilidade Estrutural**
*   **Simulação de Rotação Web**: Botão de virar carteirinha virtual no navegador.
*   **Fix de Sintaxe**: Resolução de erro crítico no `didChangeDependencies`.

### **v1.1.6 - Estabilização de Layout & Visibilidade Máxima**
*   **Correção de Overflow**: Uso de `LayoutBuilder` e `FittedBox` (800x464).
*   **Identidade Visual "Seal-Only"**: Evolução do design do selo institucional.

### **v1.1.5 - Privacidade & Identidade Institucional**
*   **Privacidade-First (No Photo)**: Remoção definitiva de fotos na carteirinha.
*   **Expansão de Marcas**: Inclusão de Família TEA Bauru e #TODOSPELOAUTISMO.

### **v1.1.4 - Estabilidade & Visibilidade Total**
*   **Correção de Renderização**: Eliminação de `RenderFlex overflow`.
*   **Upgrade Visual Back-Card**: Logotipo oficial do ConeCTEA no verso.

### **v1.1.2 - Experiência de Visualização Premium**
*   **Otimização de Carteirinha**: Modo paisagem obrigatório para legibilidade.
*   **Refinamento Estético**: Glassmorphism avançado e sombras dinâmicas.

### **v1.1.0 - Refatoração Inicial & Firebase**
*   [x] Preparação para migração Firebase.
*   [x] Ajustes estruturais de pastas.

### **v1.0.0 (MVP) - Baseline**
*   [x] Criação do projeto Flutter.
*   [x] Configuração do Design System (Cores e Temas).
*   [x] Estrutura de pastas modular e GoRouter.

## 🧭 Navegação
- `/login`
- `/home`
- `/cards` (Em desenvolvimento)
- `/requests` (Em desenvolvimento)
- `/notifications` (Em desenvolvimento)

## 🎨 Design System
### Cores
- **Principal (Roxo)**: `#7C3AED`
- **Ação (Ciano)**: `#06B6D4`
- **Branding (Azul Escuro)**: `#0B1F4D`
- **Fundo**: `#F8FAFC`

---
*Este documento é atualizado a cada nova versão, mantendo o histórico de evolução do projeto ConeCTEA.*
