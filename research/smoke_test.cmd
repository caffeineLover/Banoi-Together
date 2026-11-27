@echo off
setlocal
call "%~dp0..\tools\MsvcEnvironment.cmd"
if errorlevel 1 exit /b %errorlevel%
pushd "%~dp0.."
if not exist research\smoke-build mkdir research\smoke-build
cl /nologo /W4 /WX /O2 /MT /LD research\module_stub.cpp /Fo:research\smoke-build\stub.obj /Fe:research\smoke-build\gamedll_x64_rwdi.dll
if errorlevel 1 goto failure
copy /y research\smoke-build\gamedll_x64_rwdi.dll research\smoke-build\engine_x64_rwdi.dll >nul
cl /nologo /W4 /WX /O2 /MT research\proxy_smoke.cpp /Fo:research\smoke-build\smoke.obj /Fe:research\smoke-build\proxy_smoke.exe /link advapi32.lib
if errorlevel 1 goto failure
research\smoke-build\proxy_smoke.exe "%CD%\poc\build\xinput1_3.dll" "%CD%\research\smoke-build"
set "smoke_result=%errorlevel%"
popd
exit /b %smoke_result%
:failure
popd
exit /b 1
