# 📘 Documentação Técnica — ConeCTEA
**Versão:** 3.4.0 | **Atualizado em:** 10/05/2026

---

## 1. Visão Geral

O **ConeCTEA** é um ecossistema digital para identificação e gerenciamento de serviços para a comunidade TEA (Transtorno do Espectro Autista). Composto por:

- **Aplicativo Mobile/Web** — Flutter (Dart)
- **Back-end** — Supabase (PostgreSQL + Auth + Realtime)
- **Integrações** — Google Drive (via Google Apps Script), IBGE API, OneSignal Push

O sistema foi projetado com foco em **acessibilidade sensorial**, **segurança de dados (LGPD)** e **estética premium institucional**.

> [!IMPORTANT]
> **Aviso Legal:** O ConeCTEA **não é a CIPTEA oficial** e não substitui documentos de identificação governamentais.

---

## 2. Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Auth    │  │  Home    │  │  Admin   │  │ Cards  │  │
│  │  Layer   │  │  Screen  │  │ Dashboard│  │  QR    │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘  │
│       └─────────────┴─────────────┴─────────────┘       │
│                    Services Layer                        │
│         AuthService  │  DatabaseService  │  DriveService │
└─────────────────────┬───────────────────┬───────────────┘
                      │                   │
            ┌─────────▼──────┐   ┌────────▼──────┐
            │   Supabase     │   │  Google Drive  │
            │  PostgreSQL    │   │ (via Apps Script)│
            │  Auth + RLS    │   └───────────────┘
            └────────────────┘
```

---

## 3. Design System — Night Blue Premium

O ConeCTEA migrou para uma identidade visual baseada em **Dark Mode Azul Noite**, otimizada para conforto visual e redução de sobrecarga cognitiva.

### 3.1 Paleta de Cores (`AppColors`)

| Token | Hex | Uso |
|---|---|---|
| `primary` | `#8B3DFF` | Destaque institucional, botões primários |
| `cyan` | `#14D9D0` | Elementos funcionais e acentos |
| `background` | `#071B3A` | Fundo principal da aplicação |
| `backgroundGradientEnd`| `#0B2A55` | Final do gradiente de fundo |
| `cardBackground` | `#0E2A52` | Fundo base de cards |
| `surfaceCard` | `#10315E` | Superfícies elevadas e secundárias |
| `cardElevated` | `#123867` | Cards com destaque ou estados ativos |
| `borderLight` | `#1E4A7A` | Bordas sutis de componentes |
| `textPrimary` | `#F8FAFC` | Textos principais e títulos |
| `titleSoft` | `#F3F6FB` | Títulos com menor peso visual |
| `textSecondary` | `#B8C7E6` | Textos de apoio e descrições |
| `cardSubtitle` | `#D6E2F5` | Subtítulos dentro de cards |
| `statusGreen` | `#34D399` | Indicadores de sucesso / Ativo |
| `alertOrange` | `#F59E0B` | Indicadores de atenção / Pendente |
| `errorRed` | `#EF4444` | Indicadores de erro / Crítico |

### 3.2 Tipografia
*   **Títulos:** `Outfit` (Google Fonts) — Proporciona um ar moderno e tecnológico.
*   **Corpo:** `Inter` (Google Fonts) — Máxima legibilidade em qualquer tamanho.

### 3.3 Catálogo de Componentes Reutilizáveis
*   `PremiumCard`: Container com gradientes sutis e bordas glassmorphic.
*   `PremiumIconTile`: Item de lista com ícone destacado e layout limpo.
*   `PremiumButton`: Botões com estados animados e feedback visual claro.
*   `PremiumInput`: Campos de texto com alto contraste e validação integrada.
*   `PremiumBottomNavBar`: Barra de navegação expansível com transições em pill.
*   `AppTopHeader`: Cabeçalho padrão com avatar circular e saudação.
*   `StatusPill`: Indicadores de status compactos com alto contraste.

---

## 4. Navegação e Interação

### 4.1 Premium Bottom Navigation
A navegação inferior foi redesenhada para ser dinâmica e intuitiva:
*   **Item Ativo**: Expande para mostrar Ícone + Rótulo em formato de "pill".
*   **Itens Inativos**: Permanecem compactos (apenas ícone).
*   **Animação**: Transições suaves (`easeOutCubic`) com duração entre 180ms e 240ms.
*   **Estética**: Sem fundo branco puro; utiliza tons de `background` e `surface`.

