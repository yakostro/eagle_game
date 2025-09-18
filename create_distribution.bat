@echo off
echo Creating The Last Eagle Distribution Package...
echo.

REM Create distribution directory
if exist "distribution" rmdir /s /q "distribution"
mkdir "distribution"
mkdir "distribution\The_Last_Eagle"

REM Copy game files (you'll need to export the release build first)
echo Copying game files...
if exist "exe\The_Last_Eagle.exe" (
    copy "exe\The_Last_Eagle.exe" "distribution\The_Last_Eagle\"
    echo ✓ Game executable copied
    
    REM Copy PCK file if it exists (for non-embedded builds)
    if exist "exe\The_Last_Eagle.pck" (
        copy "exe\The_Last_Eagle.pck" "distribution\The_Last_Eagle\"
        echo ✓ Game data file copied
    )
) else (
    echo ✗ Release executable not found! Please export the release build first.
    echo   In Godot: Project -> Export -> Windows Desktop Release -> Export Project
    pause
    exit /b 1
)

REM Copy additional files if they exist
if exist "README_DISTRIBUTION.txt" copy "README_DISTRIBUTION.txt" "distribution\The_Last_Eagle\README.txt"
if exist "CONTROLS.txt" copy "CONTROLS.txt" "distribution\The_Last_Eagle\"

REM Create distribution info
echo The Last Eagle - Soaring Adventure Game > "distribution\The_Last_Eagle\game_info.txt"
echo Version: 1.0.0 >> "distribution\The_Last_Eagle\game_info.txt"
echo. >> "distribution\The_Last_Eagle\game_info.txt"
echo To play: Double-click The_Last_Eagle.exe >> "distribution\The_Last_Eagle\game_info.txt"
echo. >> "distribution\The_Last_Eagle\game_info.txt"
echo Controls: >> "distribution\The_Last_Eagle\game_info.txt"
echo W/Up Arrow - Move Up >> "distribution\The_Last_Eagle\game_info.txt"
echo S/Down Arrow - Move Down >> "distribution\The_Last_Eagle\game_info.txt"
echo E - Eat Fish >> "distribution\The_Last_Eagle\game_info.txt"
echo Space - Drop Fish >> "distribution\The_Last_Eagle\game_info.txt"
echo H - Screech >> "distribution\The_Last_Eagle\game_info.txt"

REM Create ZIP file (requires PowerShell)
echo Creating ZIP package...
powershell -command "Compress-Archive -Path 'distribution\The_Last_Eagle\*' -DestinationPath 'The_Last_Eagle_v1.0.zip' -Force"

if exist "The_Last_Eagle_v1.0.zip" (
    echo.
    echo ✓ Distribution package created successfully!
    echo ✓ File: The_Last_Eagle_v1.0.zip
    echo.
    echo This ZIP file is ready to distribute to players.
    echo Players just need to extract and run The_Last_Eagle.exe
) else (
    echo ✗ Failed to create ZIP package
)

echo.
pause
