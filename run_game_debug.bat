@echo off
echo Starting Eagle Game (Debug Mode)
echo ================================
echo.

cd /d "%~dp0\exe"

echo Running game from: %CD%
echo.

Eagle1-86-32.console.exe

echo.
echo ================================
echo Game has exited.
echo Press any key to close this window...
pause > nul