### 4.2 Regras de Acessibilidade (Neurodiversidade)
*   **Contraste Controlado**: Evita tons neon excessivos que podem causar fadiga.
*   **Layout Previsível**: Mantém elementos consistentes em todas as telas para reduzir ansiedade.
*   **Micro-animações**: Velocidade reduzida e sem efeitos elásticos/bruscos.
*   **Hierarquia Clara**: Separação visual forte entre seções para facilitar o escaneamento ocular.

---

## 5. Governança de Perfil e Edição de Dados

Para garantir a integridade do cadastro e conformidade com a emissão de documentos oficiais:

### 5.1 Bloqueio por Padrão
Todos os campos em `EditProfileView` iniciam em estado de leitura (`LockedField`).

### 5.2 Modo de Edição Protegido
- Ativação via botão "Editar" na AppBar.
- Exige confirmação explícita via Diálogo de Aviso.
- Desbloqueia campos editáveis (Nome Social, Telefone, Gênero, etc.).

### 5.3 Campos de Segurança Crítica (Always Locked)
**CPF e E-mail** são permanentemente bloqueados para edição direta. 
- **Justificativa:** São chaves únicas de validação no banco e no Supabase Auth.
- **Fluxo de Alteração:** O usuário deve clicar no campo bloqueado, o que abre um diálogo de suporte com link direto para o WhatsApp da administração.

---

## 6. Controle de Acesso e Permissões (RBAC)

O sistema possui **4 níveis de acesso** gerenciados pelo campo `role` no banco:

| Role | Permissões |
|---|---|
| `user` | Acesso à própria carteirinha, dependentes e solicitações |
| `admin` | Gestão de solicitações, visualização de membros, scanner QR |
| `admin_master` | Tudo do `admin` + promoção/remoção de admins padrão |
| `admin_dev` | Acesso total: manutenção técnica e gestão total de cargos |

### 6.1 Segurança RLS (Row Level Security)
Políticas no PostgreSQL impedem alteração do campo `role` por usuários sem permissão — a segurança é garantida a nível de banco, independente do front-end.

```sql
-- Exemplo: Apenas admin_master e admin_dev podem alterar roles
CREATE POLICY "manage_roles" ON public.profiles
  FOR UPDATE USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin_master', 'admin_dev')
  );
```

---

## 7. Fluxo de Autenticação

```
┌──────────┐    signUp()     ┌────────────────┐
│  App     │ ─────────────►  │ Supabase Auth  │
│ Register │  + metadata     │  auth.users    │
└──────────┘                 └───────┬────────┘
                                     │ TRIGGER: handle_new_user()
                                     ▼
                             ┌────────────────┐
                             │ public.profiles│
                             │ (auto-insert)  │
                             └────────────────┘
```

### 7.1 SQL Trigger — Criação Automática de Perfil
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, cpf, phone, city, state, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'name',
    NEW.email,
    NEW.raw_user_meta_data->>'cpf',
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'city',
    NEW.raw_user_meta_data->>'state',
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 8. Estrutura de Diretórios Oficial

```
lib/
├── app/                         # Rotas, tema e configuração geral
│   ├── routes.dart              # go_router: todas as rotas da aplicação
│   └── theme.dart               # Tema Material 3 global
├── core/                        # Base reutilizável do app
│   ├── constants/               # Cores, tokens e estilos (AppColors)
│   ├── notifiers/               # Estados/Notifiers globais (ChangeNotifier)
│   ├── utils/                   # Helpers e utilitários globais
│   └── widgets/                 # Widgets globais e componentes base
│       └── premium/             # Componentes oficiais do design Night Blue
├── features/                    # Telas e funcionalidades por domínio
│   ├── account/                 # Perfil, segurança e legal (LGPD)
│   ├── admin/                   # Gestão, dashboard e scanner admin
│   ├── auth/                    # Login, cadastro e recuperação
│   ├── cards/                   # Visualização e gestão de carteirinhas
│   ├── home/                    # Dashboard principal do usuário
│   ├── notifications/           # Histórico e gestão de notificações
│   └── requests/                # Fluxo de novas solicitações
├── models/                      # Modelos de dados (AppUser, Member, etc)
├── services/                    # Serviços globais (Auth, DB, GoogleDrive)
├── widgets/                     # Pasta legada (em revisão, contém PremiumHero)
└── main.dart                    # Ponto de entrada (Bootstrap)
```

---

## 9. Módulos de Negócio

### 9.1 Ciclo de Vida da Carteirinha

```
[user] Solicitação ──► waiting_docs ──► under_review ──► approved/active
                                                     └──► rejected
                                                     └──► reviewing_data
                                                     └──► suspended
                                                     └──► expired
```

