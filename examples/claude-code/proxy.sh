#!/usr/bin/env bash
# Jalankan proxy LiteLLM di 127.0.0.1:4000 (Anthropic API -> LLM7/Groq).
# Pakai: examples/claude-code/proxy.sh          (foreground; Ctrl+C untuk berhenti)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LITELLM="$ROOT/tools/.venv/bin/litellm"
[ -x "$LITELLM" ] || { echo "LiteLLM belum terpasang. Lihat docs/HOWTO.md bagian 'Proxy LiteLLM'." >&2; exit 1; }
# Master key lokal untuk proxy (dibuat sekali, disimpan di secrets/litellm.env).
if [ ! -f "$ROOT/secrets/litellm.env" ]; then
  ( umask 077; printf 'LITELLM_MASTER_KEY=sk-%s\n' "$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')" > "$ROOT/secrets/litellm.env" )
fi
set -a
for f in litellm llm7 groq; do [ -r "$ROOT/secrets/$f.env" ] && source "$ROOT/secrets/$f.env"; done
set +a
exec "$LITELLM" --config "$ROOT/examples/claude-code/litellm.yaml" --host 127.0.0.1 --port "${PORT:-4000}"
