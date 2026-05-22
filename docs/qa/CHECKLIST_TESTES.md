# Checklist de Testes — ConeCTEA

**App:** 0.6.0-dev
**Documentação:** 4.3.0
**Status:** Desenvolvimento
**Atualizado em:** 18/05/2026

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

---

## Checklist de Revisão de Dados e Reenvio de Documentos (Frente 26F)

Verificações para garantir a estabilidade visual do banner de pendências, o destravamento seletivo de inputs e a integridade de exclusões no Drive e Supabase:

### 1. Banner "Ajustes solicitados" e Responsividade
- [ ] Colocar uma solicitação no status de pendência ("Revisar") e preencher observações do administrador.
- [ ] Abrir o formulário de edição do dependente (`AddMemberPage`) e validar que o banner "Ajustes solicitados" é renderizado no topo.
- [ ] Testar em emulador com largura de 360dp e garantir que o banner se ajusta de forma elástica, sem apresentar qualquer overflow horizontal de renderização ou quebra textual dura.

### 2. Bloqueio e Destravamento Condicional de Campos e CID
- [ ] **Caso A: Reenvio de apenas campos cadastrais textuais (ex: Nome).**
  - [ ] Validar que apenas o campo de Nome está habilitado para alteração.
  - [ ] Verificar se os documentos (RG, Laudo) e o campo CID estão bloqueados de forma segura contra escrita.
- [ ] **Caso B: Reenvio apenas de "Documento com Foto" (RG).**
  - [ ] Validar que o campo tipográfico de Código CID está desabilitado.
  - [ ] Confirmar que o seletor para "Documento com Foto" está habilitado e exibe o label obrigatório em destaque ("Documento obrigatório nesta etapa"), enquanto o seletor de "Laudo Médico" está completamente bloqueado e preserva a URL anterior.
- [ ] **Caso C: Reenvio de "Laudo Médico".**
  - [ ] Validar que o campo de Código CID está reativo e liberado dinamicamente para digitação pelo usuário.
  - [ ] Confirmar que o seletor para "Laudo Médico" está habilitado e limpo com o aviso de obrigatoriedade, enquanto o seletor de "Documento com Foto" permanece bloqueado.

### 3. Integridade da Seleção e do Upload de Arquivos
- [ ] Abrir a tela de reenvio de documento e selecionar um novo arquivo local (simular pick com imagem ou PDF).
- [ ] Validar que a seleção do arquivo local NÃO aciona nenhuma exclusão lógica ou solicitação de limpeza física do arquivo anterior de forma precoce no Google Drive.
- [ ] Fechar a tela sem salvar e reabri-la; atestar que os documentos anteriores continuam consistentes no Supabase (URLs não quebradas).
- [ ] Concluir o reenvio clicando em "Salvar e Continuar" e confirmar que o novo arquivo é persistido de forma integrada no Google Drive e no Supabase.

### 4. Limpeza Seletiva de Arquivos no Lado do Administrador
- [ ] No painel administrativo, simular a rejeição de apenas o "Documento com Foto", validando o envio da solicitação de limpeza do arquivo antigo no Drive.
- [ ] Confirmar no terminal de logs que o disparo do fluxo de exclusão seletiva via `GoogleDriveService.deleteFile` solicita a limpeza física estritamente do Documento com Foto antigo no Drive, deixando a URL e o arquivo do Laudo Médico intocados.
- [ ] Simular a rejeição de "Laudo Médico" apenas; confirmar no terminal que foi solicitada a exclusão física do Laudo Médico obsoleto no Drive e que o Documento com Foto antigo permanece seguro e com link funcional.
- [ ] Validar que falhas de conexão ou erros de API durante a exclusão do arquivo físico no Drive não travam a atualização lógica da solicitação no banco do Supabase, registrando o erro silenciosamente nos logs administrativos para fins de auditoria e mitigação operacional.

---

## Checklist de Testes do Botão "Fazer mais tarde" e Descarte de Alterações (Frente 26G)
Verificações estruturais e operacionais para garantir a consistência do descarte seguro de dados e a higiene de uploads temporários na `AddMemberPage`:

> [!NOTE]
> Itens marcados como concluídos refletem validação funcional realizada por Lucas na bancada local. Manter em observação para testes futuros de rede/Drive.

