-- =========================================================================
-- ConeCTEA — Fila Privada de Descarte de Arquivos no Google Drive
--
-- MIGRATION: 20260623184000_create_gc_drive_files_to_delete_v1.sql
-- OBJETIVO:
--   - Criar a tabela privada private.gc_drive_files_to_delete para controle de
--     descarte assíncrono de arquivos sensíveis do Google Drive.
--   - Fornecer persistência confiável da intenção de descarte de forma que
--     workers futuros possam reprocessar falhas.
--
-- PRIVACIDADE E SEGURANÇA:
--   - A tabela reside no schema 'private', invisível para chamadas externas REST.
--   - É terminantemente proibido gravar CPF, nome, e-mail, URLs completas de documentos
--     ou o payload criptografado nesta fila. Armazena-se apenas o file_id operacional.
--   - Todos os grants padrão são revogados para PUBLIC, anon e authenticated.
-- =========================================================================

CREATE TABLE IF NOT EXISTS private.gc_drive_files_to_delete (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider text NOT NULL DEFAULT 'google_drive',
  file_id text NOT NULL,
  source_table text NOT NULL,
  source_id uuid NOT NULL,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  attempts integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 5,
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  locked_at timestamptz NULL,
  locked_by text NULL,
  processed_at timestamptz NULL,
  last_error_code text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- 1. Provedor exclusivo suportado
  CONSTRAINT chk_gc_drive_provider CHECK (provider = 'google_drive'),

  -- 2. Formato e limites do file_id do Google Drive (letras, números, hífen e underscore, tamanho de 10 a 256)
  -- Esta regex impede que URLs completas ou strings vazias sejam salvas
  CONSTRAINT chk_gc_drive_file_id CHECK (file_id ~ '^[a-zA-Z0-9_-]{10,256}$'),

  -- 3. Tabela de origem restrita ao domínio cadastral nesta camada
  CONSTRAINT chk_gc_drive_source_table CHECK (source_table = 'account_change_requests'),

  -- 4. Motivos permitidos de descarte
  CONSTRAINT chk_gc_drive_reason CHECK (reason IN (
    'request_approved',
    'request_rejected',
    'request_cancelled',
    'request_expired',
    'document_replaced'
  )),

  -- 5. Status válidos na fila
  CONSTRAINT chk_gc_drive_status CHECK (status IN ('pending', 'processing', 'processed', 'failed')),

  -- 6. Tentativas não negativas
  CONSTRAINT chk_gc_drive_attempts CHECK (attempts >= 0),

  -- 7. Limite inferior e superior para tentativas máximas permitidas
  CONSTRAINT chk_gc_drive_max_attempts CHECK (max_attempts BETWEEN 1 AND 10),

  -- 8. Assegura que tentativas não ultrapassam o máximo configurado
  CONSTRAINT chk_gc_drive_attempts_limit CHECK (attempts <= max_attempts),

  -- 9 e 10. Coerência dos campos de lock com o estado de processamento
  CONSTRAINT chk_gc_drive_processing_lock CHECK (
    (status = 'processing' AND locked_at IS NOT NULL AND locked_by IS NOT NULL) OR
    (status <> 'processing' AND locked_at IS NULL AND locked_by IS NULL)
  ),

  -- 11 e 12. Coerência do processed_at com o status de sucesso
  CONSTRAINT chk_gc_drive_processed_time CHECK (
    (status = 'processed' AND processed_at IS NOT NULL) OR
    (status <> 'processed' AND processed_at IS NULL)
  ),

  -- 13. Formato do código de erro higienizado (sem dados pessoais e sem espaços)
  CONSTRAINT chk_gc_drive_last_error_code CHECK (
    last_error_code IS NULL OR 
    last_error_code ~ '^[a-zA-Z0-9_.:-]{1,80}$'
  )
);

-- ─────────────────────────────────────────────────────────────────────────
-- 2. CRIAÇÃO DE ÍNDICES OPERACIONAIS
-- ─────────────────────────────────────────────────────────────────────────

-- Índice único parcial: impede duplicar descartes ativos do mesmo arquivo para o mesmo destino
CREATE UNIQUE INDEX IF NOT EXISTS gc_drive_files_to_delete_active_uniq_idx
  ON private.gc_drive_files_to_delete (provider, file_id, source_table, source_id)
  WHERE status IN ('pending', 'processing');

-- Índice parcial de fila: otimiza a busca de tarefas pendentes agendadas pelo worker
CREATE INDEX IF NOT EXISTS gc_drive_files_to_delete_pending_idx
  ON private.gc_drive_files_to_delete (next_attempt_at, created_at)
  WHERE status = 'pending';

-- Índice de rastreabilidade: busca rápida para referenciar a origem lógica
CREATE INDEX IF NOT EXISTS gc_drive_files_to_delete_source_idx
  ON private.gc_drive_files_to_delete (source_table, source_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. SEGURANÇA E PRIVACIDADE (RLS e GRANTS)
-- ─────────────────────────────────────────────────────────────────────────

-- Ativação do Row Level Security
ALTER TABLE private.gc_drive_files_to_delete ENABLE ROW LEVEL SECURITY;

-- Revogação total de privilégios para segurança da fila
REVOKE ALL ON TABLE private.gc_drive_files_to_delete FROM PUBLIC;
REVOKE ALL ON TABLE private.gc_drive_files_to_delete FROM anon;
REVOKE ALL ON TABLE private.gc_drive_files_to_delete FROM authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. DOCUMENTAÇÃO E COMENTÁRIOS DE SEGURANÇA
-- ─────────────────────────────────────────────────────────────────────────

COMMENT ON TABLE private.gc_drive_files_to_delete IS
  'Fila privada para descarte assíncrono futuro de arquivos do Google Drive vinculados a solicitações finalizadas.';

COMMENT ON COLUMN private.gc_drive_files_to_delete.file_id IS
  'Identificador operacional sensível do arquivo no Drive. Não deve ser exposto publicamente ou gravado em logs crus.';

COMMENT ON COLUMN private.gc_drive_files_to_delete.status IS
  'Status do ciclo de vida do item de descarte na fila: pending, processing, processed ou failed.';

COMMENT ON COLUMN private.gc_drive_files_to_delete.last_error_code IS
  'Código de erro técnico curto e higienizado retornado na última tentativa. Jamais armazenar mensagens de erro brutas com dados pessoais.';

COMMENT ON COLUMN private.gc_drive_files_to_delete.updated_at IS
  'Data e hora da última modificação. O campo será atualizado explicitamente pela RPC ou worker futuro, sem trigger nesta migration.';