Status são gerenciados exclusivamente pelo painel administrativo.

### 9.2 QR Code Seguro
- **Padrão do token:** `TEA-ID-<HEXA>` (gerado internamente)
- **Sem URLs públicas:** o QR aponta para um token interno (Card Number), não para um link externo.
- **Validação:** Realizada em tempo real via `DatabaseService.getCardByNumber()`.
- **Scanner:** `mobile_scanner` com regex de normalização (`TEA-ID-[A-Z0-9]+`).

### 9.3 API IBGE — Localização
- **Endpoint:** `https://servicodados.ibge.gov.br/api/v1/localidades/`
- **Estratégia:** Fetch único por estado ao selecionar UF, filtro local por digitação
- **Componente:** `SearchAnchor` (Material 3) para autocomplete fluido

---

## 10. Segurança e LGPD

### 10.1 Dados Coletados
| Dado | Finalidade | Base Legal |
|---|---|---|
| Nome, E-mail | Identificação e comunicação | Contrato |
| CPF | Validação de identidade e unicidade | Obrigação legal |
| Telefone, Cidade | Atendimento e suporte | Legítimo interesse |
| Laudo médico (Drive) | Emissão de carteirinha | Consentimento explícito |
| Dados de saúde/deficiência | Emissão de CIPTEA | Consentimento explícito |

### 10.2 Proteções Implementadas
- **RLS no PostgreSQL:** Acesso a dados restrito por política de banco
- **Validação de CPF:** Algoritmo de dígitos verificadores no front-end
- **Unicidade:** Verificação de e-mail e CPF antes do cadastro
- **Tokens QR:** Sem exposição de dados pessoais em URLs públicas
- **Proteção de Secrets:** Nenhuma chave de API sensível (como OneSignal REST Key) é armazenada no código cliente.
- **Consentimentos:** Tela dedicada para gerenciamento de preferências LGPD

### 10.3 Contato para Privacidade
- **Instituição:** Família TEA Bauru
- **Instagram:** [@familiateabauru](https://www.instagram.com/familiateabauru)
- **Localização:** Bauru — SP, Brasil

---

## 11. Problemas Conhecidos e Soluções

| Problema | Causa | Solução |
|---|---|---|
| `MissingPluginException` (OneSignal) | OneSignal não suporta web | Inicialização funciona apenas em mobile nativo; ignorar em web/debug |
| `RealtimeSubscribeException` | Configuração de Realtime no Supabase | Não bloqueia operações CRUD; configurar políticas de Realtime no dashboard |
| Build lento (web) | Hot restart com erros de análise | Corrigir todos os erros antes de hot restart |

---

## 12. Scripts SQL Relevantes

```
supabase/
├── trigger_handle_new_user.sql      # Criação automática de perfil
├── setup_roles_and_security.sql     # RBAC e políticas de segurança
├── rls_admin_policies.sql           # RLS detalhado por tabela
└── fix_admin_notifications_and_deadline.sql  # Correções de notificações
```

## 13. Regras de Organização Técnica

Para manter a manutenibilidade e o padrão profissional do ConeCTEA, as seguintes regras devem ser seguidas:

### 13.1 Padrão de Comentários
*   **Idioma:** Todos os comentários internos devem ser em **Português Brasileiro (PT-BR)**.
*   **Utilidade:** Comentários devem explicar o "porquê" (regra de negócio ou lógica complexa), não o "o quê" (código óbvio).
*   **Tradução:** Comentários herdados em inglês devem ser traduzidos ou removidos se forem genéricos.

### 13.2 Gestão de Imports
*   **Preferência:** Utilizar imports de pacote (`package:conectea/...`) para maior clareza.
*   **Limpeza:** Remover sistematicamente imports não utilizados antes de cada commit.
*   **Organização:** Agrupar imports por (1) Dart/Flutter, (2) Pacotes externos, (3) Arquivos do projeto.

### 13.3 Desenvolvimento de Componentes
*   **Duplicidade:** Antes de criar um widget novo, verifique se já existe um equivalente em `core/widgets/premium`.
*   **Estética:** Novos componentes devem seguir rigorosamente o design system **Night Blue Premium** (Glassmorphism, sombras suaves, cores do `AppColors`).
*   **Estabilidade:** Validar alterações sempre no **Android (Emulador ou Físico)**. A validação via Chrome é apenas para testes rápidos de layout.

---

*Documentação atualizada em 10/05/2026 — ConeCTEA v3.4.0*
*Família TEA Bauru 💙*
