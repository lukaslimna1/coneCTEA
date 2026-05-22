# Histórico Técnico de Frentes — ConeCTEA

**App:** 0.7.1-dev
**Documentação:** 4.6.0
**Status:** Desenvolvimento  
**Atualizado em:** 22/05/2026

---

## Objetivo

Registrar o histórico técnico das frentes recentes do ConeCTEA, incluindo entregas concluídas, frentes intermediárias, ciclos absorvidos, hotfixes e decisões de arquitetura.

Este arquivo existe para manter rastreabilidade sem sobrecarregar o `DOCTecnico.md`.

---

## Regras de Registro

- Toda frente concluída deve ser registrada com resumo técnico.
- Frentes intermediárias, protótipos e ciclos absorvidos podem ser registrados quando realmente ocorreram.
- Não inventar frentes para preencher lacunas de numeração.
- Quando uma frente foi absorvida por outra, registrar isso claramente.
- Quando não houver registro consolidado de uma numeração intermediária, não afirmar que ela existiu.
- O `DOCTecnico.md` deve apontar para este arquivo quando precisar de histórico detalhado.

---

## | Frente | Status | Resumo técnico | Observação |
|---|---|---|---|
| 26A.1 | Concluída | Blindagem e cálculo adaptativo de `SafeArea` superior da Home para notch, furos e gota. Commit `a38ad63`. | Evita sobreposição do AppTopHeader e do Hero sem criar vãos excessivos. |
| 26A.2 | Concluída | Correção do overflow temporário de milissegundos no `PremiumBottomNavBar` (Flexible e ClipRect com ellipsis). Commit `0ad6c0a`. | Mitiga tremores e falhas de RenderFlex na barra de navegação. |
| 26A.3.1 | Concluída | Compactação de altura e responsividade interna do `QuickAccessCard` (remoção de Spacer e altura rígida). Commit `14e5e0b`. | Elimina vãos vazios sob o botão CTA em telas pequenas e médias. |
| 26A.3.2 | Concluída | Responsividade flexível em `HomeMembersSection` (minHeight: 64 e MainAxisSize.min) e ajuste fino do header clearance para `8.0`. Commit `871c8ae`. | Garante escalabilidade da lista de membros sem overflows. |
| 26A.3.3 | Concluída | Ajuste fino do carrossel pai de Acesso Rápido (altura de 168 para 148), removendo vão entre seções. Commit `6353db7`. | Conclui a harmonia vertical da Home. |
| 26A.3.4-AUD | Concluída | Auditoria técnica e visual das seções de médio risco ("Outros Serviços" e "Informações"). | Redução de riscos de layout e regressões sob os cenários testados. |
| 25C | Concluída | Finaliza modal premium e ajustes de status da Home. Commit `c282eb7`. Novo `PremiumStatusDialog` sem ações complexas. Fluxo de "Renovação" isolado para status "Vencida". Status "Suspensa" com botão de revisão próprio. Validações: `flutter analyze` limpo, `flutter build apk --debug` ok, `git diff --check` ok. | Push concluído para `origin/main`. Fluxo de renovação validado manualmente com usuário QA interno, sem dados pessoais. |
| 23E | Concluída | Implementação do sistema oficial `ConecteaAvatar`, visual Lunar Glass, 15 paletas neon/tech e herança cromática por conta titular. | Consolidou identidade visual familiar dos avatares. |
| 24C | Concluída | Correções críticas pós-teste APK 23E: Instagram externo, CTA de retorno, upload mobile de documentos, redirect GAS no `GoogleDriveService`, limpeza automática de documentos do Drive após aprovação, logs mascarados e feedback administrative de falha de limpeza. | Fluxo mobile/emulador validado com deleção instantânea dos documentos do Drive. Chrome/Web segue com limitação futura por CORS/GAS. |
| 24D.3 | Concluída | Remoção do fluxo de confirmação por OTP. Cadastro passou a ser interno: cria conta/perfil, executa `signOut()`, exibe diálogo de sucesso e leva para `/login`. Reset de senha via Supabase preservado. | `confirm_email_page.dart`, rota `/confirm-email` e métodos OTP foram removidos. |
| 25A | Concluída | Responsividade do ecossistema Auth e bancada QA Android. `PremiumButton`, `LoginPage` e `RegisterPage` receberam proteções para telas estreitas. `tools/qa/android/` foi reorganizada com scripts oficiais Samsung, Motorola e Xiaomi. | Home ficou fora do escopo da 25A. |
| 25B.3A | Concluída | Criação/padronização do `PremiumQrButton` para acesso ao scanner em Home, Cards e Admin. | Scanner/rota preservados; o QR da carteirinha não foi confundido com botão de scanner. |
| 25B.3 | Concluída | Criação de `StatusVisualTokens` e `StatusActionButton`, centralizando cores, ícones, labels, pills e botões por status no padrão Dark Glass. | Admin, Requests, Carteirinha e pontos da Home passaram a consumir o padrão visual unificado. |
| 25B.3.x | Concluída | Ciclo de refinamento semântico dos status: auditoria de cores/ícones, previews QA temporários, aprovação de `waiting_docs` como Docs File Cyan, `suspended` como Antique Silver, labels compactas `ENVIAR DOCS` e `REVISAR`, e limpeza dos previews antes do commit. | Agrupa microfases visuais de status para evitar poluir a tabela com dezenas de entradas. |
| 25B.4 | Absorvida | Refino intermediário da antiga seção `HomeOngoingRequestSection`. Corrigiu overflow, reorganizou hierarquia e revelou redundância/status divergente entre solicitação global e membro selecionado. | A solução final foi absorvida pela 25B.5, com remoção da seção separada. |
| 25B.5 | Concluída | Home unificada em torno do Documento Digital. `HomeMembersSection` virou seletor mestre, `HomeDynamicContent` orquestra blocos dinâmicos, `HomeDigitalCardSection` concentra status, protocolo copiável, CTAs e modais contextuais. `HomeOngoingRequestSection` foi removida. | Reduziu redundância e impediu que solicitação de um membro fosse exibida junto da carteirinha de outro. |
| 25B.5-HOTFIX | Concluída | Correção de sincronização visual da carteirinha via `statusOverride` em `DigitalCardWidget`/`DigitalCardFront` e validação condicional de CPF/Data na `AddMemberPage` via `_isFieldEnabled`. | Corrigiu selo interno da carteirinha e desbloqueou fluxos de `ENVIAR DOCS`/`REVISAR` quando CPF/Data não eram alvo da revisão. |
| 26B.1 | Concluída | Refinamento estético e de legibilidade da carteirinha digital no padrão Sapphire Luxe. Commit `5876692`. | Ajustes nos widgets de frente, verso e background da carteirinha, otimizando contrastes, fontes e removendo a exibição direta de contatos (dados preservados no model). |
| 26C.1 | Concluída | Refino controlado do formulário de "Cadastrar novo dependente" com separação visual de campos. Commit `db0ccf9`. | Divisão visual de Cidade/Estado, contatos de emergência e responsável. Placeholder do tipo sanguíneo resumido para "Selecione". Sem migrações de banco. |
| 26C.2 | Concluída | Ocultação temporária e reativa da navbar premium com o teclado virtual aberto. Commit `49e6cae`. | Oculta a `PremiumBottomNavBar` quando o teclado Android está ativo via `MediaQuery.viewInsetsOf`, mitigando sobreposições em barras nativas. |
| 26B.2 | Concluída | Mitigação de overflow horizontal na seção de detalhes da carteirinha digital. Commit `e3e004f`. | Redução de textos de CTA para "VER", redimensionamento de paddings/ícones do bloco de validade e aplicação de `Expanded` e `TextOverflow.ellipsis`. |
| 26B.3-AUD | Concluída | Auditoria técnica global de responsividade da seção de detalhes da carteirinha digital em viewports de 360dp a 412dp. | Comprova estabilidade e flexibilidade elástica do layout nos cenários simulados. Sem necessidade de alterações de código Dart. |
| 26D.1 | Concluída | Refino visual da tela Pedidos / Solicitações com nova hierarquia vertical, LayoutBuilder na barra de progresso e contador Dark Glass com número branco. Commit `5b4ab6f`. | Melhora significativamente a responsividade da tela em viewports de 360dp a 438dp. |
| 26E.1 | Concluída | Refino visual da tela de Notificações, compactação de topo das telas internas e novo badge Ruby/Rose no header. Commits `b3862ca` e `bb4f7df`. | Padronizou a estrutura de topo de todas as telas internas e removeu ciano do contador do sino. |
| 26E.2 | Concluída | Humanização de textos das notificações, vínculo direto de cores/ícones ao `StatusVisualTokens` e leitura individual e reativa ao toque. Commits `8ea9d84` e `e7980d3`. | Otimizou o tom textual, corrigiu duplicidades e permitiu marcar mensagens individuais como lidas reativamente. |
| 26F | Concluída nesta etapa | Fluxo de revisão administrativa de dados e reenvio seletivo de documentos sensíveis com solicitação de exclusão no Drive. Commits: f08b4c4 (destravamento de campos, validação de documentos e limpeza visual inicial), 5c61157 (banner "Ajustes solicitados" e texto dinâmico de documentos obrigatórios) e c0d7551 (limpeza seletiva de documentos rejeitados movida para fluxo admin com refino posterior do ponto da deleção). | Atua na tentativa de exclusão seletiva de arquivos rejeitados no Drive ao solicitar reenvio administrativo, destravando dinamicamente apenas os campos/documentos alvos da revisão, sem ação necessária no momento. |
| 26G | Concluída nesta etapa | Botão "Fazer mais tarde" e descarte seguro de alterações na AddMemberPage. Commit `593ec1e` (Adiciona fazer mais tarde em solicitações). | Implementa saída segura sem envio que descarta alterações locais sob confirmação do usuário e efetua tentativa de limpeza física de uploads temporários novos da sessão atual no Drive, mantendo em observação riscos residuais. |
| 26H.1 | Concluída | Centralização de fuso horário oficial America/Sao_Paulo (UTC-3) e helper central `ConecteaDateTimeHelper` em Flutter. | Elimina a dependência de relógios locais nas notificações e exibições de prazo da Home. |
| 26H.2 | Concluída | Validade técnica da carteirinha digital no Supabase via RPC por exatamente 1 ano civil (365 dias) a partir da aprovação, vencendo em 00:00:00 do dia seguinte no fuso oficial. Sem triggers no banco. | Mantém conformidade de regras de negócio internas e declara expressamente ausência de CIPTEA governamental/Romeo Mion. |
| 26H.3 | Concluída | Prazos administrativos server-side selecionáveis (7, 15 ou 30 dias úteis operacionais) calculados via DB (`conectea_add_business_days` / `conectea_admin_deadline`), vencendo em 00:00:00 do dia seguinte no fuso oficial, com controle de privilégios `SECURITY INVOKER` e sem triggers. | Impede fraudes por adulteração de relógio do celular e exclui sábados/domingos. Feriados são limitações futuras registradas. |
| 26H.3-FIX.1A | Concluída | Refatoração do `home_status_helper.dart` para consumir o helper unificado de tempo `ConecteaDateTimeHelper.formatProjectDateShort(deadline)`. | Uniformiza e protege a interface visual da Home contra fusos e offsets desalinhados de dispositivos móveis. |
| 26H.3-COMMIT | Concluída | Commit controlado `dfd3ca4` de exatamente 4 arquivos envolvidos na centralização temporal e push bem-sucedido para branch `main` em `origin`. | Mantém repositório 100% sincronizado com branch main remoto. |
| 27A.2 | Concluída | Reorganização do Painel de Gestão em Hub modular mobile-first, criação dos ConecteaVisualTokens e do componente global ConecteaRoleBadge. Commits `1ea7d50` e `7a718d2`. | Todos os cargos administrativos visualizam o Hub, com controle de entrada em cada módulo por permissão. |
| 27B.1 | Concluída | Refinamento do módulo Usuários e Permissões com travas hierárquicas, edição limitada a e-mail/CPF (protegido) e experiência visual Dark Glass / teclado aware. Commits `5e0b4e8`, `c32d29c`, `584f557`. | Travas defensivas aplicadas somente na camada de interface (segurança de UI/UX). |
| 27C.2 | Concluída | Revisão do Supabase Realtime: otimização em Notificações, estabilização de streams na Home/Carteirinhas/RequestsView e remoção do N+1 administrativo em Gestão de Carteirinhas. Commits `5685c8c`, `f0a6234`, `e95b173`, `37f0f3e`. | Reduz conexões e vazamentos de stream, preparando a arquitetura para escala. |
| 28A | Concluída nesta etapa | Evolução da Central do Usuário — Privacidade, Segurança, Institucional e documentos legais. | Estruturação e criação das telas de dados, segurança, dependentes, suporte e hub institucional no padrão premium, inteiramente visual/estático na UI. |

