@echo off
setlocal
call "%~dp0..\tools\MsvcEnvironment.cmd"
if errorlevel 1 exit /b %errorlevel%
pushd "%~dp0"
if not exist build mkdir build
cl /nologo /std:c++17 /EHsc /W4 /WX /O2 /MT /LD quest_chat.cpp /Fo:build\quest_chat.obj /Fe:build\xinput1_3.dll /link /DEF:xinput.def bcrypt.lib
set "build_result=%errorlevel%"
popd
exit /b %build_result%
