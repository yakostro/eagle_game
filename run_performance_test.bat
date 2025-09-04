@echo off
echo ========================================
echo    EAGLE GAME - PERFORMANCE MONITORING
echo ========================================
echo.
echo Starting Godot with performance monitoring...
echo.
echo CONTROLS:
echo   F1  - Print current performance stats
echo   F2  - Print detailed performance report
echo   F3  - Reset performance statistics
echo   F10 - Print detailed profiler analysis
echo.
echo Press Ctrl+C to stop the game
echo.
C:\GameDev\Godot_v4.2.2-stable_win64.exe --path "C:\GameDev\Eagle" --print-fps --gpu-profile
echo.
echo Game closed. Check the console output above for performance data.
pause
