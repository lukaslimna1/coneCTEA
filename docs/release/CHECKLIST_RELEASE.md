# Checklist de Release — ConeCTEA

**App:** 0.6.0-dev
**Documentação:** 4.4.0
**Status:** Desenvolvimento
**Atualizado em:** 22/05/2026

---

## Objetivo

Fornecer as etapas obrigatórias de verificação de conformidade e integridade que devem ser seguidas pela equipe de desenvolvimento e operação antes de gerar pacotes de distribuição e submissão na Google Play Store.

---

## Itens de Release — Central do Usuário

Com a recente evolução da Central do Usuário, novos critérios rigorosos de conformidade devem ser atestados antes do lançamento de qualquer release pública:

### 1. Validação de Textos e Telas Legais
- [ ] **Aprovação de Textos Finais:** Validar que os textos contidos em `terms_of_use_content.dart` e `privacy_policy_content.dart` correspondem exatamente às versões homologadas dos arquivos Markdown oficiais presentes em `docs/legal/`.
- [ ] **Aceite de Leitura Estática:** Confirmar que as telas internas de Termos de Uso e Política de Privacidade funcionam estritamente para consulta offline, **sem registrar** aceitação no banco ao clicar em "Entendi".
- [ ] **Fluxo de Cadastro/Login:** Quando a lógica de aceite ativo for integrada ao cadastro ou login, atestar que as chamadas de gravação de consentimento e aceite técnico no Supabase estão perfeitamente sincronizadas com o estado do banco.

### 2. Validação de Recursos Funcionais vs. Mockados
- [ ] **Consentimentos Reais:** Antes de declarar os switches de consentimento como "funcionais" em produção, testar a persistência real das preferências no banco de dados e garantir fallback seguro caso o usuário esteja sem conexão de rede.
- [ ] **Exclusão de Conta Real:** Antes de expor o fluxo de exclusão como funcional nas notas de versão, validar a chamada de eliminação total do usuário na tabela de perfis, desativação no Supabase Auth, expiração física de tokens de login e descarte de documentos associados no Google Drive.
- [ ] **Remoção Real de Dependente:** Antes de habilitar a deleção física, validar no ambiente de homologação se a exclusão remove a carteirinha correspondente, as solicitações vinculadas e as imagens associadas no Drive, respeitando a LGPD e evitando registros órfãos.

### 3. Validação de Responsividade e Dispositivos
- [ ] **Viewports de 360dp:** Realizar bateria de testes manuais em aparelhos da classe Samsung Galaxy A05/A06 (largura aproximada de 360dp) para garantir que todas as novas telas da Central do Usuário (Meus Dados, Dependentes, Segurança, Privacidade, Institucional) rolam de forma íntegra e sem RenderFlex.
- [ ] **Clearance de Teclado:** Validar que nenhum diálogo ou campo que exija entrada de teclado virtual sofra sobreposição severa que impeça o clique nos botões de ação ou submissão.

### 4. Segurança e Declaração na Google Play (Data Safety)
- [ ] **Auditoria de Data Safety:** Revisar a declaração de coleta e compartilhamento de dados no console do Google Play contra as categorias reais tratadas no código do aplicativo, certificando-se de que os dados do usuário estão protegidos de forma consistente com a documentação em `docs/governanca/GOVERNANCA_DADOS.md`.
- [ ] **Declaração de Transparência:** Confirmar que os textos públicos explicam explicitamente por que CPF, nome e fotos de documentos são coletados (exclusivamente para fins de validação cadastral da carteirinha comunitária interna) e que esses dados não são comercializados ou compartilhados com fins lucrativos.

---

## Observações

Este arquivo é um roteiro operacional de controle de qualidade e compliance legal para auditoria antes de submissões à loja.
