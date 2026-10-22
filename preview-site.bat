@echo off
setlocal
cd /d "%~dp0"

echo Starting the SKLA Beroe local preview...
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "scripts\preview_site.ps1"
set "PREVIEW_EXIT_CODE=%ERRORLEVEL%"

if "%PREVIEW_EXIT_CODE%"=="0" exit /b 0

echo.
echo ERROR: The local preview server could not be started.
echo Review the message above, then close any program using port 8000 and try again.
echo.
pause
exit /b %PREVIEW_EXIT_CODE%
