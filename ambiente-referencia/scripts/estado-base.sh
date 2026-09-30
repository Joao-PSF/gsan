#!/bin/bash
# Estado de partida das execuções da Fase 2 (contêiner `ferramentas`, rede interna).
#
#   estado-base.sh congelar            gsan_comercial/gsan_gerencial recém-criados → modelos *_ref
#   estado-base.sh restaurar ARQ...    bancos de trabalho recriados dos modelos + massa (ARQ, em ordem)
#   estado-base.sh massa               lista a massa efetiva registrada no banco de trabalho
#
# O JBoss tem de estar parado (baseline.sh cuida disso): DROP/CREATE DATABASE exigem o banco sem
# conexões. Os modelos ficam com IS_TEMPLATE e sem conexões permitidas — só servem de origem.
# A massa aplicada fica registrada em public.baseline_massa (arquivo + sha256), que o executor
# confere antes de executar: a massa efetiva é a declarada na variação, ou a execução não vale.
set -euo pipefail
export LC_ALL=C

BANCOS="gsan_comercial gsan_gerencial"
psql_p() { psql -X -q -v ON_ERROR_STOP=1 -d postgres "$@"; }
existe() { [ "$(psql -X -At -d postgres -c "select count(*) from pg_database where datname = '$1'")" = "1" ]; }
sem_conexoes() {
  psql -X -At -d postgres -c "select count(*) from pg_stat_activity where datname = '$1'" | grep -qx 0 \
    || { echo "estado-base: $1 tem conexões abertas — pare o JBoss (baseline.sh faz isso)" >&2; exit 1; }
}

congelar() {
  # Guarda de procedência: o modelo só nasce de banco em que ninguém entrou pela aplicação.
  acessos=$(psql -X -At -d gsan_comercial -c "select count(*) from seguranca.usuario where usur_tmultimoacesso is not null")
  if [ "$acessos" != "0" ] && [ "${1:-}" != "--aceitar-uso" ]; then
    echo "estado-base: gsan_comercial já recebeu login ($acessos usuário(s)) — não é o estado pós-migração." >&2
    echo "  Recrie com: referencia.sh recriar-banco --sim  (o modelo é congelado ao fim do passo banco)" >&2
    exit 1
  fi
  for b in $BANCOS; do
    sem_conexoes "$b"
    if existe "${b}_ref"; then
      psql_p -c "ALTER DATABASE ${b}_ref WITH IS_TEMPLATE false" -c "DROP DATABASE ${b}_ref"
    fi
    psql_p -c "CREATE DATABASE ${b}_ref TEMPLATE $b" -c "ALTER DATABASE ${b}_ref WITH IS_TEMPLATE true ALLOW_CONNECTIONS false"
    echo "estado-base: modelo ${b}_ref congelado"
  done
}

restaurar() {
  for b in $BANCOS; do
    existe "${b}_ref" || { echo "estado-base: modelo ${b}_ref ausente — rode referencia.sh recriar-banco --sim" >&2; exit 1; }
    sem_conexoes "$b"
    psql_p -c "DROP DATABASE IF EXISTS $b" -c "CREATE DATABASE $b TEMPLATE ${b}_ref"
  done
  psql -X -q -v ON_ERROR_STOP=1 -d gsan_comercial \
    -c "CREATE TABLE public.baseline_massa (ordem integer PRIMARY KEY, arquivo text NOT NULL, sha256 text NOT NULL)"
  ordem=0
  for arq in "$@"; do
    ordem=$((ordem + 1))
    psql -X -q -v ON_ERROR_STOP=1 -d gsan_comercial --single-transaction -f "$arq"
    rel=${arq#/referencia/baselines/}
    psql -X -q -v ON_ERROR_STOP=1 -d gsan_comercial \
      -c "INSERT INTO public.baseline_massa VALUES ($ordem, '$rel', '$(sha256sum "$arq" | cut -d' ' -f1)')"
  done
  avancar_sequencias "$@"
  echo "estado-base: bancos restaurados dos modelos; massa: $ordem arquivo(s)"
}

# Sequências das tabelas que a massa povoou com id explícito passam do maior id: uma inserção feita
# depois pela operação do GSAN não colide com a massa. Mesma convenção do P2 (seq_<tabela>).
avancar_sequencias() {
  [ "$#" -gt 0 ] || return 0
  grep -h -o -i -E 'INSERT INTO [a-z_]+\.[a-z_]+' "$@" | awk '{print tolower($3)}' | sort -u | while read -r tab; do
    esquema=${tab%%.*}; tabela=${tab#*.}
    psql -X -q -v ON_ERROR_STOP=1 -d gsan_comercial <<SQL
DO \$\$
DECLARE seq text; pk text; maior bigint; atual bigint;
BEGIN
  SELECT n.nspname || '.' || c.relname INTO seq FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE c.relkind = 'S' AND n.nspname = '$esquema' AND c.relname = 'seq_$tabela';
  SELECT a.attname INTO pk FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
   WHERE i.indrelid = '$tab'::regclass AND i.indisprimary AND i.indnatts = 1;
  IF seq IS NOT NULL AND pk IS NOT NULL THEN
    EXECUTE format('SELECT max(%I) FROM %s', pk, '$tab') INTO maior;
    EXECUTE format('SELECT last_value FROM %s', seq) INTO atual;
    IF maior IS NOT NULL AND maior > atual THEN
      PERFORM setval(seq, maior);
    END IF;
  END IF;
END \$\$;
SQL
  done
}

massa() { psql -X -At -d gsan_comercial -c "select format('%s %s %s', ordem, arquivo, sha256) from public.baseline_massa order by ordem"; }

case "${1:-}" in
  congelar) congelar "${2:-}" ;;
  restaurar) shift; restaurar "$@" ;;
  massa) massa ;;
  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
