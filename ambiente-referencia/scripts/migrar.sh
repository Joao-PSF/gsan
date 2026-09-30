#!/bin/bash
# Aplica as migrações do gsan-migracoes a um banco, com a semântica do MyBatis
# Migrations configurado pelos environments/*.exemplo.properties do próprio
# repositório (send_full_script=true, auto_commit=false, changelog=CHANGELOG):
#   - ordem pelo ID (prefixo numérico do nome do arquivo);
#   - executa só a seção "do": o que vem antes de "-- //@UNDO";
#   - substitui ${changelog} por CHANGELOG;
#   - cada script numa sessão nova (o MyBatis 3.2 abre uma conexão por
#     script) e inteiro numa transação, com o registro em CHANGELOG
#     (ID, APPLIED_AT, DESCRIPTION) na mesma transação;
#   - para no primeiro erro; migração já registrada não é reaplicada.
#
# Desvios explícitos (detalhe e evidência em banco/README.md):
#   - codificação por arquivo (GSAN_MIGRACOES_CODIFICACAO=detectar); `latin1`
#     reproduz script_char_set=LATIN1 da receita;
#   - CREATE TABLESPACE roda fora de transação (o PostgreSQL não o aceita em
#     bloco transacional; com auto_commit=false o MyBatis falharia);
#   - pré-requisitos para base nova, na mesma transação da migração:
#       P1-P3  banco/sementes/<banco>/<ID>.sql, antes da migração <ID>
#              (papéis, sequences, linhas e colunas de referência);
#       P2     banco/sequencias-<banco>.tsv: avanço mínimo da sequence para
#              que os próximos nextval() não colidam com IDs já ocupados;
#       P4     banco/correcoes/<banco>/<ID>.sql substitui a seção "do";
#       P5     banco/nao-aplicaveis-<banco>.tsv: não executa, registra em
#              public.referencia_nao_aplicada.
#
# Uso: migrar.sh comercial|gerencial
# GSAN_MIGRAR_DIAGNOSTICO=1: registra falhas e segue (a base resultante NÃO é
# referência; serve para levantar pré-requisitos).
set -euo pipefail
export LC_ALL=C

BANCO=${1:?uso: migrar.sh comercial|gerencial}
DIR=/migracoes/gsan-migracoes/$BANCO/scripts
DB=gsan_$BANCO
MODO=${GSAN_MIGRACOES_CODIFICACAO:-detectar}
PRE=/referencia/banco
SEMENTES=$PRE/sementes/$BANCO
CORRECOES=$PRE/correcoes/$BANCO
SEQUENCIAS=$PRE/sequencias-$BANCO.tsv
NAO_APLICAVEIS=$PRE/nao-aplicaveis-$BANCO.tsv
LOG=/saida/migracoes-$BANCO.log
DIAGNOSTICO=${GSAN_MIGRAR_DIAGNOSTICO:-0}
DIAG=/saida/diagnostico-$BANCO.tsv
case "$MODO" in detectar|latin1) ;; *) echo "GSAN_MIGRACOES_CODIFICACAO inválido: $MODO" >&2; exit 1 ;; esac
[ -d "$DIR" ] || { echo "migrar: $DIR ausente — execute a obtenção das migrações" >&2; exit 1; }

psql_db() { psql -X -q -v ON_ERROR_STOP=1 -d "$DB" "$@"; }

codificacao() {
  local arq=$1
  if [ "$MODO" = latin1 ]; then echo LATIN1; return; fi
  if ! grep -q -P '[^\x00-\x7F]' "$arq"; then echo LATIN1; return; fi   # ASCII puro
  # Alguma linha que não casa com ".*" em locale UTF-8 = UTF-8 inválido. (O
  # iconv do Alpine/musl não serve: aceita sequência inválida e sai com 0.)
  if LC_ALL=C.UTF-8 grep -a -q -v -x '.*' "$arq"; then echo LATIN1; else echo UTF8; fi
}

# P2: avança a sequence @SEQ@ só o necessário para que os próximos @N@ valores
# estejam livres em @TAB@.
avancar_sequence() {
  sed -e "s|@SEQ@|$1|g" -e "s|@TAB@|$2|g" -e "s|@N@|$3|g" <<'SQL'
DO $p2$ DECLARE pk text; v bigint; m bigint; mudou boolean := false; BEGIN
  IF to_regclass('@TAB@'::cstring) IS NULL OR to_regclass('@SEQ@'::cstring) IS NULL THEN RETURN; END IF;
  SELECT a.attname INTO pk FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
   WHERE i.indrelid = '@TAB@'::regclass AND i.indisprimary;
  EXECUTE 'SELECT CASE WHEN is_called THEN last_value ELSE last_value - 1 END FROM @SEQ@' INTO v;
  LOOP
    EXECUTE format('SELECT max(%I) FROM @TAB@ WHERE %I BETWEEN $1 AND $2', pk, pk) INTO m USING v + 1, v + @N@;
    EXIT WHEN m IS NULL;
    v := m; mudou := true;
  END LOOP;
  IF mudou THEN PERFORM setval('@SEQ@', v); END IF;
END $p2$;
SQL
}

# Sem pipe com `grep -q`: sob pipefail, o SIGPIPE do produtor viraria "não listada".
nao_aplicavel() { [ -f "$NAO_APLICAVEIS" ] && awk -F'\t' -v id="$1" '!/^#/ && $1 == id { achou = 1 } END { exit !achou }' "$NAO_APLICAVEIS"; }

