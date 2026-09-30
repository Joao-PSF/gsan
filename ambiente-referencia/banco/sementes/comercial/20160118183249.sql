-- P2 — sincronização de sequences ao fim da carga em massa (popula_*, 20160118183242-48).
-- O dump de 20160118183224 é só schema: as sequences começam em 1, e os popula_* inserem IDs
-- explícitos (funcionalidade 1-16025, operação 2-15047, tabela_coluna 1-1000112). Numa base em
-- uso, a sequence está à frente desses IDs — sem isso, o nextval() das migrações seguintes
-- colide. Os IDs que o nextval produziu em produção anos depois (funcionalidade 16108 e
-- operação 15123 em 2023, citados por 20230510162447 e 20230510162504) confirmam que as
-- sequences seguiram a partir do maior ID desta carga. Uma única vez, aqui: IDs explícitos
-- posteriores e mais altos (ex.: operação 16044) não movem a sequence, como em produção.
DO $sinc$
DECLARE
  par text[];
  pk text;
  m bigint;
BEGIN
  FOREACH par SLICE 1 IN ARRAY ARRAY[
    ['seguranca.seq_funcionalidade', 'seguranca.funcionalidade'],
    ['seguranca.seq_operacao', 'seguranca.operacao'],
    ['seguranca.seq_tabela_coluna', 'seguranca.tabela_coluna'],
    ['seguranca.seq_tabela', 'seguranca.tabela'],
    ['seguranca.seq_modulo', 'seguranca.modulo'],
    ['seguranca.seq_operacao_tipo', 'seguranca.operacao_tipo'],
    ['seguranca.seq_funcionalidade_categoria', 'seguranca.funcionalidade_categoria']]
  LOOP
    IF to_regclass(par[1]::cstring) IS NULL OR to_regclass(par[2]::cstring) IS NULL THEN CONTINUE; END IF;
    SELECT a.attname INTO pk FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
     WHERE i.indrelid = par[2]::regclass AND i.indisprimary;
    EXECUTE format('SELECT max(%I) FROM %s', pk, par[2]) INTO m;
    IF m IS NOT NULL THEN PERFORM setval(par[1], m); END IF;
  END LOOP;
END $sinc$;
