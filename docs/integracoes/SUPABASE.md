# Integração com Supabase — ConeCTEA

**App:** 0.7.0-dev | **Documentação:** 4.4.0 | **Status:** Desenvolvimento  
**Atualizado em:** 18/05/2026

---

## 1. Visão Geral da Arquitetura de Banco de Dados

O **Supabase** (com motor relacional PostgreSQL) é o núcleo do ecossistema do ConeCTEA. Ele centraliza:
* **Autenticação e Cadastro de Perfis** (integração direta com Supabase Auth).
* **Gestão de Dependências de Membros** (tabelas `profiles`, `members` e `card_requests`).
* **Segurança e Isolamento por RLS** (Row Level Security).
* **Consistência Temporal e Regras de Negócio Server-Side** (validação de prazos administrativos e expiração lógica de carteirinhas via RPCs).

---

## 2. Prazos Administrativos em Dias Úteis (Frente 26H.3)

Para evitar dependências do relógio de dispositivos locais e proporcionar igualdade nas regras de prazos, os prazos administrativos de reenvio de documentos e correção de dados são gerados e validados no banco de dados.

As migrations da Frente 26H.3 **não introduziram triggers ou políticas automáticas** nas tabelas. O fluxo de prazos baseia-se em funções/RPCs que o aplicativo consome de forma controlada.

### 2.1 Função de Acréscimo de Dias Úteis (`public.conectea_add_business_days`)
Calcula a data civil futura adicionando dias úteis operacionais (segunda a sexta-feira, excluindo sábados e domingos) a partir de uma data inicial.

```sql
CREATE OR REPLACE FUNCTION public.conectea_add_business_days(
  p_start_date date,
  p_business_days integer
)
RETURNS date
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_current_date date := p_start_date;
  v_days_added integer := 0;
  v_dow integer;
END;
$$;
```
* **Controle de Entrada:** A função valida rigorosamente que o número de dias úteis (`p_business_days`) deve pertencer ao conjunto aceito pelo produto: **7, 15 ou 30 dias** úteis operacionais. Se outro valor for fornecido, a execução lança uma exceção.
* **Início do Prazo:** O cálculo da soma de dias inicia no dia subsequente à data de envio/solicitação.
* **Limitação Operacional:** Não há suporte para tabelas dinâmicas de feriados nesta etapa, de modo que feriados nacionais ou municipais são processados como dias úteis ordinários.

### 2.2 Função de Geração de Prazo (`public.conectea_admin_deadline`)
Retorna um timestamp com fuso horário `America/Sao_Paulo` convertido em UTC, representando a meia-noite (`00:00:00`) do dia civil seguinte ao término do prazo útil. Isso garante que o usuário tenha o último dia útil em sua totalidade para submeter correções.

```sql
CREATE OR REPLACE FUNCTION public.conectea_admin_deadline(
  p_business_days integer
)
RETURNS timestamptz
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT (public.conectea_add_business_days(public.conectea_project_today(), p_business_days)::timestamp AT TIME ZONE 'America/Sao_Paulo');
$$;
```

### 2.3 Função de Verificação de Expiração (`public.conectea_is_admin_deadline_expired`)
Determina se um prazo administrativo fornecido já foi expirado de acordo com a data civil atual do projeto.

```sql
CREATE OR REPLACE FUNCTION public.conectea_is_admin_deadline_expired(
  p_expires_at timestamptz
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT public.conectea_project_today() > (p_expires_at AT TIME ZONE 'America/Sao_Paulo')::date;
$$;
```

---

## 3. Validade Civil da Carteirinha (Frente 26H.2)

A validade da carteirinha digital possui caráter **estritamente lógico e interno** para controle e parcerias da associação Família TEA Bauru. Ela **não atua como CIPTEA oficial e não possui vínculos com a Lei Romeo Mion**.

O controle de expiração é executado de forma controlada através das seguintes funções de suporte:

### 3.1 Data Civil do Projeto (`public.conectea_project_today`)
Retorna o dia civil atual correspondente ao fuso oficial da associação (`America/Sao_Paulo`), abstraindo o timezone do servidor em nuvem.

```sql
CREATE OR REPLACE FUNCTION public.conectea_project_today()
RETURNS date
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date;
$$;
```

### 3.2 Janela de Validade (`public.conectea_digital_card_validity_window`)
Retorna a data de emissão (`issued_at`) e a data de expiração lógica (`valid_until`) calculadas para **1 ano** (365 dias) a partir da data de aprovação, alinhadas à meia-noite (`00:00:00`) do fuso de referência.

