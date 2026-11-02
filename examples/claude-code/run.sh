#!/usr/bin/env bash
# Jalankan Claude Code lewat OpenRouter dengan model gratis, tanpa menyentuh ~/.claude.
# Pakai: examples/claude-code/run.sh [argumen claude...]
#        examples/claude-code/run.sh -p "jelaskan repo ini"
# Ganti model: MODEL=google/gemma-4-31b-it:free examples/claude-code/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Berisi ANTHROPIC_BASE_URL=https://openrouter.ai/api, ANTHROPIC_AUTH_TOKEN=<key>, ANTHROPIC_API_KEY="" (harus kosong).
set -a; source "$ROOT/secrets/openrouter.env"; set +a

MODEL="${MODEL:-nvidia/nemotron-3.5-lightning:free}"
export ANTHROPIC_MODEL="$MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$MODEL"   # tugas latar (judul, ringkasan) ikut model gratis
export CLAUDE_CONFIG_DIR="$ROOT/.claude-home"
mkdir -p "$CLAUDE_CONFIG_DIR"

exec claude "$@"
