#!/usr/bin/env bash
# Smoke-test an amd64 .deb by extracting it and starting PanPDF on a test port.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEB="${1:-$ROOT/dist/panpdf_2.11.0-1_amd64.deb}"
PORT="${TEST_PORT:-18083}"
T="$(mktemp -d "${TMPDIR:-/tmp}/panpdf-test-XXXXXX")"

dpkg-deb -x "$DEB" "$T"
P="$T/opt/panpdf"

STIRLING_BASE_PATH="$P" PANPDF_PORT="$PORT" "$P/scripts/start.sh" > /tmp/panpdf-pkg-test.log 2>&1 &
PID=$!
echo "test dir: $T"
echo "pid: $PID"

ok=0
for i in $(seq 1 75); do
  if curl -sf --max-time 3 -o "$T/home.html" "http://127.0.0.1:$PORT/"; then
    ok=1
    echo "UP after ~$((i*2))s"
    break
  fi
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "PROCESS DIED"
    tail -30 /tmp/panpdf-pkg-test.log
    break
  fi
  sleep 2
done

if [ "$ok" = "1" ]; then
  grep -o '<title>[^<]*</title>' "$T/home.html" || true
  curl -sS --max-time 5 "http://127.0.0.1:$PORT/api/v1/config/app-config" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); print('enableLogin:', d['enableLogin'], 'appName:', d['appNameNavbar'])"
fi

kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
echo "test done (files kept in $T)"
