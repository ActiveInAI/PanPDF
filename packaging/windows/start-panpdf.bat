@echo off
setlocal
cd /d "%~dp0.."
set "STIRLING_BASE_PATH=%CD%"
set "SECURITY_ENABLELOGIN=false"
set "DISABLE_ADDITIONAL_FEATURES=false"
set "SYSTEM_DEFAULTLOCALE=zh-CN"
if "%PANPDF_PORT%"=="" set "PANPDF_PORT=8083"
if not exist "%STIRLING_BASE_PATH%\tmp" mkdir "%STIRLING_BASE_PATH%\tmp"
echo Starting PanPDF at http://localhost:%PANPDF_PORT% ...
start "" /b powershell -NoProfile -Command "Start-Sleep -Seconds 8; Start-Process 'http://localhost:%PANPDF_PORT%'"
"%STIRLING_BASE_PATH%\jre\bin\java.exe" -Dfile.encoding=UTF-8 -Djava.io.tmpdir="%STIRLING_BASE_PATH%\tmp" -Dserver.port=%PANPDF_PORT% -cp "%STIRLING_BASE_PATH%\app\app.jar;%STIRLING_BASE_PATH%\app\lib\*" stirling.software.SPDF.SPDFApplication
