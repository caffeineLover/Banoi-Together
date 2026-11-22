@echo off
where cl.exe >nul 2>nul
if not errorlevel 1 exit /b 0
set "DIDE_VS_ROOT="
set "DIDE_VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%DIDE_VSWHERE%" for /f "usebackq tokens=*" %%I in (`"%DIDE_VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "DIDE_VS_ROOT=%%I"
if not defined DIDE_VS_ROOT if exist "C:\BuildTools2026\Common7\Tools\VsDevCmd.bat" set "DIDE_VS_ROOT=C:\BuildTools2026"
if not defined DIDE_VS_ROOT (
  echo ERROR: MSVC x64 build tools were not found. Install Visual Studio C++ build tools.
  exit /b 1
)
call "%DIDE_VS_ROOT%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 >nul
exit /b %errorlevel%
