# Google Play — ConeCTEA

**App:** 0.6.0-dev
**Documentação:** 4.4.0
**Status:** Desenvolvimento
**Atualizado em:** 22/05/2026

---

## Objetivo

Descrever os requisitos, orientações e parâmetros necessários para publicação do aplicativo ConeCTEA na loja oficial Google Play Store, garantindo conformidade com as políticas do programa de desenvolvedores.

---

## Preparação de privacidade e transparência

O Google Play exige extremo rigor e transparência em relação à coleta e uso de dados pessoais e de saúde de usuários. As recentes implementações na Central do Usuário atendem a essas exigências, preparando a aplicação para a submissão de forma segura:

### 1. Documentos Legais Integrados
- **Política de Privacidade:** O documento oficial está localizado sob a pasta `docs/legal/politica_de_privacidade_conectea_v1.md`. No aplicativo, o conteúdo correspondente é renderizado offline em uma tela dedicada (`PrivacyPolicyView`), garantindo fácil acesso ao usuário.
- **Termos de Uso:** O documento oficial está localizado em `docs/legal/termos_de_uso_conectea_v1.md` e é exibido na tela interna (`TermsOfUseView`) de forma estruturada.

### 2. Declarações e Limites do Aplicativo
Ambos os documentos legais e as telas de transparência interna deixam claro para os revisores da Google Play e para a comunidade que:
- **A carteirinha comunitária digital é de uso exclusivamente interno e comunitário,** ligada à Família TEA Bauru. Ela **não é a CIPTEA oficial**, não substitui documentos de identificação oficiais (RG, CPF, CNH) e nem laudos médicos.
- **O aplicativo é social, institucional e administrativo, não médico.** Ele **não realiza diagnóstico**, não prescreve tratamentos e não substitui a assistência médica ou terapêutica profissional.

### 3. Transparência na Central do Usuário
As telas de dados armazenados e uso das informações explicam por que dados cadastrais e arquivos de documentos/laudos médicos são coletados e como são protegidos de forma segura.

### 4. Critérios Críticos para a Submissão (Data Safety)
> [!WARNING]
> **Revisão Obrigatória de Data Safety:** Antes da submissão à loja, o formulário de Data Safety (Segurança dos Dados) no Console da Google Play deve ser auditado minuciosamente frente ao código-fonte real e ao banco de dados Supabase para atestar que todas as declarações de coleta de dados sensíveis (como nome, CPF, e-mail, telefone e arquivos) estejam 100% corretas.

> [!IMPORTANT]
> **Limites Funcionais do Lançamento:**
> - **Consentimentos Visuais:** Os switches na tela de consentimentos são estritamente locais e visuais nesta fase de interface. A persistência real das escolhas no banco Supabase deve ser implementada antes de declarar o consentimento funcional aos usuários.
> - **Exclusão de Conta e Remoção de Dependente:** Os botões e modais de confirmação de exclusão de conta e remoção de dependentes na interface de usuário funcionam como fluxos de barreira lógica simulados. A implementação técnica real de deleção física e descarte assíncrono de arquivos deve ser concluída antes de publicar estas funcionalidades como "ativas" ou "resolvidas" na loja.

---

## Escopo

Este documento será preenchido progressivamente conforme novos requisitos operacionais e técnicos de publicação no console da Google Play Store surgirem.
