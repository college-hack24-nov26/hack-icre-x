@echo off
chcp 65001 >nul
title JJM Village Scraper Web UI
color 0B

cd /d "%~dp0"

echo.
echo ============================================================
echo   Jal Jeevan Mission & IMD Weather Forecasting Web UI
echo ============================================================
echo.
echo Starting web server on http://localhost:3000 ...
echo.

:: Check if server is already running
curl -s --connect-timeout 2 http://localhost:3000/api/states >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Web UI server is already active!
    goto OPEN_BROWSER
)

:: Start server in new window
start "JJM Village Scraper Server" cmd /k "node server.js"

:: Wait for readiness
timeout /t 2 /nobreak >nul

:OPEN_BROWSER
echo Opening browser at http://localhost:3000 ...
start "" http://localhost:3000

echo.
echo ============================================================
echo   Web UI is running at http://localhost:3000
echo   You can minimize this window.
echo ============================================================
echo.
pause
