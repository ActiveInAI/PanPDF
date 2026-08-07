#!/usr/bin/env bash
# Build PanPDF installers:
#   dist/panpdf_2.11.0-1_amd64.deb
#   dist/panpdf_2.11.0-1_arm64.deb
#   dist/PanPDF-windows-x64.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${DIST_BUILD:-$ROOT/dist-build}"
OUT="${OUT:-$ROOT/dist}"
VERSION="2.11.0-1"
mkdir -p "$OUT"

copy_runtime() {
  local dest="$1" jre_src="$2"
  mkdir -p "$dest/opt/panpdf"
  cp -r "$BUILD/app" "$dest/opt/panpdf/app"
  cp -r "$BUILD/configs" "$dest/opt/panpdf/configs"
  cp -r "$BUILD/customFiles" "$dest/opt/panpdf/customFiles"
  cp -r "$jre_src" "$dest/opt/panpdf/jre"
  cp -r "$ROOT/packaging/linux" "$dest/opt/panpdf/scripts"
  chmod +x "$dest/opt/panpdf/scripts/start.sh" "$dest/opt/panpdf/scripts/stop.sh"
  mkdir -p "$dest/opt/panpdf/tmp" "$dest/opt/panpdf/logs" "$dest/opt/panpdf/pipeline"
}

make_deb() {
  local arch="$1" jre_src="$2"
  local pkg="panpdf_${VERSION}_${arch}"
  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/panpdf-deb-${arch}-XXXXXX")"
  mkdir -p "$work/DEBIAN"
  copy_runtime "$work" "$jre_src"

  local size
  size="$(du -sk "$work/opt" | awk '{print $1}')"
  cat > "$work/DEBIAN/control" <<EOF
Package: panpdf
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${arch}
Maintainer: ActiveInAI <ActiveInAI@gmail.com>
Installed-Size: ${size}
Depends: libc6 (>= 2.17)
Recommends: libreoffice-core, libreoffice-writer, libreoffice-calc, libreoffice-impress, qpdf, ghostscript, tesseract-ocr, poppler-utils, fonts-noto-cjk, fontforge, unpaper, python3-ocrmypdf
Description: PanPDF - rebranded Stirling PDF local PDF toolbox
 PanPDF is a self-contained local PDF toolbox based on Stirling PDF 2.11.0,
 rebranded as Pan PDF. It runs without registration/login and includes the
 full web UI with a bundled JRE and systemd service.
Homepage: https://github.com/ActiveInAI/PanPDF
EOF

  cat > "$work/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if ! getent passwd panpdf >/dev/null 2>&1; then
  useradd --system --home /opt/panpdf --shell /usr/sbin/nologin panpdf
fi
chown -R panpdf:panpdf /opt/panpdf
mkdir -p /opt/panpdf/tmp /opt/panpdf/logs /opt/panpdf/pipeline
chown -R panpdf:panpdf /opt/panpdf/tmp /opt/panpdf/logs /opt/panpdf/pipeline
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload >/dev/null 2>&1 || true
  systemctl enable panpdf.service >/dev/null 2>&1 || true
  systemctl start panpdf.service >/dev/null 2>&1 || true
fi
exit 0
EOF

  cat > "$work/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
if command -v systemctl >/dev/null 2>&1; then
  systemctl stop panpdf.service >/dev/null 2>&1 || true
  systemctl disable panpdf.service >/dev/null 2>&1 || true
fi
exit 0
EOF

  chmod 755 "$work/DEBIAN/postinst" "$work/DEBIAN/prerm"
  dpkg-deb --build --root-owner-group "$work" "$OUT/$pkg.deb"
  echo "Built $OUT/$pkg.deb"
}

make_deb amd64 "$BUILD/jre-linux-x64"
make_deb arm64 "$BUILD/jres/jre-linux-aarch64"

# ---- Windows portable package ----
WROOT="$(mktemp -d "${TMPDIR:-/tmp}/panpdf-win-XXXXXX")"
WIN="$WROOT/PanPDF"
mkdir -p "$WIN"
cp -r "$BUILD/app" "$WIN/app"
cp -r "$BUILD/configs" "$WIN/configs"
cp -r "$BUILD/customFiles" "$WIN/customFiles"
cp -r "$BUILD/jre-windows-x64" "$WIN/jre"
mkdir -p "$WIN/scripts"
sed 's/$/\r/' "$ROOT/packaging/windows/start-panpdf.bat" > "$WIN/scripts/start-panpdf.bat"
sed 's/$/\r/' "$ROOT/packaging/windows/stop-panpdf.ps1" > "$WIN/scripts/stop-panpdf.ps1"
sed 's/$/\r/' "$ROOT/packaging/windows/install-panpdf.ps1" > "$WIN/scripts/install-panpdf.ps1"
sed 's/$/\r/' "$ROOT/packaging/windows/PanPDF-README.txt" > "$WIN/README.txt"
mkdir -p "$WIN/tmp"

cd "$WROOT"
zip -qr "$OUT/PanPDF-windows-x64.zip" PanPDF
cd "$ROOT"
echo "Built $OUT/PanPDF-windows-x64.zip"

cd "$OUT"
sha256sum *.deb PanPDF-windows-x64.zip > SHA256SUMS.txt
echo "Checksums written to $OUT/SHA256SUMS.txt"
