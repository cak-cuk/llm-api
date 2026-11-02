# Codex CLI dengan API LLM gratis

Diuji 2026-11-02 dengan `codex-cli 0.166.0`. Referensi upstream
(`repo/awesome-freellm-apis/code-examples/codex.md`) menyarankan `OPENAI_BASE_URL` +
`OPENAI_API_KEY`; cara itu **sudah usang** untuk versi ini. Gunakan `config.toml`.

## Ringkasan hasil uji

| Provider | Status | Catatan |
|---|---|---|
| OpenRouter | **Jalan** | `nvidia/nemotron-3.5-lightning:free` menjawab. Model `:free` sering 429 / berganti. |
| Groq | **Tidak jalan** | `/responses` Groq menolak body request Codex (`invalid JSON body`). Lihat di bawah. |

## Cara pakai (OpenRouter)

Prasyarat: `codex` terpasang, `secrets/openrouter.env` berisi key
(`ANTHROPIC_AUTH_TOKEN` atau `OPENROUTER_API_KEY`).

```bash
examples/codex/run.sh exec "Balas hanya satu kata: halo"   # sekali jalan
examples/codex/run.sh                                      # mode interaktif
examples/codex/run.sh exec -m google/gemma-4-31b-it:free "..."  # ganti model
```

`run.sh` memakai `CODEX_HOME=.codex-home/` (di-ignore git) sehingga `~/.codex` Anda tidak diubah.
Untuk pemakaian permanen, salin `examples/codex/config.toml` ke `~/.codex/config.toml`
dan `export OPENROUTER_API_KEY=...`.

## Penjelasan `config.toml`

```toml
web_search = "disabled"            # tool web_search bukan tipe "function"; backend gratis menolaknya
model_reasoning_summary = "none"   # Codex mengirim reasoning.summary="auto"; tidak semua backend mendukung
model = "nvidia/nemotron-3.5-lightning:free"
model_provider = "openrouter"

[model_providers.openrouter]
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"     # NAMA variabel env, bukan nilai key
wire_api = "responses"             # Codex 0.166 hanya bicara Responses API

[features]                         # kurangi ukuran prompt/tool (body awal ~40 KB)
multi_agent = false
goals = false
image_generation = false
apps = false
```

## Mengapa Groq gagal

Diselidiki dengan menangkap body yang dikirim Codex lalu mengulangnya ke Groq:

1. `reasoning.summary` ditolak -> diatasi `model_reasoning_summary = "none"`.
2. Tool non-`function` (`web_search`, namespace `multi_agent_v1`) ditolak -> diatasi dengan
   `web_search = "disabled"` dan `multi_agent = false`.
3. Setelah itu Groq masih menolak: `unknown field client_metadata` dan masih `invalid JSON body`
   walau field itu dibuang. Penyebab sisanya belum ditemukan; tidak bisa diatur lewat config.
4. Selain itu, Groq free tier membatasi 8000 token/menit, sedangkan satu request awal Codex
   sekitar 6000+ token (OpenRouter melaporkan 5.961 untuk "halo"). Tanpa tool, request tetap
   mudah kena 429.

Jalan keluar yang mungkin: proxy lokal yang membuang field tak didukung, atau pakai provider lain
yang mendukung Responses API.

## Caveat

- Model gratis tidak dirancang untuk agentic coding; kualitas tool calling bervariasi.
  Peringatan `Model metadata ... not found` di log Codex normal untuk model non-OpenAI.
- Daftar model `:free` OpenRouter berubah cepat; cek dulu:
  `curl -s https://openrouter.ai/api/v1/models | jq -r '.data[] | select(.id|endswith(":free")) | .id'`
- Jalankan Codex di direktori yang aman: model gratis dapat menjalankan perintah shell
  (`sandbox` default Codex read-only untuk `exec`; jangan longgarkan tanpa alasan).
- 429 berulang berarti kena rate limit; coba model lain atau tunggu.
