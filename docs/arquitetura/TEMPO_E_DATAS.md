# Arquitetura Temporal — ConeCTEA

**App:** 0.7.0-dev | **Documentação:** 4.4.0 | **Status:** Desenvolvimento  
**Atualizado em:** 18/05/2026

---

## 1. Política Temporal e Fuso Horário de Referência

O ecossistema **ConeCTEA** adota uma política temporal baseada na data civil oficial do local do projeto (Bauru-SP). 

* **Fuso Horário Oficial:** `America/Sao_Paulo` (UTC-3 / UTC-2 em período de horário de verão, caso ativo).
* **Fonte da Verdade (Timezone Sovereignty):** O relógio do servidor (Supabase PostgreSQL, Google Apps Script e Cloud Run) é a única e soberana fonte de verdade para cálculos de validade, expiração e prazos administrativos.
* **Segurança e Proteção contra Trapaças:** Nenhuma regra de negócio crítica baseia-se no relógio local do smartphone (`DateTime.now()` nativo do Flutter). Isso mitiga a manipulação de datas por parte do usuário (como atrasar o relógio do celular para burlar prazos ou estender validades de carteirinhas). O aplicativo Flutter apenas recebe as strings formatadas do banco e delega a renderização para helpers protegidos.

---

## 2. Validade da Carteirinha (Frente 26H.2)

A validade da carteirinha digital emitida pela associação Família TEA Bauru segue regras de negócios e governança:

* **Prazo de Validade:** Validade técnica de **1 ano civil (365 dias)** a partir da aprovação técnica pela administração.
* **Cálculo Server-Side:** Executado de forma controlada no banco de dados Supabase por meio de RPCs server-side, sem a criação de triggers ou policies nas tabelas do banco. O cálculo da janela ocorre pela função `public.conectea_digital_card_validity_window()`.
* **Virada Técnica de Expiração:** A carteirinha permanece válida até o último segundo de uso real, vencendo na virada exata para o dia civil subsequente (`00:00:00` do dia seguinte no fuso oficial), garantindo que o usuário usufrua integralmente do último dia completo de validade.
* **AVISO DE GOVERNANÇA CRÍTICO (Aviso Legal):** A carteirinha digital é um documento de identificação de caráter **estritamente interno**, para fins de controle, projetos e parcerias da associação Família TEA Bauru. Ela **NÃO possui relação legal com a Lei Romeo Mion (Lei 13.977/2020)**, **NÃO substitui a CIPTEA oficial** instituída por órgãos governamentais (estaduais ou municipais) e não atua como substituto de documentos públicos de identidade civil.

---

## 3. Prazos Administrativos de Correção (Frente 26H.3)

Quando uma solicitação necessita de ajustes ou reenvio de documentos, são aplicados prazos operacionais calculados a partir de dias úteis:

* **Dias Úteis Operacionais:** Os prazos excluem sábados e domingos.
* **Cálculo no Banco (Supabase):** Implementado através da função PostgreSQL customizada `public.conectea_add_business_days(p_start_date date, p_business_days integer)`.
* **Regras de Prazos Dinâmicos:**
  * Os prazos não são fixos por status de solicitação.
  * O administrador seleciona a quantidade de dias úteis (7, 15 ou 30 dias úteis operacionais) no fluxo da interface administrativa.
  * O banco de dados valida e calcula o prazo com base nas opções aceitas (7, 15 ou 30 dias úteis).
* **Virada Técnica de Expiração:** O prazo expira na virada exata para o dia civil subsequente (`00:00:00` do dia seguinte ao limite técnico), garantindo ao usuário a totalidade do último dia útil operacional para o reenvio das pendências.
* **Limitação Conhecida (Feriados):** O motor de cálculo de datas atual **não inclui tabelas de feriados** devido à volatilidade de calendários locais. Portanto, apenas sábados e domingos são descartados na soma de dias úteis. Esta limitação está catalogada no backlog técnico.

---

## 4. Helper Centralizado em Flutter (`ConecteaDateTimeHelper`)

Para evitar tremores, diferenças de fuso horário no render do widget e uso inseguro do relógio local, o frontend centraliza a formatação de exibição:

* **Caminho:** `lib/core/utils/conectea_date_time_helper.dart`
* **Responsabilidade:**
  * Parsear strings de data vindas em formato ISO-8601 (UTC) do banco.
  * Aplicar o offset correto de `America/Sao_Paulo` antes de converter para strings amigáveis ao usuário.
  * Fornecer formatações padronizadas de data curta (ex: `18/05/2026`) via `formatProjectDateShort(DateTime date)`.
* **Utilização:** Todas as telas críticas (Home Unificada, Detalhes da Solicitação do Administrador, Cards Administrativos) consomem o helper, reduzindo a dependência de métodos `toLocal()` desprotegidos.

---

## 5. Notificações e Agrupamento Temporal (Frente 26H.1)

O módulo de notificações armazena e expõe datas com base no fuso horário soberano do projeto. As datas de envio e o agrupamento visual de notificações lidas/não lidas respeitam o horário de Brasília, garantindo consistência cronológica mesmo que o usuário esteja viajando ou com o fuso do smartphone incorreto.

---

## 6. Privilégios e Segurança de Banco de Dados

As funções de cálculo de prazos e atualização de validades de carteirinhas operam sob rígidos padrões de segurança no Supabase:

* **Security Invoker:** Todas as RPCs e funções declaradas utilizam `SECURITY INVOKER`, garantindo que as operações sejam executadas dentro do contexto de segurança do usuário autenticado ativo.
* **Higienização de Acesso (Grants):** Os privilégios de execução pública e anônima são expressamente revogados para mitigar invocações maliciosas por agentes não logados:
   ```sql
   REVOKE EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) FROM public, anon;
   
   REVOKE EXECUTE ON FUNCTION public.conectea_project_today() FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) FROM public, anon;
   ```
   E o acesso de execução é concedido exclusivamente a perfis cadastrados e logados no aplicativo:
   ```sql
   GRANT EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) TO authenticated;
   
   GRANT EXECUTE ON FUNCTION public.conectea_project_today() TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) TO authenticated;
   ```
   Isso garante que apenas requisições originárias de sessões devidamente autenticadas do ConeCTEA possam acionar cálculos temporais.
