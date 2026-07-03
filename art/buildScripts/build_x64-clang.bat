@echo off
color 0a
cd ../..
setlocal
set "HAXELIB_PATH=%cd%\.haxelib\"
echo BUILDING GAME WITH CLANG-CL/LLD (using local haxelib repo: %HAXELIB_PATH%)
haxelib run lime build windows -release -Dclang
endlocal
echo.
echo done.
pause
explorer.exe export\release\windows\bin
