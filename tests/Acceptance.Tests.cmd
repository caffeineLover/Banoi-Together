@echo off
setlocal
call "%~dp0..\tools\MsvcEnvironment.cmd"
if errorlevel 1 exit /b %errorlevel%
pushd "%~dp0.."
if not exist tests\.tmp mkdir tests\.tmp
cl /nologo /std:c++17 /EHsc /W4 /WX /O2 /MT tests\Acceptance.Tests.cpp /Fo:tests\.tmp\acceptance.obj /Fe:tests\.tmp\acceptance-tests.exe
if errorlevel 1 goto failure
tests\.tmp\acceptance-tests.exe
set "test_result=%errorlevel%"
popd
exit /b %test_result%
:failure
popd
exit /b 1
