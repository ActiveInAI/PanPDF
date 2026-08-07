$ErrorActionPreference = 'SilentlyContinue'
Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
  Where-Object { $_.CommandLine -like '*stirling.software.SPDF.SPDFApplication*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Write-Host 'PanPDF stopped (if it was running).'