### 1. Comportamento Sem Alterações
- [x] **Fluxo de Cadastro Inicial:** Abrir a tela de novo cadastro dependente, não alterar nenhum campo (deixar controllers de texto vazios, tipo sanguíneo sem seleção e sem novos arquivos anexados) e tocar em `"Fazer mais tarde"`. Validar que a tela é fechada imediatamente sem exibir modal de confirmação.
- [x] **Fluxo de Correção de Pendência (`reviewing_data` / `waiting_docs`):** Acessar a tela de correção a partir de uma solicitação rejeitada, não realizar nenhuma alteração nos campos desbloqueados e tocar em `"Fazer mais tarde"` (ou usar voltar físico/gesto). Confirmar que a tela fecha direto e sem diálogos.

### 2. Comportamento Com Alterações Cadastrais
- [x] **Modificação de Texto:** No cadastro ou correção, alterar qualquer campo tipográfico habilitado (ex: preencher um caractere no campo de nome ou observações). Tocar em `"Fazer mais tarde"` ou usar voltar do sistema. Validar a exibição do diálogo `"Descartar alterações?"` contendo os botões `"Continuar Editando"` e `"Sair sem Salvar"`.
- [x] **Interrupção e Retorno:** No modal de descarte, clicar em `"Continuar Editando"`. Confirmar que o modal fecha, o usuário permanece na tela de formulário e todas as informações provisórias preenchidas continuam ativas e visíveis.
- [x] **Descarte Técnico:** Modificar um campo e clicar em `"Sair sem Salvar"`. Confirmar que a tela fecha e a informação alterada não foi gravada nem no Supabase nem mantida na reabertura subsequente.

### 3. Comportamento Com Novos Uploads Temporários
- [x] **Higiene do Drive (Laudo Médico Novo):**
  - [x] Habilitar o reenvio de Laudo Médico, anexar um arquivo local novo (imagem ou PDF). Isso gerará um upload temporário no Drive e registrará a URL provisória no app.
  - [x] Pressionar `"Fazer mais tarde"` ou voltar físico. Validar a exibição do diálogo de descarte.
  - [x] Selecionar `"Sair sem Salvar"`.
  - [ ] Acessar os logs de depuração do terminal administrativo/depuração local e validar o acionamento assíncrono do método `RequestCleanupHelper.cleanupTempUploadedUrls`.
  - [ ] Verificar se há a tentativa assíncrona de deleção da URL temporária gerada naquela sessão, mantendo em observação possíveis falhas de conexão de rede ou interrupções abruptas que gerem riscos residuais de arquivos órfãos.
- [x] **Higiene do Drive (Documento com Foto Novo):** Repetir o teste anterior para o upload temporário do Documento com Foto (RG). Confirmar que o descarte solicita a limpeza física do novo arquivo provisório no Drive.
- [x] **Higiene do Drive (Múltiplos Uploads Novos):** Anexar tanto Laudo quanto RG na mesma sessão ativa, confirmar a saída sem salvar e validar no console que ambos os novos arquivos foram catalogados para a tentativa de exclusão física no Drive.

### 4. Preservação de Dados e Documentos Oficiais/Antigos
- [x] **Preservação de URLs Consolidadas:** Em uma solicitação de reenvio de Laudo Médico (`waiting_docs` onde o Documento com Foto anterior já foi validado e está salvo), preencher novos dados no Laudo e clicar em `"Sair sem Salvar"`. Validar no banco do Supabase ou reabertura da tela que a URL e o arquivo físico consolidados do Documento com Foto antigo continuam totalmente preservados e funcionais.
- [x] **Preservação de Dados de Cadastro:** Confirmar que ao sair sem salvar, nenhuma chamada a métodos de envio (`_handleSave`) ocorre por baixo do capô, mantendo o status do dependente inalterado no Supabase.

### 5. Integridade do Fluxo Administrativo e Comunicações
- [x] **Ausência de Notificações de Saída:** Validar que ao sair sem salvar, nenhuma entrada de notificação é gerada para o usuário titular ou para o painel do administrador.
- [x] **Preservação de Status:** Atentar para que o status do cadastro do membro não mude (ex: continue em `reviewing_data` ou `waiting_docs` exatamente como estava antes de abrir a tela), permitindo que a pendência permaneça visível na lista para correção futura.

---

## Checklist de Validação Visual da Central do Usuário

Diretrizes de QA específicas para garantir a alta fidelidade estética (*Night Blue / Dark Glass Premium*), a responsividade estrutural e a barreira lógica nas telas e diálogos da Central do Usuário:

