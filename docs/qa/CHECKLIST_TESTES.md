# Checklist de Testes — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

---

## Objetivo

Fornecer um roteiro de verificações (QA) para garantir o funcionamento seguro dos fluxos críticos antes de qualquer release.

---

## Checklist de Fluxos

### Fluxo de Renovação de Carteirinha
- [ ] Preparar usuário de QA interno.
- [ ] Colocar uma carteirinha de teste no status **Vencida** (`expired`).
- [ ] Confirmar o surgimento do botão “Solicitar Renovação” na Home.
- [ ] Clicar no botão e validar a transição imediata para o status **Renovando** (`renewing`).
- [ ] Validar a chegada da solicitação na tela Administrativa.
- [ ] Aprovar a renovação via Admin.
- [ ] Validar o retorno da carteirinha para o status Ativa (`active`).
- [ ] Validar que a carteirinha continua a mesma (não foi gerada duplicidade no banco).
- [ ] Alterar o status para **Suspensa** e validar que a opção de renovação não aparece.

---

## Checklist Obrigatório (Pré-Finalização de Tarefa)

Antes de finalizar qualquer tarefa, valide os seguintes pontos:
- [ ] `flutter analyze` sem issues;
- [ ] `flutter build apk --debug` com sucesso na compilação;
- [ ] `git diff --check` sem erros reais de whitespace;
- [ ] `git status --short` para verificar arquivos modificados;
- [ ] teste visual do fluxo afetado em Android;
- [ ] priorizar perfis estreitos 320dp/360dp quando a alteração for visual;
- [ ] validar portrait e landscape quando aplicável;
- [ ] sem commit/push automáticos sem autorização explícita do Lucas;
- [ ] nunca usar `git add .`.

---

## Checklist de Responsividade da Home (Frente 26A)

Este checklist serve como guia para apoiar a mitigação de falhas visuais ou quebras de layout em futuras atualizações da Home:

### 1. Header e SafeArea Superior Adaptativa
- [ ] Iniciar o app em simulador com cutout específico (ex: Gota, Tall cutout ou Corner).
- [ ] Validar que o logotipo no `AppTopHeader` não fica sobreposto à status bar ou cortado fisicamente.
- [ ] Confirmar que o clearance entre o Header e o Hero ("Olá, Nome") permanece harmonioso em `8.0` pixels, sem vãos excessivos.
- [ ] Validar comportamento em rotação (se aplicável), garantindo integridade visual.

### 2. PremiumBottomNavBar (Barra de Navegação Premium)
- [ ] Abrir o app em dispositivo configurado com **Navegação por Gestos** do sistema Android.
- [ ] Validar que o padding inferior se ajusta adequadamente de forma nativa para evitar que o indicador de gestos colida com os botões/ícones da navbar.
- [ ] Alternar para o modo de **3 Botões Tradicionais** do Android.
- [ ] Validar que a navbar se posiciona de forma compacta imediatamente acima da barra de botões nativa, sem folgas excessivas.
- [ ] Alternar freneticamente entre as abas (Home, Carteirinha, etc.) e validar que **NENHUM RenderFlex ou tremor de milissegundos** ocorre durante as animações de transição de largura.

### 3. Membros e Seletores Familiares
- [ ] **Cenário recomendado de validação futura:** Aumentar o zoom de exibição/fonte do sistema operacional para 1.2x e 1.5x.
- [ ] Validar que os avatares neon em `HomeMembersSection` mantêm seu tamanho proporcional sem sofrer recortes verticais ou disparar exceções de overflow.

### 4. Carrosséis e Margens de Sombra (Buffers Seguros)
- [ ] Validar que o card de Acesso Rápido (`QuickAccessCard`) termina de forma compacta e simétrica logo abaixo de seu respectivo CTA, sem deixar espaços vazios indesejados.
- [ ] Confirmar que a altura do carrossel pai do Acesso Rápido está fixada em `148` no máximo.
- [ ] Rolar o carrossel de "Outros Serviços" e "Informações" e confirmar que as sombras inferiores (`BoxShadow` premium) são desenhadas integralmente, sem recortes ou linhas duras abruptas causadas por contêineres pais muito estreitos.

---

## Checklist de Formulário de Dependente & Teclado (Frente 26C.1 / 26C.2)

Verificações para garantir a estabilidade do fluxo de cadastro e o comportamento dinâmico da interface sob foco de teclado virtual:

### 1. Preenchimento de Campos e Layout do Formulário
- [ ] Navegar para `lib/features/requests/add_member_page.dart` na Home ou seção de carteirinhas.
- [ ] Validar que a Cidade e o Estado estão devidamente isolados em linhas separadas e preenchem corretamente o espaço horizontal.
- [ ] Confirmar que os campos de contatos de Emergência e Responsável estão visualmente separados em entradas dedicadas para Nome e Telefone individualizados.
- [ ] Selecionar Tipo Sanguíneo e validar que o placeholder inicial exibe exatamente `"Selecione"`.
- [ ] Confirmar se, ao recarregar a tela sem dependente selecionado ou com valor inicial nulo, o widget `RequestDropdownField` (`lib/features/requests/widgets/request_dropdown_field.dart`) renderiza adequadamente a dica de seleção.

