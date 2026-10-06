#!/bin/bash
# Baselines da Fase 2 — captura e verificação separadas, sempre a partir do estado limpo.
#
#   baseline.sh capturar ALVO... [--repeticoes N] [--substituir]   grava golden/ (N ≥ 2, padrão 2)
#   baseline.sh verificar ALVO... [--repeticoes N]                 compara com golden/ (padrão 1)
#   baseline.sh lista [LOTE]                                        variações executáveis
#   baseline.sh congelar [--aceitar-uso]                            modelos gsan_*_ref do banco atual
#
# ALVO: CEN-XXX-NNN (todas as variações) · CEN-XXX-NNN:V1 · --lote NOME.
#
# Cada execução de cada variação: para o JBoss → recria gsan_comercial/gsan_gerencial dos modelos
# congelados ao fim de `referencia.sh banco` → aplica a massa efetiva (base + deltas da variação) →
# sobe o JBoss do zero → executa a operação pelas telas do GSAN → observa. Nada sobrevive de uma
# execução para outra: nem banco, nem sessão, nem cache estático do JBoss. Evidências em
# .saida/baselines/<execução>/ (não versionado); baselines em baselines/golden/ (versionado).
set -euo pipefail
export MSYS_NO_PATHCONV=1

AQUI=$(cd "$(dirname "$0")/.." && pwd)
cd "$AQUI"
# Sempre a instância das baselines (gsan-referencia), qualquer que seja GSAN_INSTANCIA no ambiente.
dc() { docker compose -p gsan-referencia --env-file versoes.env --env-file .env -f docker-compose.yml "$@"; }
fer() { dc --profile ferramentas run --rm -T ferramentas "$@" 2> >(grep -v -E '^ ?Container .*(Creat|Start)' >&2); }
EXEC=/referencia/baselines/ferramentas/executor.py
falhar() { echo "baseline.sh: $*" >&2; exit 1; }

expandir() {
  for a in "$@"; do
    case "$a" in
      --lote=*) fer python3 "$EXEC" lista "${a#--lote=}" ;;
      CEN-*:V*) echo "$a" ;;
      CEN-*) fer python3 "$EXEC" lista | grep "^$a:" || falhar "cenário sem definição executável: $a" ;;
      *) falhar "alvo inválido: $a" ;;
    esac
  done | tr -d '\r'
}

executar_uma() {  # cenário variação diretório-no-contêiner
  local cen=$1 var=$2 dir=$3
  dc stop gsan > /dev/null 2>&1 || true
  mapfile -t massa < <(fer python3 "$EXEC" massa "$cen" "$var" | tr -d '\r')
  fer bash /referencia/scripts/estado-base.sh restaurar "${massa[@]}" \
    || falhar "a massa de $cen $var não foi aplicada (erro do psql acima) — nenhuma execução desta variação"
  GSAN_INSTANCIA=referencia bash scripts/referencia.sh subir > "$SAIDA_HOST/subir-$cen-$var-$(basename "$dir").log" 2>&1 \
    || { tail -20 "$SAIDA_HOST/subir-$cen-$var-$(basename "$dir").log" >&2; falhar "o JBoss não subiu"; }
  fer python3 "$EXEC" executar "$cen" "$var" "$dir"
}

rodar() {
  local modo=$1; shift
  # A caracterização não recebe interação humana: nenhum túnel pode apontar para esta instância.
  if [ -n "$(dc --profile compartilhamento ps -q tunel 2> /dev/null)" ]; then
    falhar "há um túnel de acesso remoto na instância das baselines — encerre-o antes de capturar/verificar"
  fi
  local reps="" substituir="" alvos=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --repeticoes) reps=$2; shift 2 ;;
      --substituir) substituir=--substituir; shift ;;
      --lote) alvos+=("--lote=$2"); shift 2 ;;
      *) alvos+=("$1"); shift ;;
    esac
  done
  [ "${#alvos[@]}" -gt 0 ] || falhar "informe ao menos um alvo"
  # O banco precisa estar no ar antes da restauração (a instância pode ter sido parada por referencia.sh parar).
  dc up -d db > /dev/null 2>&1 || falhar "o banco da instância das baselines não subiu"
  for _ in $(seq 1 60); do dc exec -T db pg_isready -q > /dev/null 2>&1 && break; sleep 2; done
  dc exec -T db pg_isready -q > /dev/null 2>&1 || falhar "o banco da instância das baselines não respondeu"
  if [ "$modo" = capturar ]; then reps=${reps:-2}; [ "$reps" -ge 2 ] || falhar "captura exige --repeticoes ≥ 2"
  else reps=${reps:-1}; fi
  mapfile -t lista < <(expandir "${alvos[@]}")
  [ "${#lista[@]}" -gt 0 ] || falhar "nenhuma variação selecionada"

  local id; id="$(date -u +%Y%m%dT%H%M%SZ)-$modo"
  SAIDA_HOST=".saida/baselines/$id"; mkdir -p "$SAIDA_HOST"
  echo "== $modo: ${#lista[@]} variação(ões) × $reps execução(ões) — evidências em $SAIDA_HOST"
  local falhas=0
  for item in "${lista[@]}"; do
    local cen=${item%%:*} var=${item#*:} dirs=()
    for r in $(seq 1 "$reps"); do
      local dir="/saida/baselines/$id/$cen/$var/execucao-$r"
      echo "-- $cen $var: execução $r/$reps"
      executar_uma "$cen" "$var" "$dir"
      dirs+=("$dir")
    done
    fer python3 "$EXEC" consolidar "$modo" "$cen" "$var" "${dirs[@]}" $substituir \
      | tee -a "$SAIDA_HOST/consolidacao.txt" || falhas=$((falhas + 1))
  done
  echo "== $modo concluído: ${#lista[@]} variação(ões), $falhas com problema — $SAIDA_HOST/consolidacao.txt"
  [ "$falhas" -eq 0 ]
}

case "${1:-}" in
  capturar|verificar) m=$1; shift; rodar "$m" "$@" ;;
  lista) fer python3 "$EXEC" lista ${2:+"$2"} ;;
  congelar)
    dc stop gsan > /dev/null 2>&1 || true
    fer bash /referencia/scripts/estado-base.sh congelar ${2:+"$2"} ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
