# Design System — ConeCTEA

**App:** 0.7.0-dev
**Documentação:** 4.4.0
**Status:** Desenvolvimento
**Atualizado em:** 18/05/2026

---

## Design System — Night Blue Premium
O padrão **Night Blue Premium** é a identidade oficial do app, focada em conforto visual para usuários neurodivergentes.

*   **Estética:** Glassmorphism, gradientes profundos, bordas suaves e sombras sutis.
*   **Cores:** Centralizadas em `lib/core/constants/colors.dart` (`AppColors`).
*   **Modularização da Home:** A `HomeView` isola seções estáticas de blocos reativos através do `HomeDynamicContent`.

---

## Comunicação visual por texto, ícone e cor

O ConeCTEA adota uma regra de comunicação visual em três camadas:
- texto;
- ícone;
- cor.

Essas camadas devem comunicar a mesma intenção. Mesmo vistas separadamente, elas precisam indicar a mesma mensagem semântica. Quando combinadas, reforçam a leitura do usuário.

Exemplo:
- “Acesso restrito” usa texto de restrição, ícone de bloqueio e cor alinhada ao estado de rejeição/restrição.
- “Manutenção Técnica” usa ícone técnico e roxo/violeta reservado para rotinas dev/manutenção.
- “Em breve” usa cor neutra/slate, sem comunicar erro ou bloqueio.

Para mais detalhes sobre componentes específicos, consulte:
*   [Avatares](AVATARES.md)
*   [Componentes Premium](COMPONENTES_PREMIUM.md)
*   [Status Visuais](STATUS_VISUAIS.md)
