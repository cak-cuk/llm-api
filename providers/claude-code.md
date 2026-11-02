# Claude Code dengan API LLM gratis

Diuji 2026-11-02 dengan Claude Code 2.1.316.

Claude Code berbicara Anthropic Messages API, bukan OpenAI. Karena itu contoh upstream
(`code-examples/claude-code.md` di https://github.com/open-free-llm-api/awesome-freellm-apis) yang mengarahkan
`ANTHROPIC_BASE_URL` ke `https://api.groq.com/openai/v1` atau NVIDIA NIM tidak akan jalan:
endpoint itu hanya OpenAI-compatible. Gunakan gateway yang menyediakan endpoint Anthropic,
misalnya OpenRouter. Provider OpenAI-only bisa dipakai lewat proxy penerjemah LiteLLM (lihat `docs/HOWTO.md` bagian 7).

## Hasil uji

| Provider | Status | Catatan |
|---|---|---|
| OpenRouter (`https://openrouter.ai/api`) | Jalan | `nvidia/nemotron-3.5-lightning:free` menjawab lewat `claude -p`. |
| LLM7 via proxy LiteLLM | Jalan | `nemotron-3-nano:30b` menjawab lewat `PROVIDER=llm7 examples/claude-code/run.sh -p ...`. |
| Groq via proxy LiteLLM | Tidak jalan | Claude Code kirim ~9.900 token/request; batas gratis Groq 8.000 TPM. Selain itu Groq menolak `prompt_cache_key` (diatasi `additional_drop_params`). |
| NVIDIA NIM langsung | Tidak didukung | Tidak ada endpoint Anthropic Messages; belum diuji lewat proxy. |

## Cara pakai

Prasyarat: `claude` terpasang dan `secrets/openrouter.env` berisi:

```bash
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"   # tanpa /v1
ANTHROPIC_AUTH_TOKEN=sk-or-v1-...                        # key OpenRouter
ANTHROPIC_API_KEY=""                                     # HARUS kosong
```

```bash
examples/claude-code/run.sh                          # interaktif
examples/claude-code/run.sh -p "Balas satu kata: halo"   # sekali jalan
MODEL=google/gemma-4-31b-it:free examples/claude-code/run.sh   # ganti model
```

`run.sh` memakai `CLAUDE_CONFIG_DIR=.claude-home/` (di-ignore git), jadi login dan pengaturan
`~/.claude` tidak ikut berubah. Tanpa skrip, cukup `source secrets/openrouter.env` lalu
`ANTHROPIC_MODEL=<id-model> claude`.

## Variabel penting

| Variabel | Fungsi |
|---|---|
| `ANTHROPIC_BASE_URL` | Alamat gateway. OpenRouter: `https://openrouter.ai/api`. |
| `ANTHROPIC_AUTH_TOKEN` | Key gateway (dikirim sebagai Bearer). |
| `ANTHROPIC_API_KEY` | Kosongkan agar tidak bentrok dengan akun Anthropic. |
| `ANTHROPIC_MODEL` | ID model utama, mis. `nvidia/nemotron-3.5-lightning:free`. |
| `ANTHROPIC_SMALL_FAST_MODEL` | Model untuk tugas latar; samakan agar tidak memanggil model Claude berbayar. |

## Caveat

- Muncul peringatan `Claude Code doesn't recognize the model ...` dan mengasumsikan context 200k.
  Tidak fatal; untuk model berkonteks kecil, atur window sesuai
  https://code.claude.com/docs/en/model-config.
- Model `:free` OpenRouter sering berganti dan kena 429. Cek daftar terkini:
  `curl -s https://openrouter.ai/api/v1/models | jq -r '.data[] | select(.id|endswith(":free")) | .id'`
- Claude Code membutuhkan tool calling yang baik; model gratis kecil sering gagal pada tugas
  multi-langkah. Untuk uji coba awal, pakai mode `-p` dengan tugas sederhana.
- Claude Code dapat menjalankan perintah dan mengedit file. Jalankan di direktori yang aman dan
  jangan beri izin otomatis (`--dangerously-skip-permissions`) pada model yang tidak dikenal.
