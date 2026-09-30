-- P1 — papel referenciado por 20170504180427 (GRANT ... TO gsan_operacional) e criado por
-- nenhuma migração. Criado sem login: só existe para a concessão aplicar.
DO $semente$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gsan_operacional') THEN
    CREATE ROLE gsan_operacional NOLOGIN;
  END IF;
END $semente$;