```sql
CREATE OR REPLACE FUNCTION public.conectea_digital_card_validity_window(
  OUT issued_at timestamptz,
  OUT valid_until timestamptz
)
LANGUAGE sql
SECURITY INVOKER
AS $$
  SELECT 
    ((now() AT TIME ZONE 'America/Sao_Paulo')::date::timestamp AT TIME ZONE 'America/Sao_Paulo') AS issued_at,
    (((now() AT TIME ZONE 'America/Sao_Paulo')::date + interval '1 year')::timestamp AT TIME ZONE 'America/Sao_Paulo') AS valid_until;
$$;
```

### 3.3 Verificação de Vencimento (`public.conectea_is_digital_card_expired`)
Avalia se a carteirinha está vencida baseando-se na data civil do projeto. A carteirinha permanece ativa e usável até o último minuto do seu último dia civil, expirando de forma consistente na virada do dia subsequente.

---

## 4. Modelo de Privilégios e Segurança de Funções

O ecossistema adota uma política rígida de controle de execução para evitar chamadas de API indevidas ou não autorizadas:

1. **Security Invoker:** Todas as funções críticas descritas operam com privilégios limitados ao perfil do chamador logado (`SECURITY INVOKER`).
2. **Revogação de Acesso Público:** Os privilégios de execução direta por conexões públicas ou anônimas são expressamente revogados:
   ```sql
   REVOKE EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) FROM public, anon;
   
   REVOKE EXECUTE ON FUNCTION public.conectea_project_today() FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() FROM public, anon;
   REVOKE EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) FROM public, anon;
   ```
3. **Execução Restrita:** O acesso de execução é concedido exclusivamente a perfis cadastrados e logados no aplicativo:
   ```sql
   GRANT EXECUTE ON FUNCTION public.conectea_add_business_days(date, integer) TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_admin_deadline(integer) TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_is_admin_deadline_expired(timestamptz) TO authenticated;
   
   GRANT EXECUTE ON FUNCTION public.conectea_project_today() TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_digital_card_validity_window() TO authenticated;
   GRANT EXECUTE ON FUNCTION public.conectea_is_digital_card_expired(timestamptz) TO authenticated;
   ```

---

## 5. Row Level Security (RLS) e Políticas de Isolamento

Todas as tabelas do Supabase possuem RLS ativado por padrão. O acesso aos dados é restrito da seguinte forma:

| Tabela | Operação | Regra RLS (Perfil Usuário Comum) | Regra RLS (Perfil Administrador) |
| :--- | :--- | :--- | :--- |
| `profiles` | SELECT / UPDATE | `auth.uid() = id` (Lê/edita própria conta). | `auth.role() = 'authenticated'` e `is_admin = true`. |
| `card_requests`| SELECT / INSERT | `auth.uid() = user_id` (Seu próprio pedido). | Permissão total de leitura e atualização de status. |
| `members` | SELECT | `auth.uid() = user_id` (Lê apenas seus dependentes).| Permissão total de leitura de dependentes aprovados. |
| `notifications`| SELECT / UPDATE | `auth.uid() = user_id` (Lê/marca próprias notificações).| Acesso total para envio de mensagens via sistema. |

---

## 6. Realtime e consumo de streams

A Frente 27C.2 revisou o uso de Supabase Realtime no app para reduzir consumo desnecessário e evitar recriações de streams durante rebuilds do Flutter.

Padrões registrados:
- Em streams por usuário, filtrar no Supabase por user_id sempre que aplicável, como em notificações.
- Streams não devem ser criadas diretamente dentro do `build` quando puderem ser estabilizadas no ciclo de vida do State.
- Listeners manuais com `.listen()` devem armazenar `StreamSubscription` e cancelar no `dispose()`.
- Fluxos administrativos globais devem evitar enriquecimento N+1 no client.
- A Gestão de Carteirinhas passou a usar `card_requests.member_name`, preenchido e sincronizado pelo banco, removendo consultas repetidas em `members` dentro da stream administrativa.

---

## 7. Limitações Técnicas e Roadmap de Integrações

* **Feriados:** Atualmente, o cálculo de dias úteis desconsidera calendários de feriados nacionais ou locais de Bauru-SP. Esse refino está catalogado no backlog.
* **Cron Jobs / PG Cron:** O Supabase PG Cron poderá ser adotado no futuro para varrer periodicamente a base de dados em busca de prazos expirados, alterando automaticamente o status do banco. Na fase atual, a verificação ocorre de forma lazy durante a leitura ou processamento de fluxos no app.
