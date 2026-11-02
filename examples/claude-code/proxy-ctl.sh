#!/usr/bin/env bash
# Kelola proxy LiteLLM di latar belakang: start | stop | status | logs
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${PORT:-4000}"; PIDF="$ROOT/tools/proxy.pid"; LOG="$ROOT/tools/proxy.log"
alive() { curl -s -m 2 "http://127.0.0.1:$PORT/health/liveliness" >/dev/null 2>&1; }
case "${1:-status}" in
  start)
    alive && exit 0
    mkdir -p "$ROOT/tools"
    PORT="$PORT" nohup "$ROOT/examples/claude-code/proxy.sh" >"$LOG" 2>&1 &
    echo $! > "$PIDF"
    for _ in $(seq 1 60); do alive && { echo "proxy siap di :$PORT" >&2; exit 0; }; sleep 2; done
    echo "proxy gagal start; lihat $LOG" >&2; exit 1 ;;
  stop)   if [ -f "$PIDF" ]; then pkill -P "$(cat "$PIDF")" 2>/dev/null || true; kill "$(cat "$PIDF")" 2>/dev/null || true; rm -f "$PIDF"; fi; echo stopped ;;
  status) alive && echo "proxy hidup di :$PORT" || echo "proxy mati" ;;
  logs)   tail -n 50 "$LOG" ;;
  *) echo "pakai: $0 start|stop|status|logs" >&2; exit 2 ;;
esac
