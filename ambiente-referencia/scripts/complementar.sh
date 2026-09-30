#!/bin/bash
# Pré-requisito P6 — complemento estrutural de gsan_comercial (contêiner `ferramentas`).
#   1. exporta colunas e sequences dos dois bancos;
#   2. regenera o complemento com scripts/mapeamento.py e exige que seja idêntico ao versionado
#      em banco/complemento-comercial.sql (o arquivo é gerado, não editado à mão);
#   3. aplica o versionado numa transação, uma única vez (public.referencia_complemento);
#   4. reexporta e confere: nenhuma divergência que o P6 deveria cobrir pode continuar aberta.
set -euo pipefail
export LC_ALL=C

EXPORT=/saida/export
VERSIONADO=/referencia/banco/complemento-comercial.sql
AUTORIZADAS=/referencia/banco/complemento-tabelas.tsv
MAPEAMENTO="python3 /referencia/scripts/mapeamento.py"

exportar() {
  mkdir -p "$EXPORT"
  for banco in comercial gerencial; do
    psql -X -At -F $'\t' -d "gsan_$banco" -c "select table_schema, table_name, column_name from information_schema.columns
      where table_schema not in ('pg_catalog', 'information_schema')" > "$EXPORT/colunas-$banco.tsv"
    psql -X -At -F $'\t' -d "gsan_$banco" -c "select sequence_schema, sequence_name from information_schema.sequences" \
      > "$EXPORT/sequencias-$banco.tsv"
  done
}

HASH=$(sha256sum "$VERSIONADO" | cut -d' ' -f1)
psql -X -q -v ON_ERROR_STOP=1 -d gsan_comercial -c "CREATE TABLE IF NOT EXISTS public.referencia_complemento (
  sha256 char(64) PRIMARY KEY, arquivo varchar(255) NOT NULL, aplicado_em timestamp NOT NULL DEFAULT now())"

if [ "$(psql -X -At -d gsan_comercial -c "select count(*) from public.referencia_complemento where sha256 = '$HASH'")" = "1" ]; then
  echo "complementar: complemento $HASH já aplicado"
else
  exportar
  $MAPEAMENTO complemento /legado/src "$EXPORT" "$AUTORIZADAS" /saida/complemento-comercial.sql
  if ! cmp -s /saida/complemento-comercial.sql "$VERSIONADO"; then
    diff "$VERSIONADO" /saida/complemento-comercial.sql | head -20 >&2 || true
    echo "complementar: o complemento regenerado difere do versionado — regenere-o conscientemente" >&2
    exit 1
  fi
  {
    printf "SET client_encoding = 'UTF8';\n"
    cat "$VERSIONADO"
    printf "\nINSERT INTO public.referencia_complemento (sha256, arquivo) VALUES ('%s', 'banco/complemento-comercial.sql');\n" "$HASH"
  } | psql -X -q -v ON_ERROR_STOP=1 --single-transaction -d gsan_comercial > /dev/null
  echo "complementar: complemento $HASH aplicado"
fi

exportar
$MAPEAMENTO verificar /legado/src "$EXPORT" "$AUTORIZADAS" /saida/mapeamento.tsv
