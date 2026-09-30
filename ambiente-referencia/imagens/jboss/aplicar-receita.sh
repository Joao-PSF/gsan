#!/bin/bash
# Reproduz sobre o JBoss 4.0.1SP1 extraído as alterações que a receita oficial
# faz na instalação do servidor:
#   ti/docs/scripts/install/jboss/linux.sh  -> configure_jboss4
#   ti/docs/scripts/install/gsan/linux.sh   -> install_gsan (log4j, ROOT.war)
#   jboss-libs/copiar-libs-para-jboss.sh
# Ficam de fora os passos de sistema operacional (usuário, serviço init.d,
# rc.local), que o contêiner substitui. Cada desvio está comentado.
set -euo pipefail

JBOSS=$1
TI=$2/docs/scripts
LIBS=$3
DEFAULT=$JBOSS/server/default

falhar() { echo "aplicar-receita: $*" >&2; exit 1; }

# 0. Scripts executáveis (configure_jboss4: chmod +x $_JBOSS_FOLDER/bin/*.sh) — o zip não
#    preserva o bit de execução.
chmod +x "$JBOSS"/bin/*.sh

# 1. standardjboss.xml — invoker-proxy-bindings message-driven-bean-limiteN,
#    usados pelos jboss.xml dos MDBs do GSAN. Inserção antes da marca, como na
#    receita.
ORIGEM=$DEFAULT/conf/standardjboss.xml
MARCA="Uncomment to use JMS message inflow from jmsra.rar"
[ "$(grep -c "$MARCA" "$ORIGEM")" = "1" ] || falhar "marca ausente ou repetida em standardjboss.xml"
LINHA=$(grep -n "$MARCA" "$ORIGEM" | cut -d: -f1)
{ head -n $((LINHA - 1)) "$ORIGEM"; cat "$TI/templates/jboss/standardjboss.xml"; tail -n +"$LINHA" "$ORIGEM"; } > "$ORIGEM.novo"
mv "$ORIGEM.novo" "$ORIGEM"

# 2. run.conf — JAVA_OPTS da receita (512m/1024m/512m). Em execução, o
#    entrypoint exporta JAVA_OPTS a partir do .env e este valor não é usado;
#    fica como padrão de quem rodar run.sh diretamente.
RUNCONF=$JBOSS/bin/run.conf
ANTIGA=$(sed '/^ *#/d' "$RUNCONF" | grep -E "JAVA_OPTS=" || true)
[ -n "$ANTIGA" ] || falhar "linha JAVA_OPTS não encontrada em run.conf"
[ "$(printf '%s\n' "$ANTIGA" | wc -l)" = "1" ] || falhar "mais de uma linha JAVA_OPTS em run.conf"
NOVA='   JAVA_OPTS="-server -Xms512m -Xmx1024m -XX:MaxPermSize=512m"'
awk -v antiga="$ANTIGA" -v nova="$NOVA" '$0 == antiga { print nova; next } { print }' "$RUNCONF" > "$RUNCONF.novo"
mv "$RUNCONF.novo" "$RUNCONF"

# 3. jboss-service.xml — portas de naming da receita (1099 -> 8098, 1098 -> 8099).
SERVICE=$DEFAULT/conf/jboss-service.xml
grep -q '<attribute name="Port">1099</attribute>' "$SERVICE" || falhar "porta 1099 não encontrada"
grep -q '<attribute name="RmiPort">1098</attribute>' "$SERVICE" || falhar "porta 1098 não encontrada"
sed -i 's|<attribute name="Port">1099</attribute>|<attribute name="Port">8098</attribute>|; s|<attribute name="RmiPort">1098</attribute>|<attribute name="RmiPort">8099</attribute>|' "$SERVICE"

# 4. jboss-libs — Hibernate 3 no deployer, jars web no Tomcat e DTD de
#    service-ref (o build.xml a referencia em ${jboss.home}/docs/dtd).
HIB=$DEFAULT/deploy/jboss-hibernate.deployer
WEB=$DEFAULT/deploy/jbossweb-tomcat50.sar
[ -d "$HIB" ] || falhar "jboss-hibernate.deployer ausente"
[ -d "$WEB" ] || falhar "jbossweb-tomcat50.sar ausente"
cp "$LIBS"/jboss-hibernate/*.jar "$HIB"/
cp "$LIBS"/jboss-web/*.jar "$WEB"/
rm "$HIB/cglib-full-2.0.1.jar" "$HIB/hibernate2.jar"
cp "$LIBS"/docs/dtd/* "$JBOSS/docs/dtd/"
# mondrian.war (OLAP/JPivot) é instalado como na receita: não é parte do EAR, mas o JBoss o
# implanta antes (.war antes de .ear) e, com UseJBossWebLoader=true, as bibliotecas dele entram
# no repositório unificado de classes. É dele o commons-fileupload que o verificador de EJB
# exige ao implantar os controladores (sem ele, o EAR inteiro falha) — dependência implícita
# das instalações históricas, reproduzida aqui de propósito.
cp -R "$LIBS"/mondrian.war "$DEFAULT/deploy/"
# O mondrian.war versiona credenciais de banco (usuário e senha em strings de conexão). Elas
# são neutralizadas na instalação — divergência permitida: substituir segredo. Nenhum valor é
# impresso; a conferência abaixo falha se sobrar algum.
arquivos_mondrian() {
  find "$DEFAULT/deploy/mondrian.war" -type f \( -name '*.xml' -o -name '*.properties' -o -name '*.jsp' \) -print0
}
arquivos_mondrian | xargs -0 sed -i -E 's/((jdbc)?(password|user|username)=)[^;&"<[:space:]]+/\1REMOVIDO/Ig'
# Conferência: nenhum valor diferente de REMOVIDO (sem imprimir nenhum).
restantes=$(arquivos_mondrian | xargs -0 grep -h -o -i -E '(jdbc)?(password|user|username)=[^;&"<[:space:]]+' \
  | grep -v -c -E '=REMOVIDO$' || true)
[ "$restantes" = "0" ] || falhar "credencial remanescente no mondrian.war ($restantes ocorrência(s))"
# Desvios deliberados em relação ao copiar-libs-para-jboss.sh:
#  - driver postgres 8.1 + tools.jar: substituídos pelo driver 42.2.23.jre6
#    versionado no fork (copiado no Dockerfile); tools.jar vem do JDK.
#  - scripts init.d e deploy.sh: substituídos pelo contêiner.

# 5. log4j.xml — limiar INFO no appender de arquivo (install_gsan).
LOG4J=$DEFAULT/conf/log4j.xml
N=$(grep -c '<param name="Append" value="false"/>' "$LOG4J" || true)
[ "$N" -ge 1 ] || falhar "parâmetro Append ausente em log4j.xml"
sed -i 's|<param name="Append" value="false"/>|&\n      <param name="Threshold" value="INFO" />|' "$LOG4J"

# 6. ROOT.war — página raiz redireciona para o GSAN (install_gsan). A receita
#    usa o domínio do nginx; aqui o caminho é relativo.
ROOT_INDEX=$WEB/ROOT.war/index.html
[ -f "$ROOT_INDEX" ] || falhar "ROOT.war/index.html ausente"
mv "$ROOT_INDEX" "$ROOT_INDEX.old"
printf '<html>\n  <head>\n    <meta HTTP-EQUIV="REFRESH" content="0; url=/gsan">\n  </head>\n</html>\n' > "$ROOT_INDEX"

echo "aplicar-receita: concluído"
