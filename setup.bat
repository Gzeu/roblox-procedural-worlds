@echo off
title roblox-procedural-worlds  [SETUP]
echo.
echo  ==========================================
echo   One-time setup
echo  ==========================================
echo.
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] Python not found.
    echo  Download from: https://python.org/downloads
    echo  Make sure to check "Add Python to PATH" during install!
    pause
    exit /b 1
)
echo  [1/2] Installing watchdog for live watch...
python -m pip install watchdog -q
echo  [2/2] Building .rbxlx...
python build.py
echo.
echo  ==========================================
echo   DONE! Open roblox-procedural-worlds.rbxlx
echo   in Roblox Studio.
echo  ==========================================
pause
