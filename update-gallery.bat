@echo off
setlocal
cd /d "%~dp0"

echo Updating the SKLA Beroe gallery manifest...
echo.

py -3 --version >nul 2>nul
if errorlevel 1 goto use_python

py -3 "scripts\generate_gallery_manifest.py"
if errorlevel 1 goto generation_failed
goto success

:use_python
python --version >nul 2>nul
if errorlevel 1 goto python_missing

python "scripts\generate_gallery_manifest.py"
if errorlevel 1 goto generation_failed
goto success

:python_missing
echo ERROR: Python 3 was not found.
echo Install Python 3, then run this file again.
goto finish_error

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
