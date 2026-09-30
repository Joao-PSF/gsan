#!/bin/bash
# Obtém o gsan-migracoes no commit fixado em versoes.env (contêiner `obter`).
set -euo pipefail
: "${GSAN_MIGRACOES_REPO:?}" "${GSAN_MIGRACOES_COMMIT:?}"

DESTINO=/migracoes/gsan-migracoes
if [ -d "$DESTINO/.git" ] && [ "$(git -C "$DESTINO" rev-parse HEAD)" = "$GSAN_MIGRACOES_COMMIT" ]; then
  echo "obter-migracoes: $GSAN_MIGRACOES_COMMIT já presente"
  exit 0
fi

rm -rf "$DESTINO"
git init -q "$DESTINO"
git -C "$DESTINO" fetch -q --depth 1 "$GSAN_MIGRACOES_REPO" "$GSAN_MIGRACOES_COMMIT"
git -C "$DESTINO" -c advice.detachedHead=false checkout -q FETCH_HEAD
[ "$(git -C "$DESTINO" rev-parse HEAD)" = "$GSAN_MIGRACOES_COMMIT" ]
echo "obter-migracoes: $GSAN_MIGRACOES_COMMIT — comercial: $(ls "$DESTINO"/comercial/scripts/*.sql | wc -l) scripts, gerencial: $(ls "$DESTINO"/gerencial/scripts/*.sql | wc -l) scripts"
