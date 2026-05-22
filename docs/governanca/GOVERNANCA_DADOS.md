# Governança de Dados — ConeCTEA

**App:** 0.7.1-dev
**Documentação:** 4.6.0
**Status:** Desenvolvimento
**Atualizado em:** 22/05/2026

---

## Objetivo

Este documento descreve os pilares e as diretrizes de governança de dados na Central do Usuário do ecossistema ConeCTEA, apresentando de forma transparente como os fluxos visuais, controles de acesso e privacidade são mapeados no aplicativo móvel.

---

## Central do Usuário e governança de dados

A evolução recente da Central do Usuário trouxe uma camada aprofundada de transparência operacional, consentimento e conformidade visual com as boas práticas de proteção de dados (LGPD).

### 1. Categorização de Dados Armazenados
A tela de **Dados Armazenados** (`StoredDataView`) foi projetada para educar o usuário sobre quais informações são coletadas pelo ecossistema, separando-as em categorias claras:
*   **Dados Cadastrais:** CPF, Nome do titular, E-mail, Gênero, Cidade, Estado e Telefone.
*   **Dados dos Dependentes:** Nome completo, Data de nascimento, Gênero, Tipo sanguíneo, Foto de perfil e código de diagnóstico (CID).
*   **Documentos Comprovatórios (Sensíveis):** Fotos do documento de identificação (RG/CPF) e laudos médicos/comprovantes de diagnóstico.
*   **Dados de Uso Técnico:** logs de sessão e tokens de notificação em segundo plano (OneSignal).

### 2. Finalidade de Uso das Informações
Na tela de **Uso das Informações** (`InformationUsageView`), o aplicativo formaliza o compromisso operacional com a transparência do tratamento de dados:
*   **Validação Administrativa:** Documentos de identificação e laudos médicos são utilizados estritamente pela diretoria da Família TEA Bauru para analisar a elegibilidade do dependente e evitar cadastros falsificados ou duplicados.
*   **Emissão da Carteirinha:** Uso do nome, foto e CID do dependente exclusivamente para a renderização visual e checagem de integridade interna da Carteirinha Comunitária Digital.
*   **Comunicações Operacionais:** Uso de e-mail e telefone para suporte técnico, esclarecimento de pendências e disparos de avisos automáticos sobre as solicitações.
*   **Compromisso de Não Comercialização:** O app expressa formalmente que não vende ou aluga dados cadastrais das famílias a nenhuma entidade comercial externa.

### 3. Gestão e Controle de Consentimentos
O menu **Consentimentos e autorizações** (`ConsentsView`) atua como a interface mestre de controle do titular, estabelecendo a distinção entre tratamentos obrigatórios e preferências opcionais:
*   **Tratamentos Essenciais:** Aceite dos Termos de Uso e Política de Privacidade, necessários para o funcionamento e emissão da carteirinha digital.
*   **Preferências Opcionais:** Switches de autorização para envio de avisos de projetos, convites de reuniões institucionais e notificações sobre parcerias e convênios.

> [!WARNING]
> **Privacidade Local e Temporária:**
> Nesta etapa de desenvolvimento, os switches de consentimento e termos presentes na interface são puramente locais/visuais. **O aplicativo ainda não realiza persistência física dessas preferências no banco de dados Supabase.** O salvamento e rastreabilidade real dessas escolhas em backend pertencem ao backlog das frentes futuras.

### 4. Leitura e Aceite Técnico de Termos e Políticas
As telas internas de **Termos de Uso** e **Política de Privacidade** oferecem a visualização integral dos documentos jurídicos indexados no app.
*   **Comportamento do Botão "Entendi":** A ação de fechar ou tocar no botão "Entendi" funciona unicamente como retorno de navegação (`Navigator.pop`). Ela **não registra aceite real** nem escreve metadados no banco.
*   **Vínculo com o Fluxo de Cadastro:** O aceite legal vinculante e real permanece centralizado e tratado de forma integrada durante o fluxo inicial de cadastro e login, sem modificações nesta etapa.

### 5. Ciclo de Vida Visual de Ações Críticas (Exclusões e Remoções)
Operações que representam alta sensibilidade à governança de dados pessoais contam com travas de UI destinadas a mitigar o clique impulsivo:
*   **Correção de Dados do Dependente (`DependentCorrectionView`):** Solicitação visual estruturada por campo de edição, que permanece mockada de forma local nesta versão.
*   **Remoção de Dependente (`DependentsView`):** Exige confirmação por escrito da palavra "REMOVER" em modal de segurança. A ação ainda não remove os registros reais do banco Supabase.
*   **Exclusão de Conta (`SecurityView`):** Exige confirmação textual da frase "EXCLUIR CONTA". A chamada técnica de remoção no `AuthService` e tabelas relacionadas está desativada na UI (mockada).

---

## Pendências e Roadmap Técnico de Governança

Para as fases subsequentes de implementação, estão catalogadas as seguintes pendências técnicas obrigatórias:
1.  **Persistência Real de Consentimentos:** Implementar tabela de histórico de consentimentos (`user_consents`) no Supabase, registrando timestamp e versão das escolhas do usuário.
2.  **Fluxo Real de Exclusão de Conta:** Conectar o botão final da interface ao `AuthService.deleteUserAccount`, executando a exclusão do usuário do Supabase Auth de forma síncrona e disparando via trigger/PostgreSQL a remoção física de dados e dependentes associados, respeitando os prazos legais de auditoria.
3.  **Fluxo Real de Remoção de Dependente:** Integrar a confirmação de exclusão à remoção física lógica do dependente do banco Supabase, disparando simultaneamente a chamada ao GAS para expurgar a foto de perfil do Google Drive, mantendo a consistência do descarte operacional.
4.  **Fluxo Real de Correção de Dados Protegidos:** Encaminhar as solicitações tipográficas de correção de dependentes direto à fila de revisão administrativa para aprovação.
5.  **Integração Real de Parceiros, Eventos e Projetos:** Estruturar a exibição dinâmica de parceiros comerciais e agendas caso a funcionalidade final seja aprovada pela Família TEA Bauru.

---

## Observações

Este documento descreve o estado atual da arquitetura de governança e suas representações visuais na Central do Usuário, assegurando a transparência técnica de que as ações simuladas não geram impacto imediato na infraestrutura de dados até a implantação final de seus respectivos serviços de backend.
