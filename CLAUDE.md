# llm-api

Proyek latihan untuk mencoba API LLM gratis dan memakainya dengan coding agent (Claude Code dan Codex CLI).
Panduan lengkap: `docs/HOWTO.md`.
Referensi provider (tidak disalin ke repo ini): https://github.com/open-free-llm-api/awesome-freellm-apis. Bahasa pemrograman
belum dipilih; contoh saat ini berupa skrip bash + config.

## Struktur

```
docs/HOWTO.md               # panduan lengkap cara pakai & troubleshooting
providers/                  # catatan & hasil uji per provider/tool
  codex.md                  #   Codex CLI + OpenRouter (jalan), Groq (gagal)
  claude-code.md            #   Claude Code + OpenRouter (jalan)
  fallback.md               #   wrapper fallback + hasil probe provider lain
examples/
  groq-chat.sh              # satu prompt ke Groq via curl
  fallback.sh               # claude|codex dengan auto-ganti model :free bila gagal
  codex/                    # config.toml + run.sh (Codex via OpenRouter)
  claude-code/              # run.sh (OpenRouter | LLM7), proxy.sh/proxy-ctl.sh, litellm.yaml
notes/                      # hasil eksperimen (latensi, rate limit nyata)
secrets/                    # API key (di-ignore git): groq, llm7, openrouter, litellm .env
tools/                      # venv LiteLLM + log proxy (di-ignore git)
.codex-home/ .claude-home/  # config terisolasi hasil run.sh (di-ignore git)
```

## Perintah

```bash
examples/groq-chat.sh "pertanyaan"             # tes Groq
examples/codex/run.sh exec "tugas"             # Codex via OpenRouter
PROVIDER=llm7 examples/codex/run.sh exec -m nemotron-3-nano:30b "tugas"   # Codex via LLM7
examples/claude-code/run.sh -p "tugas"         # Claude Code via OpenRouter
PROVIDER=llm7 examples/claude-code/run.sh -p "tugas"   # Claude Code via LLM7 (proxy LiteLLM, otomatis)
examples/claude-code/proxy-ctl.sh stop         # matikan proxy
examples/fallback.sh claude "tugas"            # idem, ganti model otomatis bila gagal
```

## Secrets

- `secrets/groq.env`: `GROQ_API_KEY=...`
- `secrets/llm7.env`: `LLM7_API_KEY=...` (hanya model tier `turbo` yang gratis).
- `secrets/openrouter.env`: variabel gaya Claude Code (`ANTHROPIC_BASE_URL=https://openrouter.ai/api`,
  `ANTHROPIC_AUTH_TOKEN=<key>`, `ANTHROPIC_API_KEY=""`). `examples/codex/run.sh` memetakan token
  itu ke `OPENROUTER_API_KEY`.
- Jangan pernah mencetak, meng-commit, atau menyalin isi `secrets/`. Saat memeriksa, redaksi nilainya.

## Temuan yang perlu diingat

- README referensi sudah usang di banyak titik: model seperti `llama-3.3-70b-versatile` dan
  `openai/gpt-oss-120b:free` sudah tidak ada. Selalu cek daftar model aktif sebelum memakainya:
  Groq `GET /openai/v1/models` (pakai key), OpenRouter `GET /api/v1/models`.
- Codex CLI (0.166) hanya memakai Responses API via `config.toml` (`wire_api = "responses"`);
  cara `OPENAI_BASE_URL` di referensi tidak berlaku. Perlu `web_search = "disabled"`,
  `model_reasoning_summary = "none"`, dan fitur multi-agent dimatikan agar backend gratis menerima request.
- Claude Code memakai Anthropic Messages API: native hanya di OpenRouter (`https://openrouter.ai/api`);
  LLM7 lewat proxy LiteLLM lokal. Groq tidak bisa (prompt ~9.900 token > batas 8.000 TPM).
- Groq + Codex gagal (`invalid JSON body`); Groq free juga dibatasi ~8000 token/menit.
- Model `:free` OpenRouter sering berganti dan kena 429. Hasil kode dari model gratis harus direview
  (contoh: path `ROOT` salah dan JSON tidak di-escape pada skrip buatan Codex).

## Saat kuota Claude habis

Pakai `examples/fallback.sh claude|codex "tugas"` (OpenRouter model :free; LLM7 sebagai cadangan terakhir). `AGENTS.md` adalah
symlink ke file ini agar Codex membaca konteks yang sama. Kualitas model gratis lebih rendah:
batasi tugas kecil dan review hasilnya. Detail & provider lain: `providers/fallback.md`.

## Konvensi

- Skrip bash: `set -euo pipefail`, `ROOT` dihitung dari lokasi skrip, key dimuat dari `secrets/`.
- JSON dibangun dengan `python3 -I`, bukan interpolasi string.
- Config tool (Codex/Claude Code) dijalankan dengan `*_HOME` terisolasi; jangan ubah `~/.codex`
  atau `~/.claude` tanpa persetujuan pengguna.
- Catat setiap provider/tool baru yang dicoba di `providers/`, dengan tanggal uji dan versi.