### Detalhes das Frentes Recentes

#### Frente 27A.2 — Hub de Gestão/Admin e tokens visuais
**Status:** concluída
**Commits:** `1ea7d50` e `7a718d2`

##### Resumo
A Frente 27A.2 iniciou a reorganização do Painel de Gestão/Admin em formato de Hub modular mobile-first. O Hub passa a apresentar áreas administrativas como Gestão de Carteirinhas, Projetos/Programas/Eventos e Consultas com Profissionais (como módulos futuros/em breve), além de Usuários e Permissões (módulo existente restrito conforme cargo administrativo, acessível a admin_master e admin_dev) e Manutenção Técnica (módulo técnico existente restrito a admin_dev). Todos os cargos administrativos visualizam a estrutura geral do Hub, mas a entrada nos módulos é controlada por cargo/permissão. Nesta etapa, apenas Gestão de Carteirinhas permanece funcional; módulos futuros ou restritos ficam indicados como “Em breve” ou “Acesso restrito”, sem rotas ou regras novas.

Também foi criado o ConecteaVisualTokens, camada global de tokens semânticos para elements sem vínculo direto com status real. A regra definida é: quando há vínculo direto com status do fluxo, usa-se StatusVisualTokens; quando o elemento representa ação, módulo ou card sem vínculo direto com status, usa-se ConecteaVisualTokens.

