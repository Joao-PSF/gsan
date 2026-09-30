#!/bin/bash
# Verificação do GSAN de referência (contêiner `ferramentas`, rede interna).
# Cada verificação imprime OK, ALERTA ou FALHA; o script termina com erro se houver
# alguma FALHA. O resultado vai também para /saida/verificacao.txt.
set -uo pipefail
export LC_ALL=C

SAIDA=/saida/verificacao.txt
: > "$SAIDA"
falhas=0; alertas=0
registrar() { echo "$1 — $2" | tee -a "$SAIDA"; case $1 in FALHA) falhas=$((falhas + 1)) ;; ALERTA) alertas=$((alertas + 1)) ;; esac; }
verificar() { if [ "$1" = "$2" ]; then registrar OK "$3 ($1)"; else registrar FALHA "$3 (obtido: '$1'; esperado: '$2')"; fi; }
condicao() { if eval "$1"; then registrar OK "$2"; else registrar FALHA "$2"; fi; }
sql() { psql -X -At -d "$1" -c "$2" 2>&1; }

echo "# verificação — $(date -u '+%Y-%m-%dT%H:%M:%SZ')" | tee -a "$SAIDA"

# --- Banco ---------------------------------------------------------------------------------
for banco in comercial gerencial; do
  verificar "$(sql postgres "select pg_encoding_to_char(encoding) || '/' || datcollate from pg_database where datname = 'gsan_$banco'")" \
    "LATIN1/pt_BR.ISO-8859-1" "gsan_$banco: codificação/collation"
  esperados=$(find /migracoes/gsan-migracoes/$banco/scripts -maxdepth 1 -name '*.sql' | wc -l)
  aplicadas=$(sql gsan_$banco 'select count(*) from changelog')
  nao=$(sql gsan_$banco "select count(*) from public.referencia_nao_aplicada")
  verificar "$((aplicadas + nao))" "$esperados" "gsan_$banco: migrações aplicadas ($aplicadas) + não aplicáveis ($nao) = scripts do repositório"
done
verificar "$(sql postgres "select pg_tablespace_location(oid) from pg_tablespace where spcname = 'indices'")" "/opt/pgsql/indices" "tablespace indices"
verificar "$(sql postgres "select count(*) from pg_database where datname in ('gsan_comercial_ref', 'gsan_gerencial_ref') and datistemplate and not datallowconn")" \
  "2" "modelos congelados da Fase 2 (gsan_*_ref: só origem, sem conexão)"
verificar "$(sql gsan_comercial "select count(*) from public.referencia_complemento where sha256 = '$(sha256sum /referencia/banco/complemento-comercial.sql | cut -d' ' -f1)'")" \
  "1" "complemento estrutural P6 versionado aplicado"

# A senha do admin não pode continuar a versionada (sem imprimir nenhuma das duas).
versionada=$(grep -o -E "'[A-Za-z0-9+/=]{27,28}'" /migracoes/gsan-migracoes/comercial/scripts/20160118183239_criar_usuario.sql | tr -d "'")
atual=$(sql gsan_comercial "select usur_nmsenha from seguranca.usuario where usur_nmlogin = 'admin'")
condicao '[ -n "$versionada" ] && [ -n "$atual" ] && [ "$versionada" != "$atual" ]' "senha do admin substituída (difere da versionada)"
registrar OK "variante de companhia: $(sql gsan_comercial 'select parm_nmcontrolador from cadastro.sistema_parametros')"

# --- Mapeamento Hibernate × schema ---------------------------------------------------------------
EXPORT=/tmp/export; mkdir -p "$EXPORT"
for banco in comercial gerencial; do
  sql gsan_$banco "select table_schema || E'\t' || table_name || E'\t' || column_name from information_schema.columns
    where table_schema not in ('pg_catalog', 'information_schema')" > "$EXPORT/colunas-$banco.tsv"
  sql gsan_$banco "select sequence_schema || E'\t' || sequence_name from information_schema.sequences" > "$EXPORT/sequencias-$banco.tsv"
done
if resumo=$(python3 /referencia/scripts/mapeamento.py verificar /legado/src "$EXPORT" /referencia/banco/complemento-tabelas.tsv /saida/mapeamento.tsv); then
  registrar OK "mapeamento × schema: nenhuma divergência a complementar aberta — $(echo "$resumo" | tr '\n' ' ')"
