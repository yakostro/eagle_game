@echo off
echo Creating Eagle Game Distribution Package...
echo.

REM Create distribution directory
if exist "distribution" rmdir /s /q "distribution"
mkdir "distribution"
mkdir "distribution\Eagle"

REM Copy game files (you'll need to export the release build first)
echo Copying game files...
if exist "exe\Eagle_Release.exe" (
    copy "exe\Eagle_Release.exe" "distribution\Eagle\"
    echo ✓ Game executable copied
) else (
    echo ✗ Release executable not found! Please export the release build first.
    echo   In Godot: Project -> Export -> Windows Desktop Release -> Export Project
    pause
    exit /b 1
)

REM Copy additional files if they exist
if exist "README_DISTRIBUTION.txt" copy "README_DISTRIBUTION.txt" "distribution\Eagle\README.txt"
if exist "CONTROLS.txt" copy "CONTROLS.txt" "distribution\Eagle\"

REM Create distribution info
echo Eagle - Soaring Adventure Game > "distribution\Eagle\game_info.txt"
echo Version: 1.0.0 >> "distribution\Eagle\game_info.txt"
echo. >> "distribution\Eagle\game_info.txt"
echo To play: Double-click Eagle_Release.exe >> "distribution\Eagle\game_info.txt"
echo. >> "distribution\Eagle\game_info.txt"
echo Controls: >> "distribution\Eagle\game_info.txt"
echo W/Up Arrow - Move Up >> "distribution\Eagle\game_info.txt"
echo S/Down Arrow - Move Down >> "distribution\Eagle\game_info.txt"
echo E - Eat Fish >> "distribution\Eagle\game_info.txt"
echo Space - Drop Fish >> "distribution\Eagle\game_info.txt"
echo H - Screech >> "distribution\Eagle\game_info.txt"

REM Create ZIP file (requires PowerShell)
echo Creating ZIP package...
powershell -command "Compress-Archive -Path 'distribution\Eagle\*' -DestinationPath 'Eagle_Game_v1.0.zip' -Force"

if exist "Eagle_Game_v1.0.zip" (
    echo.
    echo ✓ Distribution package created successfully!
    echo ✓ File: Eagle_Game_v1.0.zip
    echo.
    echo This ZIP file is ready to distribute to players.
    echo Players just need to extract and run Eagle_Release.exe
) else (
    echo ✗ Failed to create ZIP package
)

echo.
pause
