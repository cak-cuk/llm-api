#!/usr/bin/env bash
# Kirim satu prompt ke Groq dan cetak jawabannya.
# Pakai: examples/groq-chat.sh "pertanyaan"    (ganti model: MODEL=openai/gpt-oss-120b ...)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a; source "$ROOT/secrets/groq.env"; set +a
: "${GROQ_API_KEY:?GROQ_API_KEY belum diset di secrets/groq.env}"
PROMPT="${1:?Pakai: $0 \"prompt\"}"
export MODEL="${MODEL:-openai/gpt-oss-20b}" PROMPT

# JSON dibangun dengan python agar kutip/newline di prompt aman.
BODY="$(python3 -I -c 'import json,os; print(json.dumps({"model": os.environ["MODEL"], "messages": [{"role": "user", "content": os.environ["PROMPT"]}]}))')"

curl -sS https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" -H "Content-Type: application/json" \
  -d "$BODY" |
python3 -I -c '
import sys, json
d = json.load(sys.stdin)
if "error" in d:
    sys.exit("API error: " + d["error"].get("message", str(d["error"])))
print(d["choices"][0]["message"]["content"])
'
