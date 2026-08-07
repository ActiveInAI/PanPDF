param(
    [switch]$DesktopShortcut
)
$ErrorActionPreference = 'Stop'

$src = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $env:LOCALAPPDATA 'PanPDF'

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
}
Copy-Item -Path (Join-Path $src '*') -Destination $dest -Recurse -Force

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
if (-not (Test-Path $startMenu)) {
    New-Item -ItemType Directory -Path $startMenu | Out-Null
}
$lnk = Join-Path $startMenu 'PanPDF.lnk'
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = Join-Path $dest 'scripts\start-panpdf.bat'
$sc.WorkingDirectory = Join-Path $dest 'scripts'
$sc.IconLocation = "$env:SystemRoot\System32\shell32.dll,13"
$sc.Description = 'PanPDF - local PDF toolbox'
$sc.Save()

if ($DesktopShortcut) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $dlnk = Join-Path $desktop 'PanPDF.lnk'
    $dsc = $ws.CreateShortcut($dlnk)
    $dsc.TargetPath = Join-Path $dest 'scripts\start-panpdf.bat'
    $dsc.WorkingDirectory = Join-Path $dest 'scripts'
    $dsc.IconLocation = "$env:SystemRoot\System32\shell32.dll,13"
    $dsc.Description = 'PanPDF - local PDF toolbox'
    $dsc.Save()
}

Write-Host "PanPDF installed to: $dest"
Write-Host 'Start it from the Start Menu: PanPDF'
Write-Host 'Default URL: http://localhost:8083'
