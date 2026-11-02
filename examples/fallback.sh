#!/usr/bin/env bash
# Jalankan satu prompt lewat Claude Code atau Codex dengan model gratis OpenRouter,
# mencoba model berikutnya bila gagal (429/404/timeout/jawaban kosong).
#
# Pakai : examples/fallback.sh <claude|codex> "prompt"
# Opsi  : MODELS="id1 id2 ..."  daftar model manual (default: temukan otomatis dari OpenRouter)
#         LLM7_MODELS="..."     model LLM7 (tier turbo, gratis) untuk codex (default nemotron-3-nano:30b);
#                               claude memakai alias llm7-nemotron lewat proxy. Butuh secrets/llm7.env
#         MAX_TRIES=5           jumlah model maksimum yang dicoba
#         TIMEOUT=180           detik per percobaan
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TOOL="${1:?Pakai: $0 <claude|codex> \"prompt\"}"; PROMPT="${2:?prompt kosong}"
case "$TOOL" in claude|codex) ;; *) echo "tool harus claude atau codex" >&2; exit 2 ;; esac
MAX_TRIES="${MAX_TRIES:-5}"; TIMEOUT="${TIMEOUT:-180}"

discover() { # model :free yang mendukung tool calling dan konteks >= 64k, konteks terbesar dulu
  curl -sS -m 20 https://openrouter.ai/api/v1/models | python3 -I -c '
import sys, json
ms = [m for m in json.load(sys.stdin)["data"]
      if m["id"].endswith(":free") and "tools" in (m.get("supported_parameters") or [])
      and (m.get("context_length") or 0) >= 65536]
ms.sort(key=lambda m: -(m.get("context_length") or 0))
print(" ".join(m["id"] for m in ms))'
}

MODELS="${MODELS:-$(discover)}"
[ -n "$MODELS" ] || { echo "Tidak ada model yang ditemukan." >&2; exit 1; }

# Kandidat berbentuk "provider|model". LLM7 dipakai codex langsung, claude lewat proxy LiteLLM.
CANDS=""
for m in $MODELS; do CANDS="$CANDS openrouter|$m"; done
if [ -r "$ROOT/secrets/llm7.env" ]; then
  if [ "$TOOL" = codex ]; then
    for m in ${LLM7_MODELS:-nemotron-3-nano:30b}; do CANDS="$CANDS llm7|$m"; done
  elif [ -x "$ROOT/tools/.venv/bin/litellm" ]; then
    CANDS="$CANDS llm7|llm7-nemotron"     # alias di examples/claude-code/litellm.yaml
  fi
fi

n=0
for cand in $CANDS; do
  provider="${cand%%|*}"; model="${cand#*|}"
  n=$((n+1)); [ "$n" -le "$MAX_TRIES" ] || break
  echo "[$n/$MAX_TRIES] $TOOL + $provider/$model ..." >&2
  if [ "$TOOL" = claude ]; then
    out="$(PROVIDER="$provider" MODEL="$model" timeout "$TIMEOUT" "$ROOT/examples/claude-code/run.sh" -p "$PROMPT" </dev/null 2>/dev/null)"
  else
    out="$(PROVIDER="$provider" timeout "$TIMEOUT" "$ROOT/examples/codex/run.sh" exec --skip-git-repo-check -m "$model" "$PROMPT" </dev/null 2>/dev/null)"
  fi
  rc=$?
  if [ "$rc" -eq 0 ] && [ -n "${out// /}" ]; then
    echo "OK: $provider/$model" >&2; printf '%s\n' "$out"; exit 0
  fi
  echo "    gagal (exit $rc), coba berikutnya" >&2
done
echo "Semua percobaan gagal." >&2; exit 1
