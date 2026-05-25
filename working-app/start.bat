@echo off
echo ==========================================
echo    Nexus Tracker - Starting Server
echo ==========================================
echo.

if not exist "server\node_modules" (
    echo Installing server dependencies...
    npm install --prefix server
    if errorlevel 1 (
        echo Failed to install dependencies.
        pause
        exit /b 1
    )
)

echo.
echo Starting server on http://localhost:5000
echo Press Ctrl+C to stop
echo.
node server/src/index.js

pause
