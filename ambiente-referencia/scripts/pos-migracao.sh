#!/bin/bash
# Passos depois das migrações, próprios deste ambiente (não existem na receita):
#   1. rotação das senhas dos papéis gsan_* criados pela migração
#      20160118183208 com senha igual ao login (achado 2; D-16). As novas senhas
#      são aleatórias e não são guardadas: nada neste ambiente usa esses papéis;
#   2. troca da senha do usuário `admin` da aplicação, semeada pela migração
#      20160118183239 e publicada na wiki do GSAN, pela de GSAN_ADMIN_SENHA —
#      no formato do legado, Base64(SHA-1(UTF-8)), gcom.util.Criptografia;
#   3. parâmetro URL_SEGURANCA apontando para o stub interno de SSO (imagens/sso);
#   4. logomarca vazia em sistema_parametros (login.jsp não aceita nulo);
#   5. variante de companhia, se GSAN_VARIANTE estiver definida;
#   6. massa sintética mínima de verificação (banco/massa-verificacao.sql).
# Nenhum segredo é escrito em log.
set -euo pipefail
: "${GSAN_ADMIN_SENHA:?}"
LOG=/saida/pos-migracao.log

psql_c() { psql -X -q -v ON_ERROR_STOP=1 -d gsan_comercial "$@"; }
aleatoria() { openssl rand -hex 16; }

echo "# pos-migracao — $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$LOG"

for papel in gsan_admin gsan_batch gsan_dba gsan_olap gsan_online; do
  if [ "$(psql_c -At -c "select count(*) from pg_roles where rolname = '$papel'")" = "1" ]; then
    psql_c -c "ALTER ROLE $papel PASSWORD '$(aleatoria)'"
    echo "papel $papel: senha rotacionada" | tee -a "$LOG"
  fi
done

HASH=$(printf '%s' "$GSAN_ADMIN_SENHA" | openssl dgst -sha1 -binary | base64)
N=$(psql_c -At -v hash="$HASH" <<'SQL'
UPDATE seguranca.usuario SET usur_nmsenha = :'hash' WHERE usur_nmlogin = 'admin' RETURNING usur_id;
SQL
)
[ -n "$N" ] || { echo "pos-migracao: usuário admin não encontrado" >&2; exit 1; }
echo "usuário admin: senha substituída pela de GSAN_ADMIN_SENHA" | tee -a "$LOG"

# URL_SEGURANCA: o FiltroSSO consulta esse serviço em toda requisição e falha sem ele. Nenhuma
# migração cria o parâmetro (em produção apontava para o SSO da companhia); aqui aponta para o
# stub interno `sso`, que responde "sem sessão SSO".
psql_c <<'SQL'
INSERT INTO seguranca.parametro (id, nome, valor)
SELECT (SELECT max(id) + 1 FROM seguranca.parametro), 'URL_SEGURANCA', 'http://sso:8081'
WHERE NOT EXISTS (SELECT 1 FROM seguranca.parametro WHERE nome = 'URL_SEGURANCA');
SQL
echo "parâmetro URL_SEGURANCA: $(psql_c -At -c "select valor from seguranca.parametro where nome = 'URL_SEGURANCA'")" | tee -a "$LOG"

# Logomarca: o seed de sistema_parametros (20160118183233) não a define e login.jsp faz
# getAttribute("logoMarca").equals("") — nulo derruba a tela de login. Numa instalação ela é
# configurada ("caminho imagem da logomarca"); "" é o caso "sem logomarca" que o JSP trata.
psql_c -c "UPDATE cadastro.sistema_parametros SET parm_nmimagemlogomarca = '' WHERE parm_nmimagemlogomarca IS NULL"
echo "logomarca: vazia (sem imagem)" | tee -a "$LOG"

if [ -n "${GSAN_VARIANTE:-}" ]; then
  [[ "$GSAN_VARIANTE" =~ ^[A-Z]+$ ]] || { echo "GSAN_VARIANTE inválida: $GSAN_VARIANTE" >&2; exit 1; }
  psql_c -c "UPDATE cadastro.sistema_parametros SET parm_nmcontrolador = '$GSAN_VARIANTE'"
fi
echo "variante de companhia (parm_nmcontrolador): $(psql_c -At -c 'select parm_nmcontrolador from cadastro.sistema_parametros')" | tee -a "$LOG"

psql_c --single-transaction -f /referencia/banco/massa-verificacao.sql
echo "massa de verificação: $(psql_c -At -c "select count(*) from cadastro.cliente where clie_nmcliente like '%SINTETICO%'") cliente(s) sintético(s)" | tee -a "$LOG"