### 2. Ocultação Dinâmica da Navbar com Teclado IME
- [ ] Em um emulador ou dispositivo físico com a barra de 3 botões tradicionais do Android ativa, toque em qualquer campo de texto no formulário de dependente.
- [ ] Validar que o teclado virtual sobe e a [PremiumBottomNavBar](../design-system/COMPONENTES_PREMIUM.md#2-premiumbottomnavbar) desaparece imediatamente, liberando o espaço da tela.
- [ ] Rolar o formulário verticalmente para atestar que os campos inferiores estão totalmente legíveis e roláveis sob a área do teclado.
- [ ] Dispensar o teclado virtual ou pressionar o botão voltar do celular.
- [ ] Validar que a barra de navegação premium ressurge imediatamente em sua posição original e sem nenhum travamento visual ou RenderFlex.

---

## Checklist de Detalhes da Carteirinha (Frente 26B.1 / 26B.2 / 26B.3-AUD)

Testes específicos de responsividade estrutural e estética premium nos cartões e blocos informativos:

### 1. Visual da Carteirinha Digital (Sapphire Luxe)
- [ ] Selecionar dependentes com diferentes paletas neon e verificar se a seed se ajusta corretamente.
- [ ] Verificar o card no Sapphire Luxe e confirmar se o token/número identificador da carteirinha está ampliado e legível.
- [ ] Atravessar para o verso (flip) e confirmar que o QR Code e o texto descritivo legal resumido estão harmoniosos e livres de overflow.
- [ ] Certificar-se de que nenhum contato de emergência secundário é impresso de forma gráfica na frente ou no verso do cartão Sapphire Luxe (a ocultação é puramente visual).

### 2. Seção de Detalhes e Ações Rápidas (Telas Estreitas - 360dp)
- [ ] Executar o teste visual no emulador ou dispositivo com largura de tela de 360dp (como Samsung A05/A06).
- [ ] Validar se o bloco de validade ("Válida até") exibe o ícone de calendário de `14dp` e o padding reduzido, permanecendo alinhado sem quebras.
- [ ] Verificar se o texto do botão CTA secundário exibe exatamente o texto compacto `"VER"`.
- [ ] Confirmar que os botões `"VER"` e `"Girar"` dividem o espaço de forma proporcional de 50/50 e não geram transbordos de layout.
- [ ] **Validação com zoom:** Aumentar a escala tipográfica do sistema operacional do smartphone/emulador para 1.5x e confirmar que os labels mais longos utilizam reticências e sofrem decaimento suave via `TextOverflow.ellipsis`, sem quebrar a integridade elástica do `CardsDetailsSection`.

---

## Checklist de Histórico e Pedidos/Solicitações (Frente 26D.1)

Testes de responsividade técnica e de experiência visual na tela de Pedidos e Solicitações (`RequestsView`):

### 1. Responsividade e Estabilidade de Layout dos Cards (360dp a 412dp)
- [ ] Executar teste visual no emulador ou dispositivo real com perfil estreito de 360dp (Samsung A05/A06).
- [ ] Validar que cada card de solicitação é renderizado verticalmente com:
  - Faixa/acento superior colorido grudado no topo correspondente à cor do status (sem vãos brancos/escuros nas curvas superiores devido ao `ClipRRect`).
  - Pill de status com ícone visível no canto superior esquerdo do conteúdo.
  - Título principal alinhado e contido via `Expanded` com reticências (`TextOverflow.ellipsis`) em caso de textos muito longos.
  - Protocolo copiável e data de solicitação exibidos em linhas individuais próprias logo abaixo.
- [ ] Pressionar o botão "Copiar" ao lado do protocolo e verificar se o feedback visual ("Protocolo copiado!") é exibido de forma discreta e legível.
- [ ] Validar que o botão "CORRIGIR" (quando disponível para status acionáveis como "Revisar") é renderizado adequadamente no canto inferior direito, sem empurrar outros elementos ou estourar a base do card.

### 2. Barra de Progresso Dinâmica com LayoutBuilder
- [ ] Redimensionar a tela ou simular aparelhos de diferentes larguras na bancada de testes.
- [ ] Confirmar que o cálculo de preenchimento proporcional da barra de progresso (baseado no valor dinâmico de `progressValue`) permanece restrito aos limites internos do card via `LayoutBuilder(constraints.maxWidth)`.
- [ ] Verificar que não ocorre nenhum estouro lateral de RenderFlex em larguras estreitas (360dp).

### 3. Legibilidade do Contador de Registros (Dark Glass)
- [ ] Localizar os cabeçalhos de seção "EM ANDAMENTO" e "HISTÓRICO".
- [ ] Validar que a contagem numérica de solicitações ao lado de cada cabeçalho é exibida em branco suave (`white.withValues(alpha: 0.92)`).
- [ ] Verificar que a pill de contorno roxo discreto e fundo Dark Glass oferece excelente taxa de contraste e boa legibilidade em ambientes de iluminação adversa.
