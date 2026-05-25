@echo off
echo ==========================================
echo    Nexus Tracker - Starting Server
echo ==========================================
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed.
    echo Please download and install from: https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo Starting server...
echo This will open in your browser automatically
echo.

:: Start browser after 2 seconds
start "" /b cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:5000"

:: Start the server with Aiven PostgreSQL
node run-server.js

echo.
echo Server stopped.
pause
