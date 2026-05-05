# ConeCTEA - Carteirinha Digital 🧩

O **ConeCTEA** é um ecossistema mobile robusto desenvolvido em Flutter para a gestão simplificada de identificação para pessoas com TEA (Transtorno do Espectro Autista). O projeto une tecnologia de ponta com acessibilidade para entregar uma experiência fluida tanto para usuários quanto para administradores.

---

## ⚡ Real-Time Sync & Performance
O ConeCTEA agora opera em **tempo real**. Utilizando a tecnologia de **Streams do Firestore**, o aplicativo sincroniza dados instantaneamente:
- **Interface Reativa**: Mudanças no banco de dados são refletidas na UI sem necessidade de recarregar a página.
- **Client-Side Sorting**: Otimização técnica que realiza a ordenação de dados diretamente no dispositivo, eliminando a dependência de índices compostos complexos no Firebase e garantindo maior velocidade de consulta.
- **Zero Latency UX**: Implementação de `StreamBuilder` em todas as telas críticas (Dashboard Admin e Home Usuário).

---

## 🛠️ Tecnologias e Arquitetura
- **Framework**: [Flutter](https://flutter.dev) (Dart) - UI performática e multi-plataforma.
- **Backend-as-a-Service**: [Firebase](https://firebase.google.com)
  - **Firestore**: Banco de dados NoSQL com sincronização em tempo real.
  - **Authentication**: Gestão segura de identidades e sessões.
- **Automação Inteligente**:
  - **Token Automático**: Geração de identificadores únicos no formato `CTEA-XXXX-YYYY`.
  - **Validade Dinâmica**: Atribuição automática de 365 dias de validade a partir do momento da aprovação.

---

## 📋 Funcionalidades Principais

### 👤 Área do Usuário
- **Solicitação Simplificada**: Envio de dados para análise de forma intuitiva.
- **Acompanhamento Live**: Status da solicitação atualizado em tempo real (Pendente ➔ Aprovado ➔ Rejeitado).
- **Carteirinha Digital Premium**: Visualização elegante da carteirinha com QR Code e dados de validade após a aprovação.
- **Suporte Integrado**: Canal direto via WhatsApp para auxílio rápido.

### 🛡️ Painel Administrativo (Elite)
- **Gestão Reativa**: Lista de solicitações organizada automaticamente por data de criação.
- **Fluxo de Aprovação Inteligente**:
  - Sistema sugere tokens únicos.
  - Cálculo automático de data de vencimento.
  - Feedback via notas administrativas para o usuário.
- **Filtros Ágeis**: Visualização clara de pendências e histórico de ações.

---

## 🔧 Configuração e Desenvolvimento

### 1. Ambiente Windows
- Flutter SDK (Recomendado na unidade `H:`).
- JDK 21 configurado via `flutter config --jdk-dir`.

### 2. Integração Firebase
- O projeto utiliza o padrão `firebase_options.dart` para máxima compatibilidade.
- **Regras de Segurança**: Implementadas para garantir que dados sensíveis sejam acessíveis apenas pelo proprietário ou administradores autorizados.

---

## 📂 Organização do Projeto
```text
lib/
├── core/         # Configurações de tema, cores e constantes globais.
├── models/       # Estruturas de dados tipadas (IDRequest, etc).
├── services/     # Serviços de backend (Auth, Firestore, Automations).
├── screens/      # Interfaces de usuário (User & Admin flows).
└── widgets/      # UI Components (Cards, Buttons, Loaders).
```

---

## 🚢 Execução Local
1. Obtenha as dependências:
   ```bash
   flutter pub get
   ```
2. Inicie o ambiente de desenvolvimento:
   ```bash
   flutter run -d chrome
   ```

---

## 📦 Repositório Oficial
Código fonte versionado em: [https://github.com/lukaslimna1/coneCTEA.git](https://github.com/lukaslimna1/coneCTEA.git)

---
*Desenvolvido com foco em impacto social por Lucas Lima & Antigravity AI.*

