@echo off
REM Hytale Docker Server - Run Script
REM This script starts the Hytale server and attaches to it

echo Starting Hytale server...

REM Start the container in detached mode
docker-compose up -d

REM Wait a moment for the container to start
timeout /t 2 /nobreak > nul

REM Attach to the container
echo.
echo Attaching to Hytale server console...
echo Press Ctrl+P, Ctrl+Q to detach without stopping the server
echo.

docker attach hytale
