# Documentos Sensíveis — ConeCTEA

**App:** 0.7.1-dev
**Documentação:** 4.6.0
**Status:** Desenvolvimento
**Atualizado em:** 22/05/2026

---

## Objetivo

Este documento descreve os fluxos operacionais, diretrizes de mitigação de riscos e regras de engenharia adotadas para o tratamento de **Documentos Sensíveis** (Laudos Médicos, Documentos de Identificação Civil com Foto e Comprovantes de Diagnóstico) no aplicativo ConeCTEA.

---

## Documentos, laudos e telas legais

A evolução da Central do Usuário refinou a governança da privacidade, fornecendo maior transparência jurídica sobre o fluxo de tratamento de documentos de identificação e laudos de diagnóstico enviados pelas famílias.

### 1. Documentos Oficiais em Markdown (docs/legal/)
Os textos normativos oficiais que regulam as obrigações mútuas, segurança e uso de dados pessoais estão documentados em:
*   [Termos de Uso do ConeCTEA](../legal/termos_de_uso_conectea_v1.md)
*   [Política de Privacidade do ConeCTEA](../legal/politica_de_privacidade_conectea_v1.md)

Estes arquivos em Markdown servem como a **única fonte jurídica e editorial da verdade** para o projeto.

### 2. Conversão para Conteúdo Estático (Dart)
Para viabilizar a exibição offline rápida e livre de processamentos pesados de Markdown em tempo de execução no Flutter, os documentos oficiais foram integralmente mapeados em estruturas estáticas Dart:
*   `lib/features/account/privacy/terms_of_use_content.dart`
*   `lib/features/account/privacy/privacy_policy_content.dart`

> [!IMPORTANT]
> **Fidelidade Editorial:**
> O conteúdo estático em Dart é derivado diretamente e de forma literal dos Markdowns originais, garantindo que o usuário leia na tela do celular exatamente a mesma redação oficial das políticas aprovadas pela Família TEA Bauru.

### 3. Renderização Estilizada em Blocos
As telas de exibição visual (`TermsOfUseView` e `PrivacyPolicyView`) consomem a estrutura estática e realizam uma renderização customizada em blocos:
*   Tratamento automatizado para marcadores (`-`) convertendo-os em bullets gráficos limpos;
*   Tratamento para formatação em negrito (`**Texto**`) renderizando os trechos com estilo tipográfico em destaque sem exibir os asteriscos em texto cru;
*   Apresentação em rolagem contínua adaptada de forma elástica a telas estreitas (360dp).

### 4. Classificação dos Documentos como Dados Pessoais Sensíveis
Nos textos legais renderizados no app, os documentos pessoais exigidos no cadastro (Laudo Médico e RG/CPF) são formalmente tipificados e descritos sob a categoria de **Dados Sensíveis**:
*   É informado didaticamente que esses documentos são necessários para a finalidade legítima de prevenção a fraudes (confirmação administrativa da elegibilidade do dependente);
*   As políticas reforçam a segurança do descarte síncrono de arquivos rejeitados e a exclusão automatizada após a aprovação do cadastro.

### 5. Estabilidade Funcional e de Infraestrutura
É expressamente registrado e garantido que:
*   **Nenhuma lógica de upload, descarte, Drive/GAS ou rotinas de limpeza remota foi alterada** na criação das telas e conteúdos da Central do Usuário. A infraestrutura de backend permanece intocada.
*   **Segurança de Visualização:** As novas páginas e fluxos informativos legais **não exibem** URLs diretas do Google Drive, identificadores únicos de arquivos (`fileId`), codificações em Base64 ou dados de documentos reais dos membros. A UI destina-se unicamente à exibição de textos explicativos didáticos institucionais.
