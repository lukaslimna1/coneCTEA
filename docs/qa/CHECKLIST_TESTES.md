# Checklist de Testes — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Em construção  
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

## Próxima Frente: Home Responsiva (Validações Futuras)

Para a próxima frente de Home responsiva, os seguintes testes serão obrigatórios:
- **Header:** Validar blindagem contra câmera frontal, notch, gota, ilhas, furos e recortes. Auditar o uso estrito de `SafeArea`. Conteúdo abaixo não pode ser empurrado de forma quebrada.
- **Navbar:** Validar comportamento com navegação Android por gestos e navegação Android com 3 botões. O espaço disponível muda dinamicamente.
