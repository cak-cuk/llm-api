# How-to: coding agent dengan API LLM gratis

Panduan lengkap untuk tetap bekerja dengan Claude Code dan Codex CLI memakai model gratis
saat kuota Claude/OpenAI habis. Semua perintah diuji pada 2026-11-02 dengan `claude 2.1.316`,
`codex-cli 0.166.0`, dan `litellm 1.106.6` di Debian 13 (WSL2).

> Peringatan kualitas: model gratis jauh lebih lemah daripada Claude. Pada uji, model gratis membuat
> dua bug pada skrip bash kecil. Pakai untuk tugas kecil dan review setiap hasilnya.

## Daftar isi

1. [Peta cepat: provider x tool](#1-peta-cepat-provider-x-tool)
2. [Prasyarat](#2-prasyarat)
3. [Menyiapkan API key](#3-menyiapkan-api-key)
4. [Claude Code](#4-claude-code)
5. [Codex CLI](#5-codex-cli)
6. [Fallback otomatis](#6-fallback-otomatis)
7. [Proxy LiteLLM (cara kerja & perawatan)](#7-proxy-litellm)
8. [Memasang secara global (opsional)](#8-memasang-secara-global-opsional)
9. [Troubleshooting](#9-troubleshooting)
10. [Keamanan](#10-keamanan)
11. [Menambah provider baru](#11-menambah-provider-baru)

## 1. Peta cepat: provider x tool

| Provider | Claude Code | Codex CLI | Catatan |
|---|---|---|---|
| OpenRouter (model `:free`) | Jalan, langsung | Jalan, langsung | Pilihan utama. Model sering berganti dan kena 429. |
| LLM7.io (tier `turbo`) | Jalan, via proxy LiteLLM | Jalan, langsung | Hanya 4 model gratis; 63 model `pro` butuh saldo. |
| Groq | Tidak bisa | Tidak bisa | Claude Code butuh ~9.900 token/request, batas gratis 8.000 TPM. Codex: body ditolak. Hanya cocok untuk skrip langsung. |

- Claude Code berbicara Anthropic Messages API. Dari provider yang diuji, hanya OpenRouter yang punya
  endpoint itu secara native; LLM7 dan Groq hanya OpenAI-compatible, jadi perlu proxy penerjemah.
- Codex CLI (0.166) hanya berbicara Responses API (`wire_api = "responses"`). Cara lama
  `OPENAI_BASE_URL` + `OPENAI_API_KEY` tidak berlaku lagi.

## 2. Prasyarat

| Kebutuhan | Cek | Pasang |
|---|---|---|
| `claude` | `claude --version` | https://code.claude.com/docs |
| `codex` | `codex --version` | https://developers.openai.com/codex |
| `bash`, `curl`, `python3` (>= 3.12) | `python3 --version` | paket distro |
| `python3-venv` (hanya untuk proxy) | `python3 -m venv /tmp/x` | `sudo apt install python3-venv` |
| Akun gratis OpenRouter, LLM7 | - | lihat bagian 3 |

Clone dan masuk ke repo: `git clone <url> && cd llm-api`.

## 3. Menyiapkan API key

Semua key disimpan di `secrets/` (di-ignore git, permission `600`). Jangan commit, jangan tempel di chat.

### 3.1 OpenRouter - `secrets/openrouter.env`

Daftar di https://openrouter.ai, buat key di https://openrouter.ai/keys. Isi file memakai nama
variabel gaya Claude Code (supaya Claude Code bisa langsung `source`):

```bash
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"   # tanpa /v1
ANTHROPIC_AUTH_TOKEN=sk-or-v1-xxxxxxxx                    # key Anda
ANTHROPIC_API_KEY=""                                      # HARUS kosong
```

Model `:free` dibatasi sekitar puluhan request/hari. Menurut daftar referensi upstream, top-up $10 sekali menaikkan batas ke sekitar 1.000 request/hari
(belum saya uji; keputusan ada di Anda).

### 3.2 LLM7 - `secrets/llm7.env`

Daftar dan buat key di https://token.llm7.io (atau https://dash.llm7.io). Isi:

```bash
LLM7_API_KEY=xxxxxxxx
```

Hanya model tier `turbo` yang gratis. Daftar tier terkini:

```bash
set -a; source secrets/llm7.env; set +a
curl -s https://api.llm7.io/v1/models -H "Authorization: Bearer $LLM7_API_KEY" |
  python3 -I -c "import sys,json; [print(m['id'],m['tier']) for m in json.load(sys.stdin)['data'] if m['tier']!='pro']"
```

### 3.3 Groq (opsional, hanya skrip langsung) - `secrets/groq.env`

Key di https://console.groq.com/keys. Isi: `GROQ_API_KEY=gsk_xxxxxxxx`.

### 3.4 Proxy - `secrets/litellm.env`

Dibuat otomatis oleh `proxy.sh` saat pertama jalan (`LITELLM_MASTER_KEY=sk-...` acak). Tidak
perlu diisi manual.

Verifikasi permission: `chmod 600 secrets/*.env` dan `git check-ignore secrets/llm7.env` (harus
mencetak path).

## 4. Claude Code

Skrip: `examples/claude-code/run.sh`. Ia memakai `CLAUDE_CONFIG_DIR=.claude-home/` sehingga login
dan pengaturan `~/.claude` Anda tidak tersentuh. `CLAUDE.md` proyek tetap terbaca.

```bash
examples/claude-code/run.sh                                  # interaktif, OpenRouter
examples/claude-code/run.sh -p "Balas satu kata: halo"       # sekali jalan (non-interaktif)
MODEL=google/gemma-4-31b-it:free examples/claude-code/run.sh # ganti model OpenRouter

PROVIDER=llm7 examples/claude-code/run.sh                    # LLM7 via proxy (nemotron)
PROVIDER=llm7 MODEL=llm7-gpt-oss examples/claude-code/run.sh # alias lain: llm7-gpt-oss
```

| `PROVIDER` | Jalur | Variabel yang diset skrip |
|---|---|---|
| `openrouter` | Claude Code ke OpenRouter | dari `openrouter.env`; `ANTHROPIC_MODEL=$MODEL` |
| `llm7` | Claude Code ke proxy `127.0.0.1:4000`, lalu ke LLM7 | `ANTHROPIC_BASE_URL=http://127.0.0.1:4000`, token = master key proxy |

Tanpa skrip (OpenRouter saja): `set -a; source secrets/openrouter.env; set +a; ANTHROPIC_MODEL=<id> ANTHROPIC_SMALL_FAST_MODEL=<id> claude`.

Hal yang normal:

- Peringatan `Claude Code doesn't recognize the model ...; assumes 200k context`. Tidak fatal.
  Untuk model berkonteks kecil, lihat https://code.claude.com/docs/en/model-config.
- Nama model "Claude" di antarmuka hanya kosmetik; model sebenarnya ialah `$MODEL`.
- `ANTHROPIC_SMALL_FAST_MODEL` diset sama dengan model utama agar tugas latar tidak memanggil model
  Claude berbayar.

Batasan: Claude Code butuh tool calling yang baik. Model kecil sering gagal pada tugas
multi-langkah. Jangan pakai `--dangerously-skip-permissions` pada model yang tidak dikenal.

## 5. Codex CLI

Skrip: `examples/codex/run.sh`. Ia memakai `CODEX_HOME=.codex-home/` (tidak menyentuh `~/.codex`) dan
menyalin config sesuai provider. `AGENTS.md` (symlink ke `CLAUDE.md`) memberi konteks proyek.

```bash
examples/codex/run.sh exec "jelaskan repo ini"               # sekali jalan, OpenRouter
examples/codex/run.sh                                        # interaktif
examples/codex/run.sh exec -m google/gemma-4-31b-it:free "..."   # ganti model

PROVIDER=llm7 examples/codex/run.sh exec -m nemotron-3-nano:30b "..."   # LLM7
```

Model yang teruji: OpenRouter `nvidia/nemotron-3.5-lightning:free`; LLM7 `nemotron-3-nano:30b`
(konteks 1M). `gpt-oss:20b` di LLM7 gagal (`does not support reasoning`).

### 5.1 Mengapa `config.toml` berisi baris-baris khusus

`examples/codex/config.toml` (OpenRouter):

```toml
web_search = "disabled"            # tool bertipe non-function ditolak backend gratis
model_reasoning_summary = "none"   # Codex mengirim reasoning.summary="auto"; sering ditolak
model = "nvidia/nemotron-3.5-lightning:free"
model_provider = "openrouter"

[model_providers.openrouter]
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"     # NAMA variabel env, bukan nilai key
wire_api = "responses"

[features]                         # kecilkan prompt/tool (body awal ~40 KB, ~6k token)
multi_agent = false
goals = false
image_generation = false
apps = false
```

`config.llm7.toml` identik kecuali `[model_providers.llm7]` (`base_url = https://api.llm7.io/v1`,
`env_key = "LLM7_API_KEY"`). `run.sh` memetakan `ANTHROPIC_AUTH_TOKEN` ke `OPENROUTER_API_KEY`.

### 5.2 Mengapa Groq tidak jalan dengan Codex

Diselidiki dengan menangkap body request Codex lalu mengulangnya ke Groq: `reasoning.summary`
ditolak, tool non-function ditolak (dua ini bisa diatasi config), lalu body masih ditolak
(`invalid JSON body`, `unknown field client_metadata`) dan tidak bisa diatur lewat config. Groq
gratis juga dibatasi 8.000 token/menit sementara satu request Codex sekitar 6.000 token.

## 6. Fallback otomatis

`examples/fallback.sh` mencoba beberapa model berurutan sampai ada yang berhasil (exit 0 dan
jawaban tidak kosong):

```bash
examples/fallback.sh claude "Balas hanya satu kata: halo"
examples/fallback.sh codex  "ringkas file CLAUDE.md"
MAX_TRIES=8 TIMEOUT=300 examples/fallback.sh claude "tugas"
MODELS="id1:free id2:free" examples/fallback.sh codex "tugas"     # daftar manual
```

Urutan kandidat:

1. Model `:free` OpenRouter yang mendukung tool calling dan konteks >= 64k (konteks terbesar dulu),
   ditemukan otomatis dari `https://openrouter.ai/api/v1/models`.
2. LLM7 sebagai cadangan terakhir, jika `secrets/llm7.env` ada: `nemotron-3-nano:30b` untuk
   `codex`; `llm7-nemotron` untuk `claude` (hanya bila proxy terpasang, bagian 7).

Log percobaan keluar di stderr, jawaban di stdout. Batasan: hanya mode sekali jalan; kegagalan di
tengah tugas panjang mengulang tugas dari awal pada model berikutnya.

## 7. Proxy LiteLLM

Dibutuhkan agar Claude Code bisa memakai provider OpenAI-only (LLM7).

### 7.1 Pemasangan sekali

```bash
sudo apt install python3-venv                 # jika belum ada
python3 -m venv tools/.venv
tools/.venv/bin/python -m pip install 'litellm[proxy]'
```

`tools/` di-ignore git. Ukurannya besar (ratusan MB); hapus kapan saja dengan `rm -rf tools/`.

### 7.2 Mengelola proxy

`run.sh` menyalakannya otomatis saat `PROVIDER=llm7`. Manual:

```bash
examples/claude-code/proxy-ctl.sh start|stop|status|logs
```

Proxy mendengar di `127.0.0.1:4000` saja (tidak terbuka ke jaringan) dan wajib master key
(`secrets/litellm.env`). Ganti port: `PORT=4100`. Log: `tools/proxy.log`.

### 7.3 Alias model

Didefinisikan di `examples/claude-code/litellm.yaml`:

| Alias | Backend |
|---|---|
| `llm7-nemotron` | LLM7 `nemotron-3-nano:30b` |
| `llm7-gpt-oss` | LLM7 `gpt-oss:20b` |
| `groq-gpt-oss` | Groq `openai/gpt-oss-20b` (tidak bisa dipakai Claude Code, lihat bagian 1) |

Tes proxy langsung:

```bash
set -a; source secrets/litellm.env; set +a
curl -s http://127.0.0.1:4000/v1/messages -H 'content-type: application/json' \
  -H "x-api-key: $LITELLM_MASTER_KEY" -H 'anthropic-version: 2023-06-01' \
  -d '{"model":"llm7-nemotron","max_tokens":300,"messages":[{"role":"user","content":"halo"}]}'
```

## 8. Memasang secara global (opsional)

Skrip `run.sh` sengaja tidak mengubah `~/.codex` atau `~/.claude`. Jika ingin Codex selalu memakai
OpenRouter, lakukan sendiri:

```bash
cp examples/codex/config.toml ~/.codex/config.toml      # cek dulu: tidak menimpa config lama
echo 'export OPENROUTER_API_KEY="$(sed -n "s/^ANTHROPIC_AUTH_TOKEN=//p" $HOME/git/llm-api/secrets/openrouter.env | tr -d "\"")"' >> ~/.bashrc
```

Key tetap dibaca dari `secrets/`, tidak disalin ke profile.

## 9. Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| `429 Too Many Requests` / `FreeUsageLimitError` | Batas gratis | Ganti model (`MODEL=`/`-m`), tunggu, atau pakai `fallback.sh` |
| `404 ... model unavailable` | ID model `:free` sudah dicabut | Cek daftar model terkini (bagian 11) |
| `invalid JSON body` (Groq + Codex) | Body Codex tidak didukung | Tidak bisa diperbaiki lewat config; pakai OpenRouter/LLM7 |
| `does not support reasoning` | Model tidak menerima parameter reasoning Codex | Pakai `nemotron-3-nano:30b` |
| `402 insufficient_balance` (LLM7) | Model tier `pro` | Pilih model tier `turbo` |
| `Request too large ... TPM` (Groq) | Prompt agent > 8.000 token | Tidak bisa dipakai dengan agent; skrip langsung saja |
| `proxy gagal start` | Port terpakai / LiteLLM belum terpasang | `proxy-ctl.sh logs`; ganti `PORT`; ulangi 7.1 |
| `ensurepip is not available` | `python3-venv` belum ada | `sudo apt install python3-venv` |
| `Could not find bubblewrap` (Codex) | Peringatan sandbox | Aman diabaikan; Codex memakai bubblewrap bawaan |
| `Model metadata ... not found` | Model non-OpenAI | Normal |
| Codex diam lama | Model lambat / retry | Tambah `TIMEOUT`, atau ganti model |

Debug body request yang dikirim Codex: jalankan listener HTTP lokal, arahkan `base_url` config ke
`http://127.0.0.1:<port>`, lalu baca body yang diterima (teknik yang dipakai untuk menganalisis
kegagalan Groq).

## 10. Keamanan

- `secrets/`, `.codex-home/`, `.claude-home/`, `tools/` ada di `.gitignore`. Periksa sebelum commit:
  `git ls-files | grep -E 'secrets|-home|tools'` harus kosong.
- Jangan mencetak isi `secrets/`; redaksi nilai saat berbagi log (`sed 's/=.*/=<redacted>/'`).
- Prompt dan kode Anda dikirim ke penyedia gratis pihak ketiga yang mungkin menyimpan/melatih
  dengan data itu. Jangan kirim kode atau data rahasia.
- Agent dapat menjalankan perintah dan mengedit file. Jalankan di direktori aman; biarkan sandbox
  Codex (`read-only` untuk `exec`) dan jangan memberi izin otomatis pada model asing.
- Proxy hanya di `127.0.0.1`; jangan ubah `--host` ke `0.0.0.0`.

## 11. Menambah provider baru

1. Dapatkan key, simpan di `secrets/<provider>.env`.
2. Cek endpoint yang tersedia tanpa key: `POST <base>/responses` (Codex) dan `/chat/completions`
   (401/400 berarti ada; 404 berarti tidak).
3. Daftar model dan tier-nya (daftar sering menyesatkan):
   - OpenRouter: `curl -s https://openrouter.ai/api/v1/models | python3 -I -c "import sys,json; [print(m['id']) for m in json.load(sys.stdin)['data'] if m['id'].endswith(':free')]"`
   - LLM7: lihat 3.2. Groq: `GET https://api.groq.com/openai/v1/models` dengan key.
4. Codex: tambahkan `examples/codex/config.<nama>.toml` (salin `config.llm7.toml`) dan satu cabang
   `case` di `examples/codex/run.sh`. Uji dengan `exec -m <model> "Balas satu kata: halo"`.
5. Claude Code: jika provider tidak punya endpoint Anthropic, tambahkan alias di
   `examples/claude-code/litellm.yaml` dan cabang di `examples/claude-code/run.sh`.
6. Catat hasil (tanggal, versi, model, batas nyata) di `providers/`.
7. Tambahkan ke `fallback.sh` jika layak jadi cadangan.

Referensi daftar provider (sering usang; selalu verifikasi):
https://github.com/open-free-llm-api/awesome-freellm-apis
