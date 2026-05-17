# Bugs Conhecidos — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
**Atualizado em:** 16/05/2026

---

## Objetivo

Descrever o objetivo deste documento dentro da documentação profissional do ConeCTEA.

---

## Escopo

Este documento será preenchido progressivamente conforme as frentes forem consolidadas.

---

## Seções planejadas

- A definir.

---

## Bugs Relacionados à Home (Próxima Frente Responsiva)

*Nota: Estas falhas devem ser resolvidas na próxima frente de Home Responsiva.*

- **Overflow na Navbar:** A `PremiumBottomNavBar` apresenta um overflow de milissegundos durante a troca de abas. O espaço disponível muda dinamicamente conforme o modo de navegação ativo (gestos vs 3 botões tradicionais).
- **Erro de RenderFlex:** Há um erro conhecido que envolve `RenderFlex` dentro de `Row` com largura muito pequena. Exemplo técnico do problema: a largura de um item chega perto de 19.7px durante a animação/transição, causando falha visual momentânea.
- **Header e SafeArea:** O conteúdo do header não está perfeitamente blindado contra recortes, necessitando auditoria estrita no uso do `SafeArea` para câmeras frontais, notch, gota, ilhas e furos, evitando que o conteúdo seja empurrado de forma quebrada.

---

## Observações

Este arquivo foi criado como parte da estrutura profissional de documentação do ConeCTEA.
