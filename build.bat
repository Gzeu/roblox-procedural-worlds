@echo off
title roblox-procedural-worlds builder
echo.
echo  ==========================================
echo   roblox-procedural-worlds  ^|  Auto Build
echo  ==========================================
echo.
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] Python not found.
    echo  Install Python from https://python.org
    pause
    exit /b 1
)
python build.py
echo.
echo  Double-click roblox-procedural-worlds.rbxlx to open in Studio.
pause
