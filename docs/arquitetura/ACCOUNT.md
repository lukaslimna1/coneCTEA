# Central do Usuário (Account) — ConeCTEA

**App:** 0.7.1-dev
**Documentação:** 4.6.0
**Status:** Desenvolvimento
**Atualizado em:** 22/05/2026

---

## 5.3 Central do Usuário (Account)
A `AccountView` foi consolidada como o hub de serviços do usuário, dividida em blocos e cards principais estruturados com visual premium Night Blue / Dark Glass.

### Central do Usuário — Estado Atual

A Central do Usuário organiza e direciona a experiência do usuário nos seguintes pilares:
1. **Meus dados:** Acesso à edição de perfil do usuário logado.
2. **Dependentes:** Listagem, visualização de detalhes, remoção e solicitação de correção de dados de dependentes.
3. **Segurança da conta:** Troca de senha e fluxo visual de exclusão de conta.
4. **Privacidade e dados:** Transparência sobre dados armazenados, finalidades de uso, consentimentos, termos de uso e política de privacidade.
5. **Institucional:** Hub de comunicação sobre a iniciativa, comunidade, projetos e rede de apoio.
6. **Suporte:** Acesso direto aos canais oficiais de acolhimento e suporte operacional.
7. **Informações do ConeCTEA:** Modal de informações do app, contendo versão, tecnologias de apoio e notas de transparência.

---

### Detalhamento dos Módulos

#### A. Privacidade e dados
A área de **Privacidade e dados** (`PrivacyView`) foi reestruturada como um hub de conformidade visual com os seguintes destinos:
*   **Dados armazenados (`StoredDataView`):** Explicação didática e detalhada de todas as categorias de dados pessoais, cadastrais, biométricos e sensíveis que o app coleta e armazena.
*   **Uso das informações (`InformationUsageView`):** Detalhamento das finalidades de uso dos dados (ex: emissão da carteirinha, comunicações e auditorias operacionais).
*   **Consentimentos e autorizações (`ConsentsView`):** Listagem de consentimentos obrigatórios (legais) e opcionais.
    *   *Nota técnica:* Os switches de consentimento e termos são puramente visuais e mantidos em estado local nesta etapa. A persistência real de preferências exige frente futura.
*   **Termos de Uso (`TermsOfUseView`):** Leitura integral dos Termos de Uso oficiais a partir do conteúdo derivado de [termos_de_uso_conectea_v1.md](../legal/termos_de_uso_conectea_v1.md). Renderização em blocos com tratamento refinado para listas e negritos.
*   **Política de Privacidade (`PrivacyPolicyView`):** Leitura integral da Política de Privacidade a partir do conteúdo derivado de [politica_de_privacidade_conectea_v1.md](../legal/politica_de_privacidade_conectea_v1.md).

#### B. Institucional
A área **Institucional** (`InstitutionalView`) atua como a vitrine social e comunitária da iniciativa:
*   **Sobre o ConeCTEA (`AboutConecteaView`):** Esclarece a finalidade do aplicativo e os limites da carteirinha.
*   **Família TEA Bauru (`FamilyTeaView`):** Apresentação da comunidade e listagem detalhada de todos os canais oficiais institucionais de contato e acolhimento.
*   **Projetos e ações (`ProjectsActionsView`):** Hub exclusivo de projetos e ações da comunidade:
    *   *Cards inclusos:* Fada do Dente, Vidas e Eventos.
    *   *Configuração visual:* Disposição em coluna única, botões em largura total e SnackBars informativos indicando ações temporárias/mockadas.
    *   *Não menciona parceiros:* Todo o conteúdo sobre parceiros e benefícios comerciais foi removido desta tela para focar estritamente em projetos e eventos comunitários.
*   **Parceiros e apoiadores (`PartnersSupportersView`):** Nova área dedicada que apresenta a rede de apoio profissional e comercial (descontos e benefícios com a carteirinha comunitária). Nesta etapa, a tela funciona como casca estática/visual premium.
*   **Importante:** Bloco de aviso que reforça que a carteirinha é de uso comunitário interno e que o app não realiza diagnóstico nem substitui serviços de saúde ou documentos civis.

#### C. Dependentes
O módulo **Dependentes** (`DependentsView`) gerencia as informações dos dependentes cadastrados:
*   **Lista de dependentes:** Apresenta os dependentes associados à conta com visualização premium.
*   **Detalhes do dependente (`DependentDetailsView`):** Visualização completa do perfil do membro.
*   **Solicitação de correção (`DependentCorrectionView`):** Formulário visual que permite solicitar correções por campo específico caso haja alguma pendência cadastral.
*   **Remoção de dependente:** Botão de remover dependente protegido por um modal de confirmação onde o usuário deve digitar "REMOVER" para habilitar a ação.
    *   *Nota técnica:* A ação final de remoção e o envio de correção são puramente visuais nesta etapa (não persistem dados no Supabase nem disparam rotinas reais de descarte).

#### D. Segurança da conta
A tela **Segurança da Conta** (`SecurityView`) foi reformulada para incluir o controle de exclusão:
*   **Exclusão de Conta:** Botão de exclusão protegido por um modal que exige que o usuário digite "EXCLUIR CONTA" para habilitar o botão final.
    *   *Nota técnica:* A ação final ainda é visual (mockada) e não realiza nenhuma mutação no `AuthService`, Supabase Auth, sessões ou tabelas de banco de dados.

---

> [!IMPORTANT]
> **Status de Desenvolvimento (Mockado/Visual):**
> Várias telas criadas nesta evolução são exclusivamente informativas e visuais. **Não houve conexão nova com o Supabase/Auth/banco de dados** para persistir as escolhas dos switches de consentimento, exclusão real de contas, remoção de dependentes ou envio real de formulários de correção. Estas ações estão mapeadas para frentes futuras específicas.
>
> **Restrições de dados sensíveis:** CPF e e-mail permanecem bloqueados para edição direta pelo usuário logado e exigem suporte administrativo institucional.
