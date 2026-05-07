# Configuração do Backend (Firebase)

Para que o aplicativo **ConeCTEA** funcione corretamente, você deve configurar o Firebase seguindo os passos abaixo.

## 1. Criação do Projeto
1. Vá para o [Firebase Console](https://console.firebase.google.com/).
2. Crie um novo projeto chamado `ConeCTEA`.
3. Adicione um app Android (e iOS se necessário) ao projeto.
4. Baixe o arquivo `google-services.json` e coloque em `android/app/`.

## 2. Autenticação
1. No menu lateral, vá em **Authentication**.
2. Clique em **Get Started**.
3. Ative o provedor **Email/Password**.

## 3. Cloud Firestore (Banco de Dados)
1. No menu lateral, vá em **Firestore Database**.
2. Clique em **Create Database**.
3. Escolha o modo de produção ou teste (recomenda-se configurar as regras abaixo).
4. O app utiliza as seguintes coleções:
   - `profiles`: Armazena dados dos usuários.
   - `id_requests`: Armazena as solicitações de carteirinha.

### Regras de Segurança Sugeridas:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Função para verificar se o usuário é admin
    function isAdmin() {
      return get(/databases/$(database)/documents/profiles/$(request.auth.uid)).data.role == 'admin';
    }

    match /profiles/{userId} {
      allow read, write: if request.auth != null && (request.auth.uid == userId || isAdmin());
    }
    
    match /id_requests/{requestId} {
      allow read: if request.auth != null && (resource.data.user_id == request.auth.uid || isAdmin());
      allow create: if request.auth != null && request.resource.data.user_id == request.auth.uid;
      allow update, delete: if request.auth != null && isAdmin();
    }
  }
}
```

## 4. Criando o primeiro Administrador
Após se cadastrar no aplicativo pela primeira vez, seu perfil será criado automaticamente no Firestore com a role `common`. Para se tornar administrador:
1. Vá no painel do **Firestore**.
2. Localize seu documento na coleção `profiles`.
3. Altere o campo `role` de `common` para `admin`.

## 5. Configuração do Flutter
O projeto já contém o arquivo `lib/core/firebase_options.dart`. Caso você crie um novo projeto Firebase, certifique-se de atualizar este arquivo usando o comando:
```bash
flutterfire configure
```
(Requer o FlutterFire CLI instalado).
