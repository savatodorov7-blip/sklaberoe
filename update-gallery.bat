@echo off
setlocal
cd /d "%~dp0"

echo Updating the SKLA Beroe gallery manifest...
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "scripts\generate_gallery_manifest.ps1"
if errorlevel 1 goto generation_failed
goto success

:generation_failed
echo.
echo ERROR: The gallery manifest could not be generated.
echo Review the message above, correct the problem, and try again.
goto finish_error

:success
echo.
echo SUCCESS: assets\gallery\gallery-manifest.json was updated.
echo You can now commit and push the changes with GitHub Desktop.
echo.
pause
exit /b 0

:finish_error
echo.
pause
exit /b 1
