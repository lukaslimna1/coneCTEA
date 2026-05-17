# Fluxos Usuário — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
**Atualizado em:** 17/05/2026

---

## Objetivo

Mapear os principais fluxos de interação e navegação do usuário no aplicativo ConeCTEA.

---

## Fluxos Identificados

### Feedback de Status ("Ver Motivo / Ver Documento Digital")
- O usuário visualiza o status na Home e toca na ação "Ver Motivo" ou "Ver Documento Digital".
- O modal premium (`PremiumStatusDialog`) abre com formato puramente informativo.
- O usuário lê o aviso e clica no botão de confirmação `Entendido`.
- O modal fecha e as eventuais ações práticas (como acionar o suporte) continuam disponíveis diretamente na Home.

### Fluxo de Renovação de Carteirinha
- O usuário com a carteirinha no status **Vencida** visualiza na Home o botão exclusivo “Solicitar Renovação”.
- Ao clicar em "Solicitar Renovação", o status do aplicativo muda para **Renovando**.
- O usuário passa a aguardar o processamento da solicitação pelo administrador.
