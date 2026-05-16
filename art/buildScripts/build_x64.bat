@echo off
color 0a
cd ../..
setlocal
set "HAXELIB_PATH=%cd%\.haxelib\"
echo BUILDING GAME (using local haxelib repo: %HAXELIB_PATH%)
haxelib run lime build windows -release
endlocal
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin