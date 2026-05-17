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

### Fluxo de Solicitação de Novo Dependente / Carteirinha (Frente 26C.1)
- O usuário acessa a página [AddMemberPage](file:///h:/Sites/ConeCTEA/lib/features/requests/add_member_page.dart) a partir da Home ou da aba de carteirinhas.
- Preenche as informações do dependente. A interface distribui o preenchimento de Cidade e Estado em linhas independentes para evitar truncações.
- Preenche os contatos de Emergência e do Responsável, agora em campos de texto individualizados (Nome e Telefone/Celular) para melhor clareza.
- Seleciona o Tipo Sanguíneo no dropdown estruturado com a opção padrão `"Selecione"`.
- O usuário realiza o upload dos documentos e submete a solicitação de forma simplificada e direta.

### Fluxo de Consulta de Carteirinha e Detalhes Rápidos (Frente 26B.1 / 26B.2 / 26B.3-AUD)
- O usuário navega para a aba de Carteirinhas ([cards_view.dart](file:///h:/Sites/ConeCTEA/lib/features/cards/cards_view.dart)).
- Seleciona o dependente no carrossel de membros. A paleta de cor neon se adapta deterministicamente à seed de cores do titular.
- Visualiza o card digital estilizado com o Sapphire Luxe. O usuário pode tocar no card para rotacioná-lo (flip) e visualizar o QR Code administrativo e o texto legal simplificado no verso.
- Logo abaixo da carteirinha, na seção [CardsDetailsSection](file:///h:/Sites/ConeCTEA/lib/features/cards/widgets/tela_carteirinhas/cards_details_section.dart), o usuário consulta rapidamente o bloco informativo de "Validade" e a pill de status administrativo, ambos protegidos contra quebra de layout em telas de 360dp.
- Toca no botão de ação rápida `"VER"` para exibir o documento em tela cheia adaptativa ou no botão `"Girar"` para flipar a carteirinha.

### Fluxo de Acompanhamento de Pedidos e Solicitações (Frente 26D.1)
- O usuário acessa a aba "Pedidos" ou "Solicitações" para monitorar o andamento de seus processos pendentes ou concluídos.
- A tela exibe um sumário organizado de forma limpa em duas seções principais: "EM ANDAMENTO" e "HISTÓRICO".
- O usuário acompanha de forma linear e vertical cada card de solicitação contendo:
  - Faixa colorida superior correspondente ao status (para fácil identificação visual).
  - Pill de status com ícone correspondente no padrão Dark Glass.
  - Título do dependente/solicitação em destaque com ellipsis se necessário.
  - Data de submissão e número do protocolo em linhas individualizadas para máxima leitura vertical.
  - Barra de progresso visual fluida e responsiva baseada na proporção do container.
  - Botão "CORRIGIR" (unificado no padrão `StatusActionButton`) quando houver pendências acionáveis a resolver (como no status "Revisar").
- O usuário pode copiar o protocolo com um clique e receber feedback visual discreto ("Protocolo copiado!").
