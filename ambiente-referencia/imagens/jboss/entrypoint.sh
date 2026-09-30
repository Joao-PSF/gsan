#!/bin/sh
# Inicia o JBoss do GSAN de referência.
# Equivale a configure_datasource + /etc/init.d/jboss start da receita oficial,
# com a configuração vinda do ambiente (.env) em vez de arquivos editados à mão.
set -eu

: "${GSAN_DB_HOST:?}" "${GSAN_DB_PORTA:?}" "${GSAN_DB_USUARIO:?}" "${GSAN_DB_SENHA:?}"
: "${GSAN_JVM_XMS:?}" "${GSAN_JVM_XMX:?}" "${GSAN_JVM_MAXPERM:?}"

DEFAULT=/opt/jboss/server/default

# A senha entra em XML e em expressão sed: só caracteres seguros.
if ! printf '%s' "$GSAN_DB_SENHA" | grep -q -E '^[A-Za-z0-9._-]+$'; then
  echo "entrypoint: GSAN_DB_SENHA deve conter só letras, dígitos, ponto, hífen ou sublinhado" >&2; exit 1
fi

if [ ! -f "$DEFAULT/deploy/gcom.ear/META-INF/application.xml" ]; then
  echo "entrypoint: EAR ausente no volume — execute 'referencia.sh build' antes" >&2; exit 1
fi

# Datasources PostgresDS e PostgresGerencialDS a partir do modelo da receita.
sed -e "s|HOST|$GSAN_DB_HOST|g" -e "s|PORT|$GSAN_DB_PORTA|g" \
    -e "s|USERNAME|$GSAN_DB_USUARIO|g" -e "s|PASSWORD|$GSAN_DB_SENHA|g" \
    /opt/gsan-referencia/postgres-ds.xml.modelo > "$DEFAULT/deploy/postgres-ds.xml"

# Limpeza que scripts/build/build_gcom.sh faz antes de cada implantação.
rm -rf "$DEFAULT/work" "$DEFAULT/tmp" "$DEFAULT/data"

# Memória da receita (via .env). O locale do servidor da receita (pt_BR.ISO-8859-1) já é o
# da imagem; as propriedades abaixo o tornam explícito na JVM. allowArraySyntax: exigência
# do JBoss 4 sob Java 6.
JAVA_OPTS="-server -Xms$GSAN_JVM_XMS -Xmx$GSAN_JVM_XMX -XX:MaxPermSize=$GSAN_JVM_MAXPERM"
JAVA_OPTS="$JAVA_OPTS -Dsun.lang.ClassLoader.allowArraySyntax=true"
JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=ISO-8859-1 -Duser.language=pt -Duser.country=BR -Duser.timezone=America/Belem"
export JAVA_OPTS

exec /opt/jboss/bin/run.sh -c default
