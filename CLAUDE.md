# llm-api

Proyek latihan untuk mencoba API LLM gratis dan memakainya dengan coding agent (Codex CLI).
Referensi provider: `repo/awesome-freellm-apis` (git submodule, read-only). Bahasa pemrograman
belum dipilih; contoh saat ini berupa skrip bash + config.

## Struktur

```
repo/awesome-freellm-apis/  # submodule referensi (JANGAN diedit)
providers/                  # catatan & hasil uji per provider/tool
  codex.md                  #   Codex CLI + OpenRouter (jalan), Groq (gagal)
  claude-code.md            #   Claude Code + OpenRouter (jalan)
examples/
  groq-chat.sh              # satu prompt ke Groq via curl
  codex/                    # config.toml + run.sh (Codex via OpenRouter)
  claude-code/              # run.sh (Claude Code via OpenRouter)
notes/                      # hasil eksperimen (latensi, rate limit nyata)
secrets/                    # API key (di-ignore git): groq.env, openrouter.env
.codex-home/ .claude-home/  # config terisolasi hasil run.sh (di-ignore git)
```

## Perintah

```bash
git submodule update --init --recursive        # setelah clone
examples/groq-chat.sh "pertanyaan"             # tes Groq
examples/codex/run.sh exec "tugas"             # Codex via OpenRouter
examples/claude-code/run.sh -p "tugas"         # Claude Code via OpenRouter
git submodule update --remote repo/awesome-freellm-apis   # perbarui referensi
```

## Secrets

- `secrets/groq.env`: `GROQ_API_KEY=...`
- `secrets/openrouter.env`: variabel gaya Claude Code (`ANTHROPIC_BASE_URL=https://openrouter.ai/api`,
  `ANTHROPIC_AUTH_TOKEN=<key>`, `ANTHROPIC_API_KEY=""`). `examples/codex/run.sh` memetakan token
  itu ke `OPENROUTER_API_KEY`.
- Jangan pernah mencetak, meng-commit, atau menyalin isi `secrets/`. Saat memeriksa, redaksi nilainya.

## Temuan yang perlu diingat

- README referensi **sudah usang** di banyak titik: model seperti `llama-3.3-70b-versatile` dan
  `openai/gpt-oss-120b:free` sudah tidak ada. Selalu cek daftar model aktif sebelum memakainya:
  Groq `GET /openai/v1/models` (pakai key), OpenRouter `GET /api/v1/models`.
- Codex CLI (0.166) hanya memakai Responses API via `config.toml` (`wire_api = "responses"`);
  cara `OPENAI_BASE_URL` di referensi tidak berlaku. Perlu `web_search = "disabled"`,
  `model_reasoning_summary = "none"`, dan fitur multi-agent dimatikan agar backend gratis menerima request.
- Claude Code memakai Anthropic Messages API: hanya jalan lewat gateway yang punya endpoint itu
  (OpenRouter `https://openrouter.ai/api`). Groq/NIM langsung tidak didukung.
- Groq + Codex gagal (`invalid JSON body`); Groq free juga dibatasi ~8000 token/menit.
- Model `:free` OpenRouter sering berganti dan kena 429. Hasil kode dari model gratis harus direview
  (contoh: path `ROOT` salah dan JSON tidak di-escape pada skrip buatan Codex).

## Konvensi

- Skrip bash: `set -euo pipefail`, `ROOT` dihitung dari lokasi skrip, key dimuat dari `secrets/`.
- JSON dibangun dengan `python3 -I`, bukan interpolasi string.
- Config tool (Codex/Claude Code) dijalankan dengan `*_HOME` terisolasi; jangan ubah `~/.codex`
  atau `~/.claude` tanpa persetujuan pengguna.
- Catat setiap provider/tool baru yang dicoba di `providers/`, dengan tanggal uji dan versi.
- Jangan memodifikasi isi submodule.
