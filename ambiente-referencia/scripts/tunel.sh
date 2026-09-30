#!/bin/sh
# Ponto de entrada do serviço `tunel` (acesso remoto temporário à instância de INSPEÇÃO).
#
# Quick Tunnel da Cloudflare PROTEGIDO: só abre com ao menos um e-mail (ou domínio curinga) em
# CLOUDFLARED_ALLOWED_EMAILS — a Cloudflare exige autenticação por e-mail antes de repassar
# qualquer requisição. Sem e-mail válido, o túnel não abre: nunca há Quick Tunnel sem proteção.
# A origem é o proxy da própria instância, que só expõe /gsan.
set -eu

lista=$(printf '%s' "${CLOUDFLARED_ALLOWED_EMAILS:-}" | tr ',; ' '\n\n\n' | sed '/^$/d')
if [ -z "$lista" ]; then
  echo "tunel: CLOUDFLARED_ALLOWED_EMAILS vazio — o túnel não abre sem autenticação por e-mail" >&2
  exit 1
fi
args=""
for item in $lista; do
  # e-mail (nome@dominio) ou domínio curinga (*@dominio)
  printf '%s' "$item" | grep -Eq '^(\*|[A-Za-z0-9._%+-]+)@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' || {
    echo "tunel: entrada inválida em CLOUDFLARED_ALLOWED_EMAILS (esperado nome@dominio ou *@dominio)" >&2
    exit 1
  }
  args="$args --allowed-mail $item"
done

# shellcheck disable=SC2086
exec cloudflared tunnel --no-autoupdate --url http://proxy:80 $args