else
  registrar FALHA "mapeamento × schema: divergência que o P6 deveria cobrir continua aberta — $(echo "$resumo" | tr '\n' ' ')"
fi

# --- Isolamento de rede ---------------------------------------------------------------------------
condicao '! curl -s -m 8 -o /dev/null https://www.gov.br' "rede interna sem saída para a internet"
verificar "$(curl -s -o /dev/null -w '%{http_code}' 'http://sso:8081/authorization?token=verificacao')" "401" "stub de SSO responde 'sem sessão'"

# --- Implantação no JBoss --------------------------------------------------------------------------
LOGJ=/jboss-log/server.log
if [ -f "$LOGJ" ]; then
  inicio=$(grep -o 'Started in [0-9a-z:]*' "$LOGJ" | tail -1)
  condicao '[ -n "$inicio" ]' "JBoss iniciado ($inicio)"
  condicao "grep -q 'deploy, ctxPath=/gsan' '$LOGJ'" "EAR implantado (contexto /gsan)"
  condicao "! grep -q 'Incomplete Deployment listing' '$LOGJ'" "sem 'Incomplete Deployment listing'"
  verificar "$(grep -c 'building session factory' "$LOGJ")" "2" "SessionFactory Hibernate construídas (comercial e gerencial)"
  registrar OK "módulos EJB implantados: $(grep -c 'EjbModule\] Deploying' "$LOGJ")"
else
  registrar FALHA "server.log ausente"
fi

# --- HTTP ------------------------------------------------------------------------------------------
B=http://gsan:8080/gsan
C=$(mktemp)
verificar "$(curl -s -o /dev/null -w '%{http_code}' "$B/")" "200" "GET /gsan/"
pagina=$(curl -s -L -c "$C" -b "$C" "$B/carregarParametrosAction.do")
condicao 'grep -q "efetuarLoginAction.do" <<< "$pagina"' "tela de login apresentada"

# Sem sessão autenticada, a tela principal não traz menu nem logoff.
anon=$(curl -s -L "$B/telaPrincipal.do")
condicao '! grep -q "efetuarLogoffAction" <<< "$anon"' "tela principal negada sem login"

login=$(curl -s -L -c "$C" -b "$C" --data-urlencode "login=admin" --data-urlencode "senha=$GSAN_ADMIN_SENHA" "$B/efetuarLoginAction.do")
printf '%s' "$login" > /saida/resposta-login.html
itens=$(grep -o 'menu=sim' <<< "$login" | wc -l)
condicao 'grep -q "efetuarLogoffAction" <<< "$login" && [ "$itens" -gt 0 ]' "login do admin: tela principal com menu ($itens itens)"

# Consulta de domínio pela pilha inteira: Struts -> gate de autorização -> Fachada -> EJB ->
# Hibernate -> PostgreSQL, sobre a massa de verificação (banco/massa-verificacao.sql).
curl -s -L -o /dev/null -c "$C" -b "$C" "$B/exibirFiltrarClienteAction.do?menu=sim"
cliente=$(curl -s -L -c "$C" -b "$C" --data-urlencode "nomeClienteFiltro=CLIENTE SINTETICO" \
  --data-urlencode "tipoPesquisa=1" --data-urlencode "indicadorUsoClienteFiltro=" "$B/filtrarClienteAction.do")
printf '%s' "$cliente" > /saida/resposta-cliente.html
condicao 'grep -q "CLIENTE SINTETICO DE VERIFICACAO" <<< "$cliente"' "consulta de domínio: Manter Cliente encontra o cliente de verificação"

# Autorização: funcionalidade sem concessão ao grupo do admin é negada pelo gate do legado.
negada=$(curl -s -L -c "$C" -b "$C" "$B/exibirConsultarClienteAction.do")
condicao 'grep -q "Acesso a funcionalidade negado" <<< "$negada"' "gate de autorização nega funcionalidade não concedida"
rm -f "$C"

echo "resultado: $falhas falha(s), $alertas alerta(s)" | tee -a "$SAIDA"
[ "$falhas" -eq 0 ]
