#!/bin/bash
# GSAN de referência — ponto único de operação (Fase 1).
#
#   referencia.sh preparar [--sem-cache]   .env (senhas geradas se vazias) e imagens
#   referencia.sh build      EAR pelo build.xml original, a partir do commit fixado
#   referencia.sh banco      bancos, migrações, pós-migração e modelo congelado (Fase 2)
#   referencia.sh subir      JBoss + proxy; espera o GSAN responder
#   referencia.sh verificar  verificação do ambiente
#   referencia.sh tudo [--sem-cache]       preparar, build, banco, subir, verificar
#   referencia.sh recriar-banco --sim   apaga o banco e refaz `banco` do zero
#   referencia.sh parar      para os contêineres, preserva os volumes
#   referencia.sh destruir --sim   remove contêineres e volumes (banco e EAR)
#
# Requer: git, docker com compose v2. Roda em Linux, macOS e Git Bash (Windows).
set -euo pipefail
# Git Bash converte argumentos iniciados por "/" em caminhos Windows; os
# caminhos passados ao docker são de dentro dos contêineres.
export MSYS_NO_PATHCONV=1

AQUI=$(cd "$(dirname "$0")/.." && pwd)
RAIZ=$(cd "$AQUI/.." && pwd)
cd "$AQUI"

dc() { docker compose --env-file versoes.env --env-file .env -f docker-compose.yml "$@"; }
msg() { printf '\n== %s\n' "$*"; }
falhar() { echo "referencia.sh: $*" >&2; exit 1; }
# git roda a partir da raiz (sem -C): no Git Bash, com MSYS_NO_PATHCONV, um
# caminho /c/... passado como argumento não seria convertido.
git_raiz() { (cd "$RAIZ" && git "$@"); }
carregar() { set -a; . ./versoes.env; . ./.env; set +a; }

preparar() {
  command -v docker > /dev/null || falhar "docker não encontrado"
  docker compose version > /dev/null || falhar "docker compose v2 não encontrado"
  docker info > /dev/null 2>&1 || falhar "o daemon do Docker não está em execução"
  if [ ! -f .env ]; then cp .env.exemplo .env; msg ".env criado a partir de .env.exemplo"; fi
  for var in GSAN_DB_SENHA GSAN_ADMIN_SENHA; do
    if grep -q -E "^$var=\s*$" .env; then
      # `head` fecha o pipe cedo: o SIGPIPE do `tr` é esperado.
      valor=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2> /dev/null | head -c 24 || true)
      [ "${#valor}" -eq 24 ] || falhar "não foi possível gerar $var"
      sed -i.bak -E "s|^$var=\s*$|$var=$valor|" .env && rm -f .env.bak
      msg "$var gerada no .env (não versionado)"
    fi
  done
  mkdir -p .saida
  msg "Construindo imagens"
  if [ "${1:-}" = "--sem-cache" ]; then
    # Reexecuta todos os downloads e conferências de checksum.
    dc --profile ferramentas build --no-cache --pull
  else
    dc --profile ferramentas build
  fi
}

build() {
  carregar
  git_raiz cat-file -e "$GSAN_COMMIT_LEGADO^{commit}" 2> /dev/null \
    || falhar "commit legado $GSAN_COMMIT_LEGADO ausente (clone raso?)"
  # O código do GSAN no HEAD tem de ser o do commit fixado: o que muda depois
  # dele é só documentação e este ambiente.
  if ! git_raiz diff --quiet "$GSAN_COMMIT_LEGADO" HEAD -- . \
        ':(exclude)docs' ':(exclude)MODERNIZACAO_GSAN.md' ':(exclude)ambiente-referencia'; then
    falhar "o código legado no HEAD difere de $GSAN_COMMIT_LEGADO — atualize versoes.env conscientemente"
  fi
  mkdir -p .saida
  msg "Parando o JBoss (o EAR é reconstruído no volume)"
  dc stop gsan > /dev/null 2>&1 || true
  msg "Build do EAR — commit $GSAN_COMMIT_LEGADO, tipo $GSAN_TIPO"
  git_raiz -c core.autocrlf=false archive --format=tar "$GSAN_COMMIT_LEGADO" \
    | dc --profile ferramentas run --rm -T construtor
}

banco() {
  # O JBoss de uma subida anterior não pode manter conexões com o banco que se refaz.
  dc stop gsan > /dev/null 2>&1 || true
  msg "Subindo o PostgreSQL"
  dc up -d --wait db
  msg "Obtendo as migrações"
  dc --profile ferramentas run --rm -T obter bash /referencia/scripts/obter-migracoes.sh
  msg "Criando os bancos"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/criar-bancos.sh
  msg "Migrando gsan_comercial"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/migrar.sh comercial
  msg "Migrando gsan_gerencial"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/migrar.sh gerencial
  msg "Complemento estrutural (P6)"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/complementar.sh
  msg "Pós-migração"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/pos-migracao.sh
  # Estado de partida de toda execução da Fase 2 (scripts/baseline.sh): o banco exatamente como
  # sai daqui, antes de qualquer login pela aplicação.
  msg "Congelando o modelo do banco (gsan_*_ref)"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/estado-base.sh congelar
}

subir() {
  carregar
  msg "Subindo JBoss e proxy"
  # Só conta a saída desta subida (o contêiner e o volume de log podem vir de uma anterior).
  desde=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  dc up -d --force-recreate gsan proxy
  msg "Aguardando o GSAN (até 15 min)"
  for _ in $(seq 1 180); do
    if dc logs --no-log-prefix --since "$desde" gsan 2> /dev/null | grep -q 'Started in'; then
      dc logs --no-log-prefix --since "$desde" gsan | grep 'Started in' | tail -1
      echo "GSAN de referência: http://127.0.0.1:${GSAN_PORTA_HTTP:-8080}/gsan"
      return 0
    fi
    if [ "$(docker inspect -f '{{.State.Running}}' "$(dc ps -aq gsan)" 2> /dev/null)" != "true" ]; then
      dc logs --no-log-prefix --since "$desde" gsan | tail -20 >&2
      falhar "o contêiner do JBoss terminou durante a inicialização"
    fi
    sleep 5
  done
  falhar "o JBoss não terminou de iniciar — veja 'docker compose logs gsan'"
}

verificar() {
  msg "Verificação"
  dc --profile ferramentas run --rm -T ferramentas bash /referencia/scripts/verificar.sh
}

case "${1:-}" in
  preparar) preparar "${2:-}" ;;
  build) build ;;
  banco) banco ;;
  subir) subir ;;
  verificar) verificar ;;
  tudo) preparar "${2:-}"; build; banco; subir; verificar ;;
  recriar-banco)
    [ "${2:-}" = "--sim" ] || falhar "recriar-banco apaga o banco; confirme com: referencia.sh recriar-banco --sim"
    dc rm -s -f db
    docker volume rm -f gsan-referencia_pgdata gsan-referencia_pgindices > /dev/null
    banco ;;
  parar) dc --profile ferramentas stop ;;
  destruir)
    [ "${2:-}" = "--sim" ] || falhar "destruir apaga banco e EAR; confirme com: referencia.sh destruir --sim"
    dc --profile ferramentas down -v ;;
  *) sed -n '2,16p' "$0"; exit 1 ;;
esac