Foi criado o componente global ConecteaRoleBadge, com variante compacta usada na Home e variante expandida usada no Hub de Gestão. O Hub exibe os cargos com textos curtos “ADM”, “ADM Master” e “ADM Dev”, preservando comunicação visual por ícone, cor e texto. ADM Dev usa roxo/violeta técnico, alinhado à identidade de Manutenção Técnica/dev.

---

#### Frente 27C.2 — Realtime, performance e consumo de streams

**Status:** concluída
**Tipo:** performance, arquitetura Flutter, Supabase Realtime e estabilidade operacional
**Resumo:** A frente revisou e corrigiu pontos de consumo de Realtime no ConeCTEA, reduzindo recriações desnecessárias de streams, corrigindo listener manual de notificações e removendo o N+1 administrativo da Gestão de Carteirinhas.

**Entregas principais:**
- Notificações passaram a filtrar por `user_id` diretamente no Supabase e o contador do sino passou a cancelar corretamente a `StreamSubscription`.
- Home e Carteirinhas deixaram de criar streams diretamente no `build`, usando streams estáveis no ciclo de vida do State.
- Auditoria confirmou que troca de cargo/permissão não usa Realtime em `profiles`; o cargo segue carregado por `Future getUserProfile`.
- Gestão de Carteirinhas removeu o N+1 em `getAllCardRequestsStream` com a coluna `card_requests.member_name`, backfill inicial + triggers de sincronização com `members.name`.
- RequestsView teve a stream de solicitações estabilizada fora do `build`.

