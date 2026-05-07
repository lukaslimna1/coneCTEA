# ConeCTEA 📱

App de identificação digital, solicitações e acompanhamento individual para a comunidade TEA.

## 🧩 Stack Oficial
- **Core**: Flutter + Dart
- **Backend**: Firebase (Auth, Firestore, Hosting)
- **Design**: Material 3 + Google Fonts (Inter)

## 🚀 Versão 1.1.0 (MVP+) - Refatoração & Firebase
- [x] Migração completa de Supabase para Firebase (Auth e Firestore)
- [x] Refatoração da Home Screen (Design Premium & Intuitivo)
- [x] Implementação do Seletor de Membros (chips com status e borda dinâmica)
- [x] Visualização de Carteirinha (cards empilhados/inclinados)
- [x] Monitor de Solicitações (tracker com barra de progresso)
- [x] Otimização da Logo e do AppBar (legibilidade e ícones)
- [x] Padronização de Avatares (iniciais dinâmicas, remoção de fotos)

## 🚀 Versão 1.0.0 (MVP) - Baseline
- [x] Criação do projeto Flutter
- [x] Configuração do Design System (Cores e Temas)
- [x] Estrutura de pastas modular
- [x] Configuração de rotas (GoRouter)
- [x] Tela de Login (UI Finalizada)
- [x] Placeholder para Home Page

## 🧭 Navegação
- `/login`
- `/home`
- `/cards` (Futuro)
- `/card-viewer` (Futuro)
- `/requests` (Futuro)
- `/notifications` (Futuro)
- `/account` (Futuro)

## 🎨 Design System
### Cores
- Roxo: `#7C3AED`
- Ciano: `#06B6D4`
- Azul Escuro: `#0B1F4D`
- Fundo: `#F8FAFC`

## 📁 Estrutura de Pastas
```
lib/
  app/       # Configurações globais (rotas, tema)
  core/      # Constantes, utils e widgets globais
  features/  # Módulos por funcionalidade
  models/    # Modelos de dados
  services/  # Integrações (Supabase, etc)
```

---
*Este documento será atualizado a cada nova versão, mantendo o histórico de evolução.*
