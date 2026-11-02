#!/usr/bin/env bash
# Jalankan Claude Code dengan model gratis, tanpa menyentuh ~/.claude.
# Pakai : [PROVIDER=openrouter|llm7|groq] [MODEL=...] examples/claude-code/run.sh [argumen claude...]
#   openrouter (default) : langsung ke OpenRouter (endpoint Anthropic native)
#   llm7 | groq          : lewat proxy LiteLLM lokal (otomatis dinyalakan di 127.0.0.1:4000)
# MODEL: openrouter -> ID model OpenRouter; llm7 -> llm7-nemotron | llm7-gpt-oss; groq -> groq-gpt-oss
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROVIDER="${PROVIDER:-openrouter}"
PORT="${PORT:-4000}"

case "$PROVIDER" in
  openrouter)
    # openrouter.env: ANTHROPIC_BASE_URL=https://openrouter.ai/api, ANTHROPIC_AUTH_TOKEN=<key>, ANTHROPIC_API_KEY="" (harus kosong)
    set -a; source "$ROOT/secrets/openrouter.env"; set +a
    MODEL="${MODEL:-nvidia/nemotron-3.5-lightning:free}" ;;
  llm7|groq)
    "$ROOT/examples/claude-code/proxy-ctl.sh" start
    set -a; source "$ROOT/secrets/litellm.env"; set +a
    export ANTHROPIC_BASE_URL="http://127.0.0.1:$PORT"
    export ANTHROPIC_AUTH_TOKEN="$LITELLM_MASTER_KEY"
    export ANTHROPIC_API_KEY=""
    [ "$PROVIDER" = llm7 ] && MODEL="${MODEL:-llm7-nemotron}" || MODEL="${MODEL:-groq-gpt-oss}" ;;
  *) echo "PROVIDER tidak dikenal: $PROVIDER (openrouter|llm7|groq)" >&2; exit 2 ;;
esac

export ANTHROPIC_MODEL="$MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$MODEL"   # tugas latar ikut model gratis
export CLAUDE_CONFIG_DIR="$ROOT/.claude-home"
mkdir -p "$CLAUDE_CONFIG_DIR"

exec claude "$@"