### 1. Privacidade e Dados
- [ ] **Dados Armazenados:** Abrir a tela de categorias e rolar o conteúdo completo em largura estreita (360dp, ex: Samsung A05/A06), validando que não há overflows e que as descrições de dados possíveis são totalmente legíveis.
- [ ] **Uso das Informações:** Rolar o conteúdo informativo em 360dp, garantindo clearance inferior adequado e alinhamento do botão "Entendi".
- [ ] **Consentimentos e Autorizações:** Confirmar que todos os switches funcionam localmente (ativar/desativar), apresentando adequadamente os selos dinâmicos **"Ativo"** (verde soft) ou **"Desativado"** (cinza/opaco). Validar que nenhuma persistência no banco Supabase ou chamada de rede é realizada, pois os switches são puramente visuais nesta etapa.
- [ ] **Termos de Uso:** Acessar a tela interna e validar que o conteúdo Markdown estático é renderizado com formatações de negrito e listas organizadas (bullets), **sem exibir** sintaxe bruta como `**` ou `-`.
- [ ] **Política de Privacidade:** Acessar a tela interna de leitura e validar a renderização livre de marcações brutas (negrito e listas convertidos semânticamente).
- [ ] **Ação do Botão "Entendi":** Certificar-se de que ao pressionar o botão "Entendi" nos Termos de Uso ou na Política de Privacidade, a tela apenas retorna (`Navigator.pop`) e **não registra** ou persiste aceite real no banco.

### 2. Segurança da Conta
- [ ] **Modal de Exclusão de Conta:** Abrir o diálogo de segurança em dispositivos estreitos (Samsung A05/A06 com largura de 360dp) e verificar se o modal completo e seus campos de validação cabem perfeitamente.
- [ ] **Barreira de Confirmação:** Tentar clicar em "Confirmar Exclusão" sem preencher o input. Validar que o botão está completamente desabilitado.
- [ ] **Texto de Validação:** Digitar exatamente `"EXCLUIR CONTA"` no campo. Validar que o botão só é habilitado após a correspondência exata de letras.
- [ ] **Teclado Virtual (IME Clearance):** Confirmar que o teclado virtual não esconde o campo de texto nem o botão de ação do modal, mantendo a janela de diálogo rolável/visível.
- [ ] **Caráter Mockado:** Certificar-se de que a ação de confirmação de exclusão emite apenas um feedback visual local e fecha o modal, **sem alterar** dados de sessão em `AuthService` ou disparar deleções em Supabase.

### 3. Dependentes e Correções
- [ ] **Modal de Remoção de Dependente:** Abrir o modal a partir do botão "Remover" nos detalhes do dependente e testar em 360dp.
- [ ] **Barreira de Confirmação:** Digitar exatamente `"REMOVER"`. Validar que o botão de ação só é liberado mediante preenchimento exato da palavra de confirmação em letras maiúsculas.
- [ ] **Rolagem de Detalhes:** Validar que a tela de detalhes de dependentes e de solicitação de correção por campo (`DependentCorrectionView`) rola suavemente, sem overflows horizontais ou verticais em telefones estreitos.
- [ ] **Caráter Mockado:** Confirmar que a solicitação de correção por campo e a remoção final de dependente não persistem dados remotamente nem modificam o estado no Supabase.

### 4. Estrutura Institucional e Hub Informativo
- [ ] **Rolagem do Hub:** Acessar a tela principal `InstitutionalView` e garantir que todos os cards informativos em coluna única e o aviso "Importante" inferior são visíveis via rolagem até o fim em 360dp.
- [ ] **Preservação de Cards Sem Ação:** Validar que os cards de "Natureza da iniciativa", "Carteirinha comunitária" e "Atuação principal" permanecem estáticos, sem botões de ação e sem efeito visual de clique.
- [ ] **Separação de Projetos e Parceiros:**
  - [ ] Acessar `ProjectsActionsView` e confirmar que ela lista apenas Fada do Dente, Vidas e Eventos, sem menções, cards ou referências diretas à rede de parceiros comerciais.
  - [ ] Acessar `PartnersSupportersView` via card separado da `InstitutionalView` e verificar se a listagem visual de parceiros de benefícios e apoiadores é apresentada isoladamente.
- [ ] **Navegação de Retorno:** Testar abertura e botões "Entendi"/voltar em todas as subviews (`AboutConecteaView`, `FamilyTeaView`, `ProjectsActionsView`, `PartnersSupportersView`) garantindo retorno seguro à página de origem.

### 5. Informações do ConeCTEA
- [ ] **Compatibilidade em 360dp:** Acionar o modal e validar que toda a estrutura de versão/build, ambiente e tecnologias de apoio cabe perfeitamente nas dimensões físicas sem gerar cortes.
- [ ] **Tecnologias de Apoio:** Validar a legibilidade e clareza da listagem de tecnologias integradas (Supabase, Flutter, Drive/GAS, OneSignal).
- [ ] **Acessibilidade do Botão Fechar:** Confirmar que o botão "Fechar" do modal permanece acessível e operável mesmo em resoluções estreitas.