**Commits relacionados:**
- `5685c8c` — Otimiza realtime de notificacoes
- `f0a6234` — Estabiliza streams da Home e Carteirinhas
- `e95b173` — Remove N+1 da gestão de carteirinhas
- `37f0f3e` — Estabiliza stream da tela de solicitacoes

**Validação funcional:**
Lucas validou notificações com múltiplos usuários, navegação rápida em Home/Carteirinhas, busca administrativa por nome, criação de nova solicitação, alteração de nome do beneficiário refletindo no admin e ausência de erros em consoles de dispositivos diferentes.

**Observação futura:**
Paginação da fila administrativa, limites operacionais e estratégias adicionais de cache/contingência ficam como planejamento futuro de escala, não como pendência crítica da Frente 27C.2.

---

## Frente 27B.1 — Usuários e Permissões no Painel de Gestão

**Status:** concluída
**Tipo:** refinamento administrativo, segurança de interface e UX mobile-first
**Commits relacionados:** `5e0b4e8`, `c32d29c`, `584f557`

A Frente 27B.1 refinou o módulo **Usuários e Permissões** dentro do Painel de Gestão/Admin, com foco em hierarquia administrativa, redução de risco operacional e melhoria visual dos fluxos sensíveis.

A primeira etapa corrigiu a exposição indevida de ações de cargo na interface. O menu de três pontos passou a respeitar a hierarquia administrativa: `admin` normal não entra no módulo; `admin_master` só pode agir sobre `user` e `admin`; `admin_master` não pode agir sobre si mesmo, sobre outros `admin_master` ou sobre `admin_dev`; `admin_dev` pode agir sobre outros cargos, mas não sobre si mesmo.

