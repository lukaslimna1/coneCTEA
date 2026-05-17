# Status e Regras — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
**Atualizado em:** 17/05/2026

---

## Objetivo

Mapear as regras de negócio associadas aos diferentes status da carteirinha e da plataforma.

---

## Regras Operacionais por Status

### Renovação
- A flag `canRenew` é exclusiva para o status **Vencida** (`expired`).
- Carteirinhas no status **Suspensa** ou **Reprovada** não podem entrar no fluxo de renovação.
- **Renovando** é um estado estritamente de espera, ativado logo após o usuário solicitar a renovação da carteirinha.

### Exibição de Informações
- O campo `notes` (justificativas, motivos de recusa) não é apagado do banco de dados quando o usuário envia correções.
- A exibição do "Detalhes da equipe" na UI é baseada em regras de apresentação, não devendo aparecer em status neutros ou de análise.
