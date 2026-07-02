# Design System V2 - Inventario e Uso Oficial v4.5

**App:** ConeCTEA
**Documentacao:** 4.5
**Status:** fonte de referencia operacional
**Atualizado em:** 02/07/2026
**Escopo:** componentes, tokens e padroes existentes em `lib/core/design_system_v2` e integracao com `lib/core/campos_cadastrais`

Este documento descreve o Design System V2 conforme encontrado no codigo atual. Ele nao cria contrato novo, nao substitui implementacao e nao autoriza migracoes automaticas. Em caso de divergencia, o codigo em `lib/core/design_system_v2` prevalece.

## Principios

- Usar primeiro os tokens, componentes e padroes exportados por `lib/core/design_system_v2/design_system_v2.dart`.
- Priorizar telas mobile-first e Android-first, com leitura rapida, contraste alto e baixa carga visual.
- Manter a identidade visual premium com base em Night Blue, superficies escuras, vidro escuro, bordas discretas e acentos semanticos.
- Usar cor semantica para orientar hierarquia, estado e categoria, evitando pintar blocos inteiros sem necessidade.
- Preferir componentes DS V2 antes de criar `Container`, `TextField`, `InputDecoration`, `AlertDialog`, `SnackBar` ou loaders manuais.
- Preservar acessibilidade: alvo de toque adequado, texto legivel, feedback claro, contraste e estados perceptiveis.
- Documentar gaps sem transformar este arquivo em plano de refatoracao.

## Arquivos Fonte

| Area | Arquivo |
| --- | --- |
| Barrel DS V2 | `lib/core/design_system_v2/design_system_v2.dart` |
| Tokens | `lib/core/design_system_v2/tokens/*.dart` |
| Componentes | `lib/core/design_system_v2/componentes/*.dart` |
| Padroes | `lib/core/design_system_v2/padroes/*.dart` |
| Campos Cadastrais | `lib/core/campos_cadastrais/campos_cadastrais.dart` |

## Tokens

| Token | Arquivo | Uso recomendado | Evitar |
| --- | --- | --- | --- |
| `DsCores`, `DsCorVisual` | `tokens/ds_cores.dart` | Cores semanticas, gradientes oficiais, categorias visuais e estados gerais. | Cores hardcoded quando houver token equivalente. |
| `DsEspacamentos` | `tokens/ds_medidas.dart` | Espacamentos consistentes entre blocos, listas, campos, botoes e secoes. | Margens arbitrarias sem motivo visual claro. |
| `DsRaios` | `tokens/ds_medidas.dart` | Raios de borda para cards, inputs, botoes e superficies. | Bordas excessivamente arredondadas fora do padrao da tela. |
| `DsTamanhos` | `tokens/ds_medidas.dart` | Alturas, larguras e dimensoes recorrentes. | Numeros soltos em componentes reutilizaveis. |
| `DsSombras` | `tokens/ds_medidas.dart` | Profundidade discreta em superficies relevantes. | Glow pesado ou sombra decorativa sem funcao. |
| `DsTipografia` | `tokens/ds_tipografia.dart` | Estilos de texto oficiais para titulos, corpo, rotulos e mensagens. | Fontes/tamanhos manuais em componentes comuns. |
| `DsTokenStatus` | `tokens/ds_tokens_status.dart` | Status de carteirinha, solicitacoes e revisoes com cor, icone e texto consistentes. | Mapear status manualmente em cada tela. |
| `DsPaletasAvatar` | `tokens/ds_paletas_avatar.dart` | Paletas estaveis para avatares e identificacao visual de pessoas. | Gerar cores aleatorias por tela. |

Tokens semanticos relevantes em `DsCores`: `conta`, `usuario`, `dependente`, `seguranca`, `privacidade`, `termos`, `dadosProtegidos`, `carteirinha`, `solicitacao`, `correcao`, `visualizacao`, `suporte`, `comunicacao`, `institucional`, `clube`, `admin`, `restricao`, `manutencao`, `sucesso`, `alerta`, `perigo` e `fallback`.

Gradientes oficiais encontrados: `nightGradient`, `cardGradient`, `adminGradient` e `carteirinhaGradient`.

