#!/usr/bin/env bash
# Jalankan Codex CLI lewat OpenRouter dengan CODEX_HOME terpisah (tidak menyentuh ~/.codex).
# Pakai: examples/codex/run.sh [argumen codex...]   mis. examples/codex/run.sh exec "jelaskan repo ini"
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

set -a; source "$ROOT/secrets/openrouter.env"; set +a
# openrouter.env memakai nama variabel untuk Claude Code; petakan ke nama yang dipakai config.toml.
export OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-${ANTHROPIC_AUTH_TOKEN:?isi ANTHROPIC_AUTH_TOKEN atau OPENROUTER_API_KEY di secrets/openrouter.env}}"

export CODEX_HOME="$ROOT/.codex-home"
mkdir -p "$CODEX_HOME"
cp "$ROOT/examples/codex/config.toml" "$CODEX_HOME/config.toml"

exec codex "$@"
