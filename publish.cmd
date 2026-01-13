@echo off
setlocal enabledelayedexpansion

REM Get the current gh username
for /f "tokens=3" %%a in ('gh auth status 2^>nul ^| findstr /C:"Logged in to"') do set GH_USERNAME=%%a

REM If no username is found, exit
if "!GH_USERNAME!"=="" (
    echo No GitHub username found
    exit /b 1
)

REM Get a token from GitHub
for /f "delims=" %%a in ('gh auth token 2^>nul') do set GH_TOKEN=%%a

if "!GH_TOKEN!"=="" (
    echo Failed to get GitHub token
    exit /b 1
)

REM Login to GitHub Container Registry
docker login ghcr.io -u !GH_USERNAME! --password !GH_TOKEN!

if errorlevel 1 (
    echo Failed to login to GitHub Container Registry
    exit /b 1
)

REM Build the image
docker build -f Dockerfile -t hytale-server .

if errorlevel 1 (
    echo Failed to build image
    exit /b 1
)

REM Tag the image
docker tag hytale-server ghcr.io/machinastudios/hytale-server:latest

if errorlevel 1 (
    echo Failed to tag image
    exit /b 1
)

REM Push the image
docker push ghcr.io/machinastudios/hytale-server:latest

if errorlevel 1 (
    echo Failed to push image
    exit /b 1
)

echo Image published successfully!