`DsMedidas` nao foi encontrado como classe unica no codigo atual. O arquivo `tokens/ds_medidas.dart` expoe `DsEspacamentos`, `DsRaios`, `DsTamanhos` e `DsSombras`.

`DsTokensVisuais` nao foi encontrado no codigo atual. Nao documentar nem usar esse nome como API disponivel; usar `DsCores`, `DsCorVisual` e `DsTokenStatus`.

## Componentes

| Componente | Arquivo | Uso recomendado | Quando evitar / observacoes |
| --- | --- | --- | --- |
| `DsBotao` | `componentes/ds_botao.dart` | Acoes primarias, secundarias, destrutivas, contorno, ghost e acao. | Evitar botao manual para acao comum. Variantes reais: `primario`, `secundario`, `ghost`, `contorno`, `perigo`, `acao`. |
| `DsCard` | `componentes/ds_card.dart` | Superficies reutilizaveis para conteudo agrupado. | Evitar `Container` decorado manualmente quando o card DS atende. |
| `DsInput` | `componentes/ds_input.dart` | Campos textuais gerais quando nao houver Campo Cadastral especifico. | Evitar em cadastro quando existir Campo Cadastral real. |
| `DsDropdown` | `componentes/ds_dropdown.dart` | Selecoes simples com lista curta. | Evitar para listas longas; nesses casos preferir `DsSearchableDropdown`. |
| `DsSearchableDropdown` | `componentes/ds_searchable_dropdown.dart` | Selecoes longas ou pesquisaveis. | Evitar quando uma lista curta e previsivel couber em `DsDropdown`. |
| `DsMolduraIcone` | `componentes/ds_moldura_icone.dart` | Icones destacados com moldura visual consistente. | Evitar uso decorativo sem semantica; usar cor do contexto. |
| `DsBotaoVoltar` | `componentes/ds_botao_voltar.dart` | Acao de retorno consistente entre telas. | Evitar variacoes manuais de voltar em telas DS V2. |
| `DsSelo` | `componentes/ds_selo.dart` | Selos genericos de estado, categoria ou atributo. | Evitar para status de negocio quando `DsSeloStatus` atende. |
| `DsSwitch` | `componentes/ds_switch.dart` | Configuracoes booleanas. | Evitar para escolhas mutuamente exclusivas; usar texto de apoio quando necessario. |
| `DsCheckbox` | `componentes/ds_checkbox.dart` | Marcacoes independentes e confirmacoes. | Evitar para escolhas mutuamente exclusivas ou acoes imediatas sem confirmacao clara. |
| `DsAvatar` | `componentes/ds_avatar.dart` | Avatar visual de usuarios, dependentes e perfis. | Evitar cores aleatorias; integrar com `DsPaletasAvatar` quando aplicavel. |
| `DsBottomNavBar`, `DsBottomNavItem` | `componentes/ds_bottom_nav_bar.dart` | Navegacao principal inferior. | Evitar excesso de destinos; manter poucos itens e icones compreensiveis. |
| `DsAppTopHeader` | `componentes/ds_app_top_header.dart` | Cabecalho superior padronizado. | Evitar cabecalhos divergentes sem necessidade de produto. |
| `DsFeedbackBanner` | `componentes/ds_feedback_banner.dart` | Feedback persistente dentro do layout. | Evitar para mensagens descartaveis; nesses casos usar snackbar DS. |

## Dialogos, Feedback e Loading

| API | Arquivo | Uso recomendado | Evitar |
| --- | --- | --- | --- |
| `DsFeedback.showSnackBar` | `componentes/ds_feedback_banner.dart` | Feedback curto e temporario de sucesso, erro, alerta ou informacao. | `SnackBar` cru quando a tela ja usa DS V2. |
| `DsFeedbackTipo` | `componentes/ds_feedback_banner.dart` | Tipos reais encontrados: `sucesso`, `erro`, `alerta`, `info`. | Tipos ad hoc fora do enum. |
| `DsStatusDialog.show` | `componentes/ds_status_dialog.dart` | Dialogo estruturado para status, mensagens de revisao e observacoes relevantes. | `AlertDialog` manual para status de negocio padronizado. |
| `DsDialog.show<T>` | `componentes/ds_dialog.dart` | Confirmacoes, decisoes e dialogos genericos com acoes tipadas. | Criar dialogos divergentes sem necessidade. |
| `DsDialogAction<T>` | `componentes/ds_dialog.dart` | Acoes de dialogo com retorno tipado. | Botoes manuais que nao seguem o DS. |
| `DsLoadingSpinner` | `componentes/ds_loading_spinner.dart` | Loading local, listas e areas parciais. | `CircularProgressIndicator` cru quando DS spinner atende. |
| `DsLoadingOverlay` | `componentes/ds_loading_overlay.dart` | Bloqueio visual durante operacao sensivel ou tela inteira. | Overlay manual com opacidade e spinner soltos. |

