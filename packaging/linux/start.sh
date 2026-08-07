#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$BASE_DIR/tmp" "$BASE_DIR/logs" "$BASE_DIR/pipeline"

export STIRLING_BASE_PATH="${STIRLING_BASE_PATH:-$BASE_DIR}"
export SECURITY_ENABLELOGIN="${SECURITY_ENABLELOGIN:-false}"
export DISABLE_ADDITIONAL_FEATURES="${DISABLE_ADDITIONAL_FEATURES:-false}"
export SYSTEM_DEFAULTLOCALE="${SYSTEM_DEFAULTLOCALE:-zh-CN}"
PORT="${PANPDF_PORT:-8083}"

exec "$BASE_DIR/jre/bin/java" \
  -Dfile.encoding=UTF-8 \
  -Djava.io.tmpdir="$BASE_DIR/tmp" \
  -Dserver.port="$PORT" \
  -Dspring.threads.virtual.enabled=true \
  -Dspring.web.resources.cache.period=0 \
  -cp "$BASE_DIR/app/app.jar:$BASE_DIR/app/lib/*" \
  stirling.software.SPDF.SPDFApplication
