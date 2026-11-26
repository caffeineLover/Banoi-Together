@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Support - Do Not Run\Setup.ps1" %*
set "installer_result=%errorlevel%"
echo.
pause
exit /b %installer_result%