A segunda etapa limitou a edição administrativa feita pelo `admin_dev`. Como o usuário já possui a área **Dados** para atualizar informações comuns, o painel administrativo passou a permitir edição apenas de dados sensíveis vinculados à conta: **e-mail** e **CPF**. Campos como nome, telefone, cidade, estado e gênero foram removidos do diálogo administrativo.

A terceira etapa refinou a experiência visual e mobile-first do módulo. O menu de permissões passou a usar visual Night Blue/Dark Glass, com cores e ícones alinhados aos badges de cargo. A ação **Editar dados sensíveis** recebeu semântica própria de privacidade. O diálogo foi refinado com aviso de cuidado, campos limitados a e-mail e CPF, CPF protegido por padrão com botão de revelar/ocultar, inputs em Dark Glass sem azul chapado e correção de overflow ao abrir teclado em telas estreitas como A05/A06.

A frente não alterou banco de dados, Supabase, RLS, `DatabaseService`, models, AuthService, Hub de Gestão, Gestão de Carteirinhas, assets ou configurações Android/Gradle.

**Pendências futuras mapeadas:** validação real em backend/RLS, logs de auditoria para alterações administrativas, proteção contra remoção do último `admin_master`/`admin_dev`, paginação de usuários e máscaras LGPD mais amplas.

---

#### Frente 28A — Evolução da Central do Usuário — Privacidade, Segurança, Institucional e documentos legais
**Status:** concluída nesta etapa
**Tipo:** conformidade legal, transparência, segurança de UI/UX, responsividade e reestruturação institucional

##### Resumo
Esta frente realizou a estruturação, modernização e refino visual da Central do Usuário, focando em transparência de dados, conformidade legal, segurança nas ações de barreira e organização comunitária.

**Entregas principais:**
- **Privacidade e Dados:** Estruturação da tela informativa em categorias claras, com a criação das telas internas de "Dados armazenados" e "Uso das informações".
- **Switches de Consentimentos:** Implementação da tela visual de consentimentos com selos reativos locais ("Ativo" em verde soft / "Desativado" em cinza opaco). Como são focados em interface de usuário, as preferências ainda não são gravadas de forma persistente no banco.
- **Telas Legais Estáticas:** Integração e renderização semântica offline da Política de Privacidade e dos Termos de Uso. O conteúdo foi derivado literalmente dos documentos Markdown oficiais (`docs/legal/`), garantindo compatibilidade estética premium e rolagem suave sem tags cruas. Clicar em "Entendi" apenas fecha a tela e não persiste o aceite.
- **Segurança da Conta:** Reformulação da tela de segurança e implementação de um modal de barreira lógica contra cliques acidentais para exclusão de conta, exigindo a digitação literal do texto `"EXCLUIR CONTA"` para liberar o botão. A exclusão de conta real não foi acoplada ao backend nesta fase.
- **Dependentes e Correções:** Exibição da listagem visual de dependentes, tela de detalhes e solicitação visual de correção por campo. O botão de remoção de dependente foi protegido com barreira que exige a digitação da palavra `"REMOVER"`. A deleção física não está funcional nesta etapa.
- **Estrutura Institucional:** Reorganização completa do hub institucional (`InstitutionalView`) em colunas de rolagem vertical única, compatíveis com viewports estreitas de 360dp (Samsung A05/A06).
  - Cards sem botões de ação foram mantidos inteiramente estáticos e sem cliques.
  - Tela **Sobre o ConeCTEA** esclarece os limites do aplicativo e da carteirinha comunitária interna (não substitui RG, CPF, laudos ou a CIPTEA oficial, e o app não faz diagnósticos).
  - Tela **Família TEA Bauru** consolida dados históricos da comunidade organizadora e canais oficiais.
  - Separação rigorosa entre a tela **Projetos e Ações** (Fada do Dente, Vidas e Eventos, puramente visual e sem menção a parceiros comerciais) e a nova tela **Parceiros e Apoiadores** (rede de apoio comercial e benefícios locais com a carteirinha comunitária).
