#!/bin/bash
# Cria gsan_comercial e gsan_gerencial como create_gsan_databases da receita
# oficial: dono = usuário de administração, ENCODING LATIN1, locale herdado do
# cluster (pt_BR.ISO-8859-1). O tablespace `indices` NÃO é pré-criado aqui: a
# receita e o README do gsan-migracoes o criam à mão, mas a migração
# 20160118183216 também o cria — pré-criar faria a migração falhar.
set -euo pipefail

for banco in gsan_comercial gsan_gerencial; do
  existe=$(psql -X -At -d postgres -c "select count(*) from pg_database where datname = '$banco'")
  if [ "$existe" = "1" ]; then
    echo "criar-bancos: $banco já existe"
  else
    psql -X -q -v ON_ERROR_STOP=1 -d postgres \
      -c "CREATE DATABASE $banco WITH OWNER=postgres ENCODING='LATIN1' TABLESPACE=pg_default"
    echo "criar-bancos: $banco criado"
  fi
done
psql -X -At -d postgres -c "select datname, pg_encoding_to_char(encoding), datcollate, datctype from pg_database where datname like 'gsan_%' order by 1"
