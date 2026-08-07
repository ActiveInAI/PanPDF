#!/usr/bin/env bash
# Regenerate the PanPDF-patched jars from the official Stirling PDF image.
# The proprietary jar is generated locally and is NOT committed to this repo.
set -euo pipefail

IMAGE="${PANPDF_IMAGE:-docker.stirlingpdf.com/stirlingtools/stirling-pdf:2.11.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/work" "$ROOT/patched"

echo "Extracting original jars from ${IMAGE} ..."
docker run --rm -v "$ROOT/work:/out" "$IMAGE" \
  sh -c 'cp /app/app.jar /app/lib/common-2.11.0-plain.jar /app/lib/proprietary-2.11.0-plain.jar /out/'

echo "Applying PanPDF branding patches ..."
python3 "$ROOT/scripts/apply_patches.py" "$ROOT/work/app.jar" "$ROOT/patched/app.jar"
python3 "$ROOT/scripts/apply_patches.py" "$ROOT/work/common-2.11.0-plain.jar" "$ROOT/patched/common-2.11.0-plain.jar"
python3 "$ROOT/scripts/apply_patches.py" "$ROOT/work/proprietary-2.11.0-plain.jar" "$ROOT/patched/proprietary-2.11.0-plain.jar"

echo "Done. patched/ jars are ready for docker compose up."
