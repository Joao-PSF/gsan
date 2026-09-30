-- P1 — papéis referenciados por 20230602183243 (GRANT ... TO pg_users / pg_aplic) e criados por
-- nenhuma migração. Criados sem login: só existem para as concessões aplicarem.
DO $semente$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_users') THEN CREATE ROLE pg_users NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_aplic') THEN CREATE ROLE pg_aplic NOLOGIN; END IF;
END $semente$;
