# Status Visuais — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

---

## Objetivo

Mapear a identidade visual, semântica cromática e os componentes relacionados aos diferentes estados da carteirinha e dos usuários no ConeCTEA. Este documento reflete as consolidações das Frentes 25B e 26A.

---

## 1. Identidade de Status Unificada

Os status da carteirinha seguem o padrão visual unificado (Dark Glass com pílulas neon correspondentes), centralizado em `StatusVisualTokens` e acionados pelo `StatusActionButton`:

| Identificador do Status | Label da Pílula | Cor Semântica | Ícone Associado | Botão de Ação (CTA) | Função do CTA |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `active` | ATIVA | Verde Neon | `CheckCircle` | *Nenhum* | Exibição direta do QrCode |
| `waiting_docs` | ENVIAR DOCS | Docs File Cyan | `Description` | **ENVIAR DOCS** | Acessa upload de documentos |
| `suspended` | SUSPENSA | Antique Silver | `Lock` | **REVISAR** | Abre fluxo "Pedir revisão" |
| `expired` | VENCIDA | Crimson Red | `Warning` | **Solicitar Renovação** | Dispara solicitação imediata |
| `renewing` | RENOVANDO | Sand Yellow | `HourglassEmpty` | *Nenhum* | Informativo em análise |
| `rejected` | REPROVADA | Ruby Crimson | `Error` | **VER MOTIVO** | Abre `PremiumStatusDialog` |

---

## 2. Regras Visuais e Comportamento de Seções

### 2.1 Detalhes da Equipe (Motivo / Pendências)
- **Peso Visual:** Equivalente a "Informação importante" (padrão de atenção premium).
- **Regra de Exibição:** Aparece apenas em status que demandem ação ativa ou justificativa administrativa (`rejected`, `suspended`, `waiting_docs`).
- **Ocultação Automática:** Fica oculto em status neutros ou de processamento (`active`, `renewing`, `in_analysis`), garantindo que pendências antigas não causem confusão visual na interface atualizada.

### 2.2 Blindagem de Edição de Dados (`AddMemberPage`)
- Durante o fluxo de correção/revisão de dados (quando o status é `suspended` ou necessita de correção de documentos), a página de edição de membro implementa a validação condicional `_isFieldEnabled`.
- **Regra de Segurança:** Campos sensíveis (como **CPF** e **Data de Nascimento**) são bloqueados para edição caso não façam parte dos itens marcados explicitamente para correção pelo administrador. Isso evita alterações fraudulentas ou acidentais e preserva a consistência dos dados do banco.