Os arquivos de dialogo, feedback e loading existem em `lib/core/design_system_v2/componentes`. Nao ha subpastas `dialogs`, `feedback` ou `loading` no DS V2 atual.

## Padroes

| Padrao | Arquivo | Uso recomendado | Quando evitar / observacoes |
| --- | --- | --- | --- |
| `DsCardHub` | `padroes/ds_card_hub.dart` | Cards de entrada para areas, atalhos e hubs. | Evitar para conteudo longo; usa `DsCardHubLayout`. |
| `DsSeloStatus` | `padroes/ds_selo_status.dart` | Status de carteirinha, cadastro, aprovacao e revisao. | Evitar selos manuais de status quando houver token equivalente. |
| `DsSeloCargo` | `padroes/ds_selo_cargo.dart` | Identificacao visual de cargo/perfil. | Evitar quando a semantica nao for cargo, permissao ou perfil. |
| `DsCardNotificacao` | `padroes/ds_card_notificacao.dart` | Notificacoes em lista ou resumo. | Evitar para conteudo puramente estatico sem natureza de notificacao. |
| `DsMembrosCarrossel`, `DsMembroCarrosselItem` | `padroes/ds_membros_carrossel.dart` | Carrossel de membros/dependentes. | Evitar conteudo extenso; manter leitura mobile curta. |
| `DsMiniCarteiraPreview` | `padroes/ds_mini_carteira_preview.dart` | Previa compacta da carteirinha. | Evitar quando a tela precisa da carteirinha completa. |
| `DsCardFiltroContador` | `padroes/ds_card_filtro_contador.dart` | Filtros com contador e estado visual. | Evitar quando nao ha contagem, filtro ou estado selecionavel. |

## Campos Cadastrais

Campos Cadastrais nao sao um pacote visual generico, mas fazem parte do ecossistema de UI padronizada para formularios. Em telas de cadastro, perfil, dependente e revisao de dados, preferir estes campos antes de montar `DsInput` ou `TextField` manual.

| Area | APIs reais |
| --- | --- |
| Barrel | `lib/core/campos_cadastrais/campos_cadastrais.dart` |
| Opcoes | `OpcoesCadastrais` |
| Formatacao | `FormatadoresCadastrais` |
| Validacao | `ValidadoresCadastrais` |
| Dados pessoais | `CampoNomeCompleto`, `CampoNomeSocial`, `CampoCpf`, `CampoEmail`, `CampoTelefone`, `CampoDataNascimento` |
| Dados protegidos | `CampoCpfProtegido`, `CampoEmailProtegido`, `CampoCidProtegido`, `CampoDadoProtegidoToggle` |
| Instituicao e saude | `CampoNomeInstituicao`, `CampoCid`, `CampoTipoSanguineo`, `CampoIndicacaoInstituicao` |
| Responsaveis e emergencia | `CampoNomeResponsavel`, `CampoTelefoneResponsavel`, `CampoNomeContatoEmergencia`, `CampoTelefoneContatoEmergencia` |
| Classificacao e endereco | `CampoGenero`, `CampoRacaCor`, `CampoEstado`, `CampoCidade` |

Regras praticas:

- Usar Campo Cadastral quando existir um campo especifico para o dado solicitado.
- Usar as variantes protegidas quando o dado exigir mascara, privacidade ou revelacao controlada.
- Usar `FormatadoresCadastrais` e `ValidadoresCadastrais` para manter comportamento uniforme.
- Evitar copiar validacao, mascara ou listas de opcoes diretamente dentro da tela.

## Regras de Uso em Telas

