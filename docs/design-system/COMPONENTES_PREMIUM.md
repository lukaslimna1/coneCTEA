# Componentes Premium — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
**Atualizado em:** 17/05/2026

---

## Objetivo

Catalogar e padronizar os componentes de interface premium utilizados no ecossistema ConeCTEA.

---

## Componentes

### PremiumStatusDialog

- **Local:** `lib/core/widgets/premium/premium_status_dialog.dart`
- **Padrão Visual:** Night Blue / Lunar Glass.
- **Função:** Componente centralizado para avisos e informativos, substituindo o `AlertDialog` nativo no fluxo “Ver Motivo / Ver Documento Digital”.
- **Características:**
  - Modal puramente informativo.
  - Botão único `Entendido`.
  - Scroll interno para garantir a leitura de justificativas longas.
  - Adaptado para evitar overflow em telas estreitas (360dp).
  - **Restrições:** Não deve conter botão de suporte ou ações de negócio (separação clara entre visual e regras de negócio).
