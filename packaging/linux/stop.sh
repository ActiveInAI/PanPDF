#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
pkill -f "stirling.software.SPDF.SPDFApplication" || true
echo "PanPDF stopped (if it was running)."
