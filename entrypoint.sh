#!/usr/bin/env bash
set -euo pipefail

: "${WEB_USER:?Bitte WEB_USER in RunPod setzen}"
: "${WEB_PASSWORD:?Bitte WEB_PASSWORD in RunPod setzen}"

export WEB_PASSWORD_HASH
WEB_PASSWORD_HASH="$(caddy hash-password --plaintext "$WEB_PASSWORD")"
export WEB_PASSWORD_HASH

caddy validate \
  --config /opt/Caddyfile.template \
  --adapter caddyfile

echo "Starte geschützten Web-Proxy auf 8189 und 8889..."
caddy run \
  --config /opt/Caddyfile.template \
  --adapter caddyfile \
  > /workspace/caddy.log 2>&1 &

exec /start.sh
