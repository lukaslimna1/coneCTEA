# Fluxos Admin — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
**Atualizado em:** 17/05/2026

---

## Objetivo

Descrever os fluxos operacionais e ferramentas disponíveis para os administradores no painel de controle do ConeCTEA.

---

## Fluxo de Renovação

- A solicitação de renovação iniciada pelo usuário aparece no painel Admin com o status **Aguardando Renovação**.
- O administrador visualiza o pedido e tem a opção de clicar em “Aprovar Renovação”.
- A aprovação reativa a carteirinha e atualiza o prazo de validade.
- O fluxo de renovação mantém a mesma carteirinha, ou seja, **não cria uma carteirinha duplicada** no banco de dados.
- O administrador mantém os poderes normais de operação: pode pedir novos documentos, revisar dados, reprovar ou suspender caso a solicitação de renovação encontre pendências, seguindo as regras já existentes.
