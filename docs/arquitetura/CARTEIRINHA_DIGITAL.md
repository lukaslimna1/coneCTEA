# Carteirinha Digital — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 16/05/2026

---

## 5.5 Área de Carteirinhas (CardsView)
A visualização de carteirinhas foi totalmente modularizada:
*   **Orquestração:** `CardsView` gerencia streams, seleção de membros e troca de estados. Propaga a `paletteSeed` da conta titular para todos os avatares de dependentes no seletor (`CardsMemberSelector`).
*   **Estados Extraídos:** Componentes específicos para estados de `empty`, `pending` (aguardando aprovação) e `error`.
*   **Acessibilidade:** O CTA "Cadastrar novo dependente" foi reposicionado para garantir visibilidade fora do seletor de membros.
*   **Seção de Detalhes (Frente 26B.2 / 26B.3-AUD):** O componente `CardsDetailsSection` (`lib/features/cards/widgets/tela_carteirinhas/cards_details_section.dart`) implementa a renderização de blocos informativos e botões de ação horizontais. Protegido estruturalmente com `Expanded`, `maxLines: 1` e `TextOverflow.ellipsis` em todas as `Row`s dinâmicas, mitigando overflows observados em aparelhos estreitos (Samsung A05/A06 360dp). A página inteira é contida por um `ListView` em `cards_view.dart` (`lib/features/cards/cards_view.dart`), assegurando rolagem vertical segura.

---

## 5.6 Carteirinha Digital (DigitalCardWidget)
Componente modular e performático:
*   `digital_card_widget.dart`: Orquestrador de flip, animação e controle de visibilidade do CPF.
*   `digital_card_front.dart`: Interface frontal com dados principais e status. Utiliza o sistema oficial de avatar e consome `StatusVisualTokens` para as pills de status, mantendo a consistência visual com o restante do app.
*   `digital_card_back.dart`: Verso contendo QR Code para validação administrativa e texto legal.
*   `digital_card_background.dart` e `digital_card_motion_wrapper.dart`: Estética premium e parallax.
*   **Refinamento Sapphire Luxe (Frente 26B.1):**
    - O fundo da carteirinha foi refinado no tema Sapphire Luxe (`digital_card_background.dart` (`lib/features/cards/widgets/carteirinha_digital/digital_card_background.dart`)).
    - A visualização do token/número identificador da carteirinha foi ampliada para maior clareza visual.
    - O tipo sanguíneo e o logotipo do CID receberam novos contrastes integrados à paleta Sapphire Luxe.
    - O texto descritivo legal no verso (`digital_card_back.dart` (`lib/features/cards/widgets/carteirinha_digital/digital_card_back.dart`)) foi resumido para melhor adequação física da tipografia.
    - Os contatos de emergência e de responsável legal foram ocultados exclusivamente da representação gráfica da carteirinha digital para evitar poluição visual do layout Sapphire Luxe, embora os dados continuem devidamente preservados nos modelos e no banco de dados da plataforma.

---

## 5.7 Tela Cheia Adaptativa (FullScreenCardPage)
Implementação de responsividade defensiva:
*   **Portrait/Landscape:** Layouts otimizados com `SingleChildScrollView` e `FittedBox` para evitar overflows em qualquer resolução Android.
