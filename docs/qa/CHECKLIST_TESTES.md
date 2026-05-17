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
