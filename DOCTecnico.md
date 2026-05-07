# Documentação Técnica - ConeCTEA

## 1. Visão Geral do Sistema
O **ConeCTEA** é um aplicativo móvel construído em **Flutter**, projetado para atuar como uma central rápida e eficiente de serviços para usuários (pais/responsáveis) e membros vinculados (dependentes com TEA). A aplicação permite o gerenciamento de perfis, acesso a carteirinhas digitais, acompanhamento de solicitações e notificações.

O back-end é alimentado pelo **Supabase**, utilizando seus serviços de Autenticação (Supabase Auth) e Banco de Dados Relacional (PostgreSQL).

## 2. Arquitetura e Tecnologias

### 2.1 Front-end (Mobile)
- **Framework:** Flutter (SDK 3.x)
- **Linguagem:** Dart
- **Design System e Estilização:** 
  - Cores customizadas (`AppColors`) definidas globalmente.
  - Tipografia baseada no `GoogleFonts.inter`.
  - Componentização para reaproveitamento (ex: Cards, Avatares por iniciais, BottomNavigationBar customizado).
- **Roteamento:** `go_router` (Navegação declarativa).
- **Gerenciamento de Estado:** `ChangeNotifier` puro do Flutter (ex: `AuthNotifier`) combinado com gerenciamento de estado local (`setState`).
- **Validação de Formulários:** `mask_text_input_formatter` para máscaras de entrada (telefone, data).
- **Ícones e Ilustrações:** `flutter_svg` para renderização de SVGs.

### 2.2 Back-end (Supabase)
- **Autenticação:** Supabase Auth (E-mail e Senha).
- **Banco de Dados:** PostgreSQL hospedado via Supabase (`supabase_flutter`).
- **Comunicação:** Chamadas assíncronas via `SupabaseClient`.

## 3. Estrutura de Diretórios
A estrutura do projeto segue os princípios de separação de responsabilidades (Clean Architecture e Feature-Based):

```
lib/
├── core/
│   ├── constants/       # Cores, fontes, dimensões (ex: colors.dart)
│   ├── notifiers/       # Gerenciadores de estado globais (ex: auth_notifier.dart)
│   └── utils/           # Funções utilitárias globais
├── features/            # Telas da aplicação separadas por domínios
│   ├── auth/            # login_page.dart, register_page.dart
│   └── home/            # home_view.dart
├── models/              # Classes de modelo (Data Transfer Objects)
│   ├── app_user.dart
│   ├── member.dart
│   ├── digital_card.dart
│   ├── card_request.dart
│   └── notification_item.dart
├── services/            # Comunicação com APIs e Back-end
│   ├── auth_service.dart
│   └── database_service.dart
└── main.dart            # Ponto de entrada, configuração do GoRouter e Supabase
```

## 4. Modelos de Dados (Entidades)

### 4.1 Usuário Principal (`profiles`)
Representa o responsável que faz login no app.
- `id` (UUID): Chave primária.
- `name`, `email`, `phone`, `dateOfBirth`, `city`, `state`, `socialName` etc.
- `role`: Nível de acesso (ex: `user`, `admin`).

### 4.2 Membros Vinculados (`members`)
Representa os dependentes cadastrados sob o perfil do usuário.
- Relacionamento: `user_id` aponta para `profiles(id)`.
- Contém iniciais para o avatar (`LM`, `PH`) e status da carteirinha (ex: `Ativa`).

### 4.3 Outras Entidades
- **Carteiras Digitais (`digital_cards`)**: Vínculo do membro com o número da carteirinha e validade.
- **Solicitações (`card_requests`)**: Histórico e status das requisições (ex: "Em análise", "Aprovada").
- **Notificações (`notifications`)**: Avisos do sistema disparados para o usuário.

## 5. Fluxos Principais

### 5.1 Fluxo de Autenticação (Login e Cadastro)
1. **Cadastro (`RegisterPage`):** 
   - Coleta os dados do usuário.
   - Faz a chamada a `AuthService.signUpWithEmailPassword()`.
   - Se sucesso, insere o registro no banco (`DatabaseService.createUserProfile()`).
   - *Nota de Segurança:* Documentos sensíveis não são trafegados no app; utiliza-se sistema sem upload de arquivos para manter o app leve. O fluxo de e-mail de confirmação é gerenciado via dashboard do Supabase.
2. **Login (`LoginPage`):**
   - Valida credenciais usando `AuthService.signInWithEmailPassword()`.
   - `AuthNotifier` captura a mudança de estado e redireciona para a rota apropriada (ex: `/home`).

### 5.2 Carregamento da Home (`HomeView`)
1. Inicializa o estado consultando o `DatabaseService`.
2. Em paralelo (via `Future.wait`), busca:
   - Perfil do usuário logado.
   - Lista de membros vinculados.
   - Carteirinhas associadas.
   - Solicitações recentes.
   - Lista de notificações não lidas.
3. Exibe a interface modularizada: Saudação, Cards de Membros (com seleção dinâmica que atualiza os dados da carteirinha), Acesso Rápido e Solicitações.

## 6. Configurações Externas (Dashboard do Supabase)
As seguintes configurações devem ser gerenciadas diretamente na interface web do Supabase (não via código):
- **E-mails Transacionais:** Confirmação de e-mail, redefinição de senha e convites. É possível desativar a confirmação obrigatória de e-mail ou personalizar as templates HTML diretamente no menu de Autenticação do Supabase.
- **Regras de Segurança (RLS - Row Level Security):** Devem ser configuradas nas tabelas (profiles, members, etc.) para garantir que um usuário só consiga fazer `SELECT`, `INSERT`, `UPDATE` nos dados onde `user_id == auth.uid()`.

## 7. Diretrizes UI/UX do MVP
- **Avatar:** Remoção total de imagens/fotos dos usuários, padronizando a utilização de iniciais (ex: `LL`) em elementos circulares e chips para garantir consistência e leveza.
- **Premium Feel:** Utilização de sombras suaves, cantos com alto border radius, espaçamentos generosos e ausência de informações desnecessárias. O foco é na clareza dos serviços odontológicos / plano de saúde.
- **Navegação:** Menus focados em uso com uma mão (BottomNavigationBar customizado) para navegação ágil.

---
*Esta documentação reflete o estado técnico atual da aplicação para a versão de MVP.*
