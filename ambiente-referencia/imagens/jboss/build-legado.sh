#!/bin/sh
# Build do EAR do GSAN pelo build.xml original (Ant), como em
# scripts/build/build_gcom.sh e no passo install_gsan da receita oficial.
#
# Entrada: o código legado como tar na entrada padrão (git archive do commit
# fixado). Saída: o EAR explodido no volume montado em deploy/gcom.ear, e em
# /saida o log do build, os metadados e o inventário do EAR.
set -eu

: "${GSAN_TIPO:?}" "${GSAN_VERSAO:?}" "${GSAN_COMMIT_LEGADO:?}"
case "$GSAN_TIPO" in Online|Batch) ;; *) echo "GSAN_TIPO deve ser Online ou Batch" >&2; exit 1 ;; esac

TRABALHO=/tmp/gsan
DEPLOY=/opt/jboss/server/default/deploy
EAR=$DEPLOY/gcom.ear
SAIDA=/saida

rm -rf "$TRABALHO" && mkdir -p "$TRABALHO"
tar -x -C "$TRABALHO"
cd "$TRABALHO"
[ -f build.xml ] || { echo "build-legado: build.xml ausente na entrada" >&2; exit 1; }

# build.properties como o install_gsan da receita o escreve, apontando
# jboss.deploy para o JBoss desta imagem.
cat > build.properties <<EOF
jboss.home=/opt/jboss
jboss.deploy=$DEPLOY
CaminhoReports=$TRABALHO/reports
build.manifest=$TRABALHO/MANIFEST.MF
gsan.tipo=$GSAN_TIPO
gsan.versao=$GSAN_VERSAO
EOF

# O EAR anterior sai inteiro (build_gcom.sh apaga deploy/gcom*.ear). O
# diretório é ponto de montagem: esvazia-se o conteúdo.
find "$EAR" -mindepth 1 -delete
mkdir -p bin

ANT_OPTS="-Xmx1536m -XX:MaxPermSize=512m"
export ANT_OPTS
INICIO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
STATUS=0
ant -Dfile.encoding=ISO-8859-1 > "$SAIDA/build.log" 2>&1 || STATUS=$?
FIM=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tail -n 20 "$SAIDA/build.log"

{
  echo "commit_legado=$GSAN_COMMIT_LEGADO"
  echo "gsan_tipo=$GSAN_TIPO"
  echo "gsan_versao=$GSAN_VERSAO"
  echo "inicio=$INICIO"
  echo "fim=$FIM"
  echo "status_ant=$STATUS"
  echo "ant=$(ant -version 2>&1)"
  echo "java=$(java -version 2>&1 | tr '\n' ' ')"
} > "$SAIDA/build.metadados"

if [ "$STATUS" -ne 0 ]; then
  echo "build-legado: Ant terminou com status $STATUS — ver .saida/build.log" >&2
  exit "$STATUS"
fi

# Inventário do EAR (caminho + sha256), base de comparação da Fase 3.
(cd "$EAR" && find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$SAIDA/inventario-ear.sha256"
{
  echo "arquivos=$(wc -l < "$SAIDA/inventario-ear.sha256")"
  echo "jars_ejb=$(find "$EAR" -maxdepth 1 -name '*.jar' | wc -l)"
  echo "classes_war=$(find "$EAR/gcom.war/WEB-INF/classes" -name '*.class' | wc -l)"
  echo "relatorios_jasper=$(find "$EAR/gcom.war/WEB-INF/classes" -maxdepth 1 -name '*.jasper' | wc -l)"
} >> "$SAIDA/build.metadados"
cat "$SAIDA/build.metadados"
