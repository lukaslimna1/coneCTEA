# Histórico Técnico de Frentes — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento  
**Atualizado em:** 17/05/2026

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

---

## Observações de Rastreabilidade

Não preencher lacunas de numeração com suposições.

Se uma frente como `24D.1`, `24D.2`, `25B.1` ou `25B.2` não estiver registrada de forma consolidada no repositório, ela não deve ser descrita como concluída, absorvida ou prototipada sem evidência.

---

## Roadmap Técnico

### Concluído recentemente
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