psql_db -c "CREATE TABLE IF NOT EXISTS public.referencia_nao_aplicada (
  id numeric(20,0) PRIMARY KEY, arquivo varchar(255) NOT NULL, classe varchar(40) NOT NULL,
  motivo text NOT NULL, registrado_em timestamp NOT NULL DEFAULT now())" 2> /dev/null

aplicados=""
if [ "$(psql_db -At -c "select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'changelog'")" = "1" ]; then
  aplicados=$(psql_db -At -c "select id from changelog")
fi
aplicados="$aplicados
$(psql_db -At -c "select id from public.referencia_nao_aplicada")"

mapfile -t arquivos < <(find "$DIR" -maxdepth 1 -name '*.sql' -printf '%f\n' | sort)
novos=0; existentes=0; ignoradas=0; falhas=0
TMP=$(mktemp)
echo "# migrar $BANCO — gsan-migracoes ${GSAN_MIGRACOES_COMMIT:-?} — modo $MODO — $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$LOG"

for arquivo in "${arquivos[@]}"; do
  nome=${arquivo%.sql}
  id=${nome%%_*}
  if grep -qx "$id" <<< "$aplicados"; then existentes=$((existentes + 1)); continue; fi

  if nao_aplicavel "$id"; then
    linha=$(grep -v '^#' "$NAO_APLICAVEIS" | awk -F'\t' -v id="$id" '$1 == id')
    classe=$(cut -f2 <<< "$linha"); motivo=$(cut -f3 <<< "$linha")
    psql_db -v id="$id" -v arq="$arquivo" -v classe="$classe" -v motivo="$motivo" <<'SQL'
INSERT INTO public.referencia_nao_aplicada (id, arquivo, classe, motivo) VALUES (:'id', :'arq', :'classe', :'motivo');
SQL
    echo "$id NAO-APLICADA $classe $arquivo" >> "$LOG"
    ignoradas=$((ignoradas + 1)); continue
  fi

  descricao=${nome#*_}; descricao=${descricao//_/ }; descricao=${descricao//\'/\'\'}
  origem="$DIR/$arquivo"; marcas=""
  if [ -f "$CORRECOES/$id.sql" ]; then origem="$CORRECOES/$id.sql"; marcas="$marcas correcao"; fi
  enc=$(codificacao "$origem")
  sed '/^--[[:space:]]*\/\/[[:space:]]*@UNDO/,$d' "$origem" | sed 's/\${changelog}/CHANGELOG/g' > "$TMP.do"

  {
    if [ -f "$SEMENTES/$id.sql" ]; then
      printf "SET client_encoding = 'UTF8';\n"; cat "$SEMENTES/$id.sql"; printf "\n;\n"
      marcas="$marcas semente"
    fi
    if [ -f "$SEQUENCIAS" ]; then
      while IFS=$'\t' read -r seq tabela; do
        case "$seq" in ''|\#*) continue ;; esac
        n=$(grep -o -i -F "${seq#*.}" "$TMP.do" | wc -l || true)
        if [ "$n" -gt 0 ]; then avancar_sequence "$seq" "$tabela" "$n"; marcas="$marcas p2:${seq#*.}"; fi
      done < "$SEQUENCIAS"
    fi
    printf "SET client_encoding = '%s';\n" "$enc"
    cat "$TMP.do"
    # public.: o script pode mudar o search_path (o dump muda). No MyBatis o
    # registro usa outra conexão e não sofre esse efeito.
    printf "\n;\nINSERT INTO public.CHANGELOG (ID, APPLIED_AT, DESCRIPTION) VALUES (%s, '%s', '%s');\n" \
      "$id" "$(date -u '+%Y-%m-%d %H:%M:%S')" "$descricao"
  } > "$TMP"

  if grep -q -i -E 'CREATE[[:space:]]+TABLESPACE' "$TMP.do"; then transacao=autocommit; opcao=""; else transacao=unica; opcao=--single-transaction; fi
  inicio=$(date +%s)
  if ! psql_db $opcao -f "$TMP" > /dev/null 2> "$TMP.erro"; then
    cat "$TMP.erro" >&2
    if [ "$DIAGNOSTICO" = 1 ]; then
      printf '%s\t%s\n' "$arquivo" "$(grep -E 'ERRO|ERROR|DETALHE|DETAIL' "$TMP.erro" | sed 's/^psql:[^ ]* //' | tr '\n' ' ' | cut -c1-400)" >> "$DIAG"
      falhas=$((falhas + 1)); continue
    fi
    echo "migrar: FALHOU em $arquivo" | tee -a "$LOG" >&2; exit 1
  fi
  echo "$id $enc $transacao$marcas $(( $(date +%s) - inicio ))s $arquivo" >> "$LOG"
  novos=$((novos + 1))
done
rm -f "$TMP" "$TMP.do" "$TMP.erro"
if [ "$DIAGNOSTICO" = 1 ]; then echo "migrar: DIAGNÓSTICO — $falhas migração(ões) falharam; lista em $DIAG"; exit 0; fi

total=$(psql_db -At -c "select count(*) from changelog")
nao=$(psql_db -At -c "select count(*) from public.referencia_nao_aplicada")
echo "migrar $BANCO: ${#arquivos[@]} scripts; $novos aplicados agora; $ignoradas não aplicáveis agora; $existentes já registrados; CHANGELOG = $total; não aplicáveis = $nao" | tee -a "$LOG"
[ $((total + nao)) = "${#arquivos[@]}" ] || { echo "migrar: CHANGELOG + não aplicáveis ($((total + nao))) difere do número de scripts (${#arquivos[@]})" >&2; exit 1; }
