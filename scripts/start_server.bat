@echo off
:: Attendance Tracker - Web Server Launcher
:: Serves the built Flutter web app on http://localhost:8080
:: Place this file anywhere; it looks for build\web relative to the project root.

set "PROJECT_DIR=%~dp0.."
set "WEB_DIR=%PROJECT_DIR%\build\web"
set PORT=8080

if not exist "%WEB_DIR%\index.html" (
    echo [ERROR] build\web not found.
    echo Run this first:  flutter build web --release
    pause
    exit /b 1
)

:: Try Python 3
python --version >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Starting with Python on http://localhost:%PORT%
    start "" "http://localhost:%PORT%"
    python -m http.server %PORT% --directory "%WEB_DIR%"
    exit /b 0
)

:: Try py launcher (Windows Python launcher)
py --version >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Starting with py on http://localhost:%PORT%
    start "" "http://localhost:%PORT%"
    py -m http.server %PORT% --directory "%WEB_DIR%"
    exit /b 0
)

:: Try Node.js npx serve
npx --version >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Starting with npx serve on http://localhost:%PORT%
    start "" "http://localhost:%PORT%"
    npx serve "%WEB_DIR%" -l %PORT% --single
    exit /b 0
)

echo [ERROR] Neither Python nor Node.js found.
echo Install Python from https://python.org  OR  Node.js from https://nodejs.org
pause
exit /b 1
