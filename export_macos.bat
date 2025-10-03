@echo off
echo Exporting The Last Eagle for macOS...
echo.

REM Change to the project directory
cd /d "%~dp0"

REM Run Godot export command
"C:\GameDev\Godot_v4.2.2-stable_win64.exe" --headless --export-release "macOS" "exe/The_Last_Eagle_macOS.zip"

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✓ Export completed successfully!
    echo ✓ macOS build saved to: exe/The_Last_Eagle_macOS.zip
    echo.
    echo IMPORTANT NOTES FOR macOS DISTRIBUTION:
    echo - The exported .zip contains a .app bundle
    echo - Users need to extract the .zip and run the .app
    echo - The app is unsigned, so users may need to:
    echo   1. Right-click the .app and select "Open"
    echo   2. Or go to System Preferences ^> Security ^& Privacy and allow the app
    echo.
) else (
    echo ✗ Export failed with error code %ERRORLEVEL%
    echo Check the Godot console for detailed error messages.
)

pause