1. Importe pelo barrel `package:.../core/design_system_v2/design_system_v2.dart` quando possivel.
2. Para formularios cadastrais, importe pelo barrel de Campos Cadastrais quando houver campo pronto.
3. Antes de criar componente novo, verificar se `componentes/` ou `padroes/` ja cobrem a necessidade.
4. Para feedback temporario, usar `DsFeedback.showSnackBar`.
5. Para feedback persistente no layout, usar `DsFeedbackBanner`.
6. Para loading local, usar `DsLoadingSpinner`; para bloqueio de operacao, usar `DsLoadingOverlay`.
7. Para status de negocio, usar `DsTokenStatus`, `DsSeloStatus` ou `DsStatusDialog`.
8. Para cards de navegacao/hub, usar `DsCardHub`.
9. Para inputs cadastrais, usar Campos Cadastrais antes de `DsInput`.
10. Ao encontrar uso legado, registrar como gap se a tarefa nao autorizar refatoracao.
11. Botoes principais de confirmacao, salvar, continuar, aprovar ou concluir intencao positiva nao devem usar roxo. Devem usar o padrao Dark Glass com intencao semantica positiva/confirmar/sucesso, normalmente verde. Roxo nao e CTA generico de confirmacao.
    - O roxo (`DsCores.adminGradient` no `DsBotaoVariante.primario` com token de admin) so pode ser usado se houver intencao visual especifica justificada pela DS (ex: area administrativa ou acao de destaque premium), nunca por padrao em acoes positivas comuns.
    - `DsBotaoVariante.primario` nao representa roxo/admin por padrao. Se nenhum token for informado (ou for nulo), ele assume o token de carteirinha (azul-claro) e renderiza no estilo Dark Glass. Ele so exibira o gradiente roxo administrativo se receber explicitamente o token `DsCores.admin`.
    - Todo botao principal deve declarar intencao semantica quando a acao tiver significado claro.
    - Confirmar, salvar, continuar, aprovar e concluir intencao positiva devem usar token de sucesso/confirmar/positivo (ex: `DsCores.sucesso`).
    - A semantica do botao deve bater com texto, icone e intencao.
    - Em caso de duvida, usar Dark Glass neutro com acento semantico do token correspondente, nao cor decorativa.

## Gaps Conhecidos

- Ainda existem telas usando padroes legados como `AppBackground`, `AppColors` e componentes Premium/V1.
- Ainda ha usos manuais de `Container`, `AlertDialog`, `SnackBar`, `CircularProgressIndicator`, `TextField` e `InputDecoration` em areas antigas.
- O DS V2 convive com codigo historico; este documento nao exige migracao imediata.
- Dialogos, feedback e loading estao em `componentes/`, nao em subpastas separadas.
- `DsTokensVisuais` nao existe no codigo atual.
- A documentacao antiga de componentes premium permanece como historico separado e nao deve ser tomada como inventario completo do DS V2.

## Checklist Antes de Implementar UI

- A tela pode usar um componente ou padrao DS V2 existente?
- O dado de formulario ja possui Campo Cadastral?
- A cor usada tem token semantico?
- O estado da entidade pode usar `DsTokenStatus` ou `DsSeloStatus`?
- O feedback e temporario (`DsFeedback.showSnackBar`) ou persistente (`DsFeedbackBanner`)?
- O loading e local (`DsLoadingSpinner`) ou bloqueante (`DsLoadingOverlay`)?
- O dialogo e de status (`DsStatusDialog`) ou decisao generica (`DsDialog`)?
- A implementacao evita expor dado sensivel sem mascara ou confirmacao?
- A tela foi validada visualmente na faixa mobile esperada, especialmente 360dp a 480dp?
- A microfrente visual evita alterar backend, schema, Supabase, rotas e configuracoes?

## Historico

- **4.3 - 01/07/2026:** inventario documental alinhado ao codigo real de `design_system_v2` e `campos_cadastrais`; registro explicito de componentes, tokens, padroes, feedback, dialogos, loading e gaps atuais.
- **4.4 - 02/07/2026:** adicao de regras semanticas para uso de cores e botoes (CTA de confirmacao sem roxo, uso correto de verde/sucesso para intencao positiva).
- **4.5 - 02/07/2026:** correcao do comportamento padrao de `DsBotaoVariante.primario` para respeitar o token semantico informado (e usar token de carteirinha neutro como fallback) em vez de aplicar o roxo administrativo como default universal.
