# Fluxos Usuário — ConeCTEA

**App:** 0.6.0-dev
**Documentação:** 4.3.0
**Status:** Em construção
**Atualizado em:** 18/05/2026

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
- Validar o retorno da carteirinha para o status Ativa após aprovação pelo administrador.

### Fluxo de Solicitação de Novo Dependente / Carteirinha (Frente 26C.1)
- O usuário acessa a página `lib/features/requests/add_member_page.dart` a partir da Home ou da aba de carteirinhas.
- Preenche as informações do dependente. A interface distribui o preenchimento de Cidade e Estado em linhas independentes para evitar truncações.
- Preenche os contatos de Emergência e do Responsável, agora em campos de texto individualizados (Nome e Telefone/Celular) para melhor clareza.
- Seleciona o Tipo Sanguíneo no dropdown estruturado com a opção padrão `"Selecione"`.
- O usuário realiza o upload dos documentos e submete a solicitação de forma simplificada e direta.

### Fluxo de Consulta de Carteirinha e Detalhes Rápidos (Frente 26B.1 / 26B.2 / 26B.3-AUD)
- O usuário navega para a aba de Carteirinhas (`lib/features/cards/cards_view.dart`).
- Seleciona o dependente no carrossel de membros. A paleta de cor neon se adapta deterministicamente à seed de cores do titular.
- Visualiza o card digital estilizado com o Sapphire Luxe. O usuário pode tocar no card para rotacioná-lo (flip) e visualizar o QR Code administrativo e o texto legal descritivo simplificado no verso.
- Logo abaixo da carteirinha, na seção `CardsDetailsSection` (`lib/features/cards/widgets/tela_carteirinhas/cards_details_section.dart`), o usuário consulta rapidamente o bloco informativo de "Validade" e a pill de status administrativo, ambos protegidos contra quebra de layout em telas de 360dp.
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

### Fluxo de Revisão de Dados e Reenvio de Documentos (Frente 26F)
- O usuário acessa a solicitação pendente com status "Revisar" a partir da lista de Pedidos/Solicitações ou diretamente através dos alertas contextuais na Home.
- Ao clicar em "CORRIGIR", o usuário é direcionado para o formulário de edição (`AddMemberPage`).
- No topo da página, um banner premium compacto com o título "Ajustes solicitados" apresenta as observações inseridas pelo administrador, indicando com clareza quais correções devem ser realizadas, com redimensionamento elástico adaptado a telas de 360dp de largura.
- O formulário bloqueia visualmente todos os campos já validados (como CPF, Nome, Data de Nascimento, etc., caso não tenham sido objeto da revisão). Apenas os campos sinalizados para correção ficam liberados para edição.
- Caso o administrador solicite a revisão de documentos:
  - Os seletores para "Documento com Foto" e/ou "Laudo Médico" aparecem limpos e com a indicação textual de "Documento obrigatório nesta etapa" em destaque, evitando a impressão incorreta de que o envio é opcional nessa fase de saneamento de pendências.
  - O campo para Código CID é liberado para digitação apenas se o Laudo Médico tiver sido solicitado para revisão.
- O usuário preenche as informações corrigidas, faz o upload dos novos documentos necessários e clica em "Salvar e Continuar".
- A solicitação é atualizada e retorna para a fila de análise administrativa, bloqueando novamente a edição no lado do usuário.

### Jornada de Saída Segura ("Fazer mais tarde") e Descarte de Alterações (Frente 26G)
Este fluxo oferece mais conforto e flexibilidade às famílias, permitindo que elas interrompam o preenchimento ou correção de dados a qualquer momento e saiam com segurança da tela, sem a pressão de ter que resolver tudo no mesmo instante:

1. **Decisão de Pausa:** Durante o preenchimento de um novo cadastro ou na tela de correção de pendências, o responsável pela criança/dependente percebe que não possui um documento em mãos ou que precisa pausar o processo. Ele decide tocar no botão `"Fazer mais tarde"` (posicionado ao lado da ação de envio) ou simplesmente usa o botão ou gesto de voltar nativo de seu smartphone.
2. **Saída Sem Alterações:** Se a família não preencheu nenhuma nova informação nos campos habilitados e não realizou nenhum upload durante aquela sessão de edição, o aplicativo reconhece que não há novos dados em risco. A tela é fechada imediatamente, retornando à visualização anterior de forma limpa e direta.
3. **Alerta de Descarte Seguro:** Caso o usuário tenha digitado novas informações nos campos ou selecionado um novo arquivo de Laudo Médico ou Documento com Foto, o aplicativo detecta a presença de alterações pendentes e apresenta uma janela de aviso amigável e cuidadosa, perguntando se ele deseja descartar as alterações daquela sessão:
   - **"Continuar Editando":** Cancela o aviso e mantém o usuário exatamente no formulário onde ele estava, preservando todos os campos preenchidos e uploads efetuados para que ele possa continuar sua edição.
   - **"Sair sem Salvar":** Confirma que ele deseja sair da tela imediatamente, abandonando as modificações não gravadas.
4. **Descarte Local e Higiene de Dados na Nuvem:** Ao confirmar `"Sair sem Salvar"`:
   - As novas alterações inseridas apenas naquela sessão são descartadas localmente.
   - Se novos documentos foram carregados temporariamente na nuvem durante aquela sessão, o aplicativo inicia em segundo plano uma tentativa de exclusão física seletiva dessas URLs recém-geradas no Google Drive institucional, preservando a higiene do espaço remoto de armazenamento e a privacidade dos dados.
   - Os documentos oficiais antigos que já haviam sido salvos anteriormente ou dados salvos **permanecem completamente preservados e intocados**, garantindo a segurança histórica do cadastro.
   - O status da solicitação não sofre nenhuma alteração, nenhuma notificação nova é criada no sistema ou enviada ao administrador, e a pendência permanece disponível no painel de solicitações do usuário para que ele volte a editá-la e corrigi-la posteriormente, no momento em que lhe for mais oportuno.
