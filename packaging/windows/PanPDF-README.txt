PanPDF - Windows x64 (portable)
================================

1. Unzip this folder anywhere (e.g. C:\PanPDF).
2. Run scripts\start-panpdf.bat
3. Open http://localhost:8083 in your browser.

Optional install (Start Menu shortcut):
  Right-click scripts\install-panpdf.ps1 -> Run with PowerShell
  Or run:  powershell -ExecutionPolicy Bypass -File scripts\install-panpdf.ps1
  Add -DesktopShortcut to also create a desktop shortcut.

Stop:
  Close the console window, or run scripts\stop-panpdf.ps1

Notes:
- Java 21 JRE is bundled in jre\.
- Config: configs\settings.yml; branding overlay: customFiles\static\.
- Advanced PDF/Office/OCR features need LibreOffice, Ghostscript, qpdf,
  Tesseract etc. installed on the system (see https://github.com/ActiveInAI/PanPDF).
- Default port is 8083; override with environment variable PANPDF_PORT.
