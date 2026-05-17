# Status Visuais — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
**Atualizado em:** 17/05/2026

---

## Objetivo

Mapear a identidade visual e os componentes relacionados aos diferentes estados da carteirinha e dos usuários no ConeCTEA.

---

## Identidade de Status

### Status: Suspensa
- Possui identidade visual própria (bronze/dourada).
- Diferencia-se visualmente do status **Reprovada** e do status **Vencida**.
- Utiliza a ação visual “Pedir revisão”.

### Status: Vencida
- É a única condição que exibe a opção de **Solicitar Renovação**.

### Status de Transição
- **Renovando / Aguardando Renovação:** Status de espera, exibido após o usuário solicitar a renovação.

---

## Regras Visuais de Seções

### Detalhes da Equipe
- A seção "Detalhes da equipe" possui peso visual equivalente a "Informação importante".
- Aparece apenas em status onde existe motivo, pendência, restrição ou ação ativa (ex: *Reprovada*, *Suspensa*, *Aguardando Documentação*, *Revisão de Dados*).
- Fica oculta em status neutros ou de análise, evitando exibir pendências antigas indevidamente (ex: *Em Análise*, *Prazo de Aprovação*, *Renovando*).
