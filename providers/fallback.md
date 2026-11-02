# Fallback saat kuota Claude habis

Diuji 2026-11-02.

## Wrapper: `examples/fallback.sh`

```bash
examples/fallback.sh claude "tugas"     # Claude Code -> OpenRouter
examples/fallback.sh codex  "tugas"     # Codex CLI   -> OpenRouter
MAX_TRIES=8 TIMEOUT=300 examples/fallback.sh claude "tugas"
MODELS="id1:free id2:free" examples/fallback.sh codex "tugas"   # daftar manual
```

Cara kerja (LLM7 ditambahkan di akhir daftar: langsung untuk codex, via proxy untuk claude): mengambil model `:free` dari OpenRouter yang mendukung tool calling dan konteks >= 64k
(konteks terbesar dulu), lalu mencoba satu per satu lewat `claude-code/run.sh` atau `codex/run.sh`
sampai ada yang exit 0 dengan jawaban tidak kosong. Log percobaan di stderr, jawaban di stdout.

Hasil uji: model pertama sengaja salah (`tidak/ada:free`) gagal, lalu wrapper pindah ke model berikutnya,
berhasil untuk `claude` dan `codex`. Penemuan otomatis memilih `thinkingmachines/inkling-small:free`.

Batasan: wrapper hanya untuk mode sekali jalan (`-p` / `exec`); tidak ada fallback di tengah sesi
interaktif. Kegagalan di tengah tugas panjang akan mengulang tugas dari awal pada model berikutnya.

## Provider lain yang diselidiki

Probe tanpa key atas `POST /responses` (butuh untuk Codex) dan `/chat/completions`:

| Provider | Hasil |
|---|---|
| OpenRouter | Jalan (Codex dan Claude Code). Satu-satunya yang sudah diuji penuh. |
| Groq | `/responses` ada, tapi body Codex ditolak; lihat `codex.md`. |
| LLM7.io | Jalan dengan Codex (key di `secrets/llm7.env`). Lihat bagian LLM7 di bawah. Tidak ada endpoint Anthropic; Claude Code memakainya lewat proxy LiteLLM (berhasil diuji). |
| OpenCode Zen | Pemakaian gratis anonim habis (429 `FreeUsageLimitError`); gratis hanya untuk dipakai di OpenCode. |
| Cerebras, Gemini | `/responses` 404: tidak cocok dengan Codex. |
| NVIDIA NIM, SambaNova, xAI | `/responses` ada (400/422 tanpa key), belum diuji dengan key. |
| Mistral, Hugging Face, DeepSeek, Z AI | 401 pada keduanya; tidak bisa disimpulkan tanpa key. |

## LLM7.io (diuji 2026-11-02)

- Base URL `https://api.llm7.io/v1`, variabel `LLM7_API_KEY` di `secrets/llm7.env`.
- 67 model terdaftar, tetapi hanya tier `turbo` yang gratis: `gpt-oss:20b`, `nemotron-3-nano:30b`
  (konteks 1M), `codestral-latest`, `mistral-Nemo-Instruct-2407`. 63 model tier `pro` (termasuk nama
  claude/gpt/gemini) membalas `402 insufficient_balance` tanpa saldo. Cek tier lewat `GET /v1/models`.
- Codex: `nemotron-3-nano:30b` jalan. `gpt-oss:20b` ditolak karena Codex mengirim parameter
  reasoning (`unsupported_model_feature`).
- Pakai: `PROVIDER=llm7 examples/codex/run.sh exec -m nemotron-3-nano:30b "tugas"`; config di
  `examples/codex/config.llm7.toml`. `fallback.sh codex` otomatis menambahkan LLM7 sebagai cadangan
  setelah model OpenRouter (ubah dengan `LLM7_MODELS`).
- Respons dari model reasoning berisi "pikiran" model; Codex hanya menampilkan jawaban akhir.

Untuk menambah cadangan lain di luar OpenRouter dan LLM7: daftar key (NVIDIA NIM, LLM7, SambaNova), simpan di
`secrets/<provider>.env`, lalu tambahkan `[model_providers.<nama>]` di config Codex dengan
`wire_api = "responses"` dan uji seperti di `codex.md`. Claude Code tetap butuh endpoint Anthropic.
