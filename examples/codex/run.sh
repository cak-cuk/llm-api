#!/usr/bin/env bash
# Jalankan Codex CLI dengan CODEX_HOME terpisah (tidak menyentuh ~/.codex).
# Pakai: [PROVIDER=openrouter|llm7] examples/codex/run.sh [argumen codex...]
#   mis. examples/codex/run.sh exec "jelaskan repo ini"
#        PROVIDER=llm7 examples/codex/run.sh exec -m nemotron-3-nano:30b "..."
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROVIDER="${PROVIDER:-openrouter}"

case "$PROVIDER" in
  openrouter)
    set -a; source "$ROOT/secrets/openrouter.env"; set +a
    # openrouter.env memakai nama variabel untuk Claude Code; petakan ke nama di config.toml.
    export OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-${ANTHROPIC_AUTH_TOKEN:?isi ANTHROPIC_AUTH_TOKEN atau OPENROUTER_API_KEY di secrets/openrouter.env}}"
    CONFIG="$ROOT/examples/codex/config.toml" ;;
  llm7)
    set -a; source "$ROOT/secrets/llm7.env"; set +a
    : "${LLM7_API_KEY:?isi LLM7_API_KEY di secrets/llm7.env}"
    CONFIG="$ROOT/examples/codex/config.llm7.toml" ;;
  *) echo "PROVIDER tidak dikenal: $PROVIDER (openrouter|llm7)" >&2; exit 2 ;;
esac

export CODEX_HOME="$ROOT/.codex-home"
mkdir -p "$CODEX_HOME"
cp "$CONFIG" "$CODEX_HOME/config.toml"

exec codex "$@"