- **Informações do App:** O modal foi reformulado esteticamente para conter detalhes de versão/build, ambiente e uma seção dedicada às tecnologias de apoio integradas ao ecossistema.

**Pendências e Limitações Mapeadas:**
- **Home/Navbar:** A navbar premium não sofreu alterações nas rotas globais ou layouts fora da Central do Usuário.
- **Integração Real de Parceiros e Eventos:** Os botões de chamada à ação ("Participar", "Ver rotas", "Obter benefício") emitem apenas snackbars informativos locais e mockados.
- **Detalhes Reais:** Fada do Dente e Vidas ainda não contam com inscrições ou cronogramas integrados de forma reativa com o banco.
- **Persistência Real de Consentimento:** O salvamento de preferências de consentimento no banco Supabase ou armazenamento seguro local está pendente.
- **Exclusão Real de Conta:** A deleção física e desvinculação em Supabase Auth/Drive não foi ativada.
- **Remoção Real de Dependentes:** A exclusão física no banco de dependentes e descarte de laudos/RG anexos no Drive requer desenvolvimento futuro integrado de limpeza de documentos.
- **Correção Real de Dados:** O envio de solicitações de alteração de campos cadastrais ou cadastros de dependentes deve passar por homologação e fila de aprovação antes de persistir alterações automáticas.

---

## Observações de Rastreabilidade

Não preencher lacunas de numeração com suposições.

Se uma frente como `24D.1`, `24D.2`, `25B.1` ou `25B.2` não estiver registrada de forma consolidada no repositório, ela não deve ser descrita como concluída, absorvida ou prototipada sem evidência.

---

## Roadmap Técnico

### Concluído recentemente
- Frente 28A (Evolução da Central do Usuário — Privacidade, Segurança, Institucional e documentos legais);
- Frente 27C.2 (Realtime, performance e consumo de streams, otimização de notificações e admin);
- Frente 27B.1 (Usuários e Permissões no Painel de Gestão, travas hierárquicas, e-mail/CPF restrito e Dark Glass);
- Frente 27A.2 (Hub de Gestão modular, ConecteaVisualTokens e ConecteaRoleBadge global);
- Série Frente 26H (Arquitetura temporal, validade da carteirinha digital, helper de tempo, RPCs de prazo administrativo em dias úteis, refabricação de Home helper e commit dfd3ca4);
- Frente 26G (Botão "Fazer mais tarde" e descarte seguro de alterações na AddMemberPage);
- Frente 26F (Fluxo de revisão administrativa e reenvio seletivo de documentos);
- Frente 26E.2 (Humanização e Leitura individual de notificações);
- Frente 26E.1 (Refino de Notificações, compactação de topo e badge Ruby/Rose);
- Frente 26D.1 (Refino visual da tela Pedidos / Solicitações);
- Frente 26B.1 (Refinamento Sapphire Luxe da Carteirinha Digital);
- Frente 26C.1 (Ajustes no formulário de Novo Dependente);
- Frente 26C.2 (Ocultação da navbar premium com teclado Android aberto);
- Frente 26B.2 (Mitigação de overflows nos detalhes da carteirinha);
- Auditoria 26B.3-AUD (Responsividade global da seção de detalhes);
- Frente 26A (Responsividade Global, SafeAreas, NavBar, Seções da Home e Auditoria);
- Frente 25C (PremiumStatusDialog e Fluxo de Renovação);
- Frente 23E;
- Frente 24C;
- Frente 24D.3;
- Frente 25A;
- Frente 25B.3;
- Versionamento;
- Account v2.

### Próxima Direção
- Home & Experiência;
- Legibilidade Estendida;
- QA Contínuo.

### Futuro / Backlog
- Saúde;
- Push;
- Geolocalização;
- Arquitetura;
- Suporte;
- Revisão Jurídica;
- Privacidade;
- Admin;
- Conteúdo;
- BI;
- UX;
- Tema claro;
- modo offline básico.
