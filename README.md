# ConeCTEA - Carteirinha Digital 🧩

O **ConeCTEA** é um aplicativo Flutter desenvolvido para facilitar a solicitação, emissão e gestão de carteirinhas de identificação para pessoas com TEA (Transtorno do Espectro Autista). O projeto foca em acessibilidade, simplicidade e segurança.

---

## 🚀 Status do Projeto e Migração
O projeto foi migrado com sucesso de Supabase para **Firebase**, utilizando uma arquitetura escalável e segura. O ambiente de desenvolvimento foi otimizado para Windows e Web.

---

## 🛠️ Tecnologias Utilizadas
- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend**: [Firebase](https://firebase.google.com)
  - **Authentication**: Login por e-mail/senha.
  - **Cloud Firestore**: Banco de dados NoSQL em tempo real.
- **Gerenciamento de Estado**: [Provider](https://pub.dev/packages/provider)
- **Estilização**: Tema customizado (Indigo/Teal) com suporte a fontes premium.

---

## 📋 Funcionalidades
### 👤 Usuário Comum
- Cadastro e login seguro.
- Solicitação de carteirinha via formulário simplificado.
- Visualização do status da solicitação.
- Visualização da carteirinha digital após aprovação.
- Botão de suporte direto via WhatsApp.

### 🛡️ Administrador
- Dashboard completo para gestão de pedidos.
- Lista de todos os usuários e solicitações.
- Aprovação/Rejeição de solicitações com campo de notas.
- Atribuição de número de carteirinha e data de validade.

---

## 🔧 Configuração do Ambiente

### 1. Requisitos do Sistema (Windows)
- Flutter SDK instalado (recomendado na unidade `H:` conforme o setup atual).
- JDK 21 (recomendado o que vem com o Android Studio).
- **Atenção**: Para evitar erros de Gradle, configure o JDK no Flutter:
  ```powershell
  flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
  ```

### 2. Configuração do Firebase
- O projeto utiliza o arquivo `lib/core/firebase_options.dart` gerado pelo FlutterFire CLI.
- **Firestore**: Deve ser inicializado no **Modo Nativo**.
- **Security Rules**: O banco está protegido com regras que permitem aos usuários acessar apenas seus próprios dados e aos admins gerenciar tudo.

---

## 📂 Estrutura de Pastas
```text
lib/
├── core/         # Temas, constantes e Firebase Options
├── models/       # Modelos de dados (User, IDRequest)
├── services/     # Lógica de Auth e Banco de Dados
├── screens/      # Interfaces (Auth, User, Admin)
└── widgets/      # Componentes UI reutilizáveis
```

---

## 🚢 Como Executar
1. Instale as dependências:
   ```bash
   flutter pub get
   ```
2. Execute o projeto (Web/Chrome):
   ```bash
   flutter run -d chrome
   ```

---

## 📦 Deploy e Controle de Versão
O código está versionado no GitHub: [https://github.com/lukaslimna1/coneCTEA.git](https://github.com/lukaslimna1/coneCTEA.git)

---
Desenvolvido por Lucas Lima e Antigravity (IA).
