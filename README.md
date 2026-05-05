# ConeCTEA - Carteirinha Digital 🧩

O **ConeCTEA** é um aplicativo mobile desenvolvido em Flutter para a solicitação, aprovação e visualização de carteirinhas de identificação para pessoas com TEA (Transtorno do Espectro Autista). O projeto foca em simplificar o processo burocrático, oferecendo uma interface intuitiva para usuários e uma gestão eficiente para administradores.

---

## ⚡ Sincronização e Performance
O ConeCTEA utiliza tecnologias modernas para garantir uma experiência fluida:
- **Interface Reativa**: Atualização dinâmica nas telas essenciais, garantindo que o status das solicitações seja refletido rapidamente.
- **Client-Side Sorting**: Ordenação de dados realizada diretamente no dispositivo para otimizar a performance e reduzir a dependência de índices complexos no backend.
- **Eficiência de Dados**: Implementação focada em manter a interface atualizada evitando o consumo excessivo de leituras no Firestore.

---

## 🛠️ Tecnologias e Arquitetura
- **Framework**: [Flutter](https://flutter.dev) (Dart) - Aplicativo nativo para Android.
- **Backend**: [Firebase](https://firebase.google.com)
  - **Firestore**: Banco de dados NoSQL para armazenamento e sincronização de dados.
  - **Authentication**: Gestão segura de usuários.
- **Automação de Processos**:
  - **Token Único**: Geração automática de identificadores no formato `CTEA-XXXX-YYYY`.
  - **Gestão de Validade**: Definição automática de 365 dias de validade a partir da aprovação.

---

## 📋 Funcionalidades

### 👤 Área do Usuário
- **Solicitação de Carteirinha**: Formulário simplificado para envio de dados.
- **Acompanhamento de Status**: Visualização reativa do progresso (Pendente, Aprovado ou Rejeitado).
- **Carteirinha Digital**: Exibição dos dados e validade após a aprovação.
- **Suporte**: Link direto para atendimento via WhatsApp.

### 🛡️ Área Administrativa
- **Gestão de Pedidos**: Lista organizada de solicitações pendentes e processadas.
- **Fluxo de Aprovação**:
  - Atribuição automática de tokens e datas de validade.
  - Possibilidade de adicionar notas de feedback para o usuário.
- **Interface Responsiva**: Dashboard otimizado para gestão rápida das demandas.

---

## 🔧 Configuração do Ambiente

### Pré-requisitos
- Flutter SDK instalado.
- Android Studio e Android Emulator configurados.
- JDK configurado conforme as exigências do ambiente local.

---

## 📂 Estrutura do Projeto
```text
lib/
├── core/         # Configurações de tema, cores e Firebase.
├── models/       # Estruturas de dados (IDRequest, etc).
├── services/     # Lógica de negócio (Auth, Firestore, Automations).
├── screens/      # Telas do usuário e do administrador.
└── widgets/      # Componentes de interface reutilizáveis.
```

---

## 🚢 Como Executar
1. Certifique-se de que um **Emulador Android** ou dispositivo físico está conectado.
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute o aplicativo:
   ```bash
   flutter run
   ```

---

## 📦 Repositório
[https://github.com/lukaslimna1/coneCTEA.git](https://github.com/lukaslimna1/coneCTEA.git)

---
*Desenvolvido por Lucas Lima & Antigravity AI.*
