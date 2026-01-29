@echo off
REM Element X Home Server - Deployment Script
REM This script prepares the installation bundle for your Matrix Synapse server

echo.
echo ========================================
echo   Element X Home Server Deployment
echo ========================================
echo.

REM Check for Git
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Git is not installed or not in PATH
    echo Please install Git and try again
    pause
    exit /b 1
)

REM Create release directory
if not exist "release" (
    echo [INFO] Creating release directory...
    mkdir release
)

REM Generate docker-compose.yml
echo [INFO] Generating docker-compose.yml...
(
echo version: '3.3'
echo.
echo services:
echo   synapse:
echo     image: matrixdotorg/synapse:latest
echo     container_name: synapse
echo     restart: unless-stopped
echo     ports:
echo       - 8008:8008
echo     volumes:
echo       - ./data:/data
echo     environment:
echo       - SYNAPSE_SERVER_NAME=matrix.local
echo       - SYNAPSE_REPORT_STATS=no
) > release\docker-compose.yml
echo [OK] docker-compose.yml created

REM Copy install script
if exist "install_server.sh" (
    copy /Y install_server.sh release\ >nul
    echo [OK] install_server.sh copied to release folder
) else (
    echo [WARN] install_server.sh not found in current directory
)

REM Copy configure script
if exist "configure.sh" (
    copy /Y configure.sh release\ >nul
    echo [OK] configure.sh copied to release folder
) else (
    echo [WARN] configure.sh not found in current directory
)

REM Ask about cloning Synapse (optional)
echo.
echo [?] Do you want to clone the Synapse source code?
echo     (Optional - only needed for custom builds, not required for Docker deployment)
echo.
set /P CLONE_CHOICE="Clone Synapse? (y/N): "

if /I "%CLONE_CHOICE%"=="y" (
    if exist "release\synapse" (
        echo [INFO] Synapse repository exists. Updating...
        cd release\synapse
        git pull
        cd ..\..
        if %ERRORLEVEL% EQU 0 (
            echo [OK] Synapse repository updated
        ) else (
            echo [WARN] Update failed, but continuing...
        )
    ) else (
        echo [INFO] Cloning Synapse repository - this may take 5-10 minutes...
        git clone https://github.com/element-hq/synapse.git release\synapse
        if %ERRORLEVEL% EQU 0 (
            echo [OK] Synapse repository cloned
        ) else (
            echo [ERROR] Clone failed, but the Docker deployment will still work
        )
    )
) else (
    echo [SKIP] Skipping Synapse source code clone
)

echo.
echo ========================================
echo   Bundle Preparation Complete!
echo ========================================
echo.
echo The 'release' folder is ready to transfer to your Linux server.
echo.
echo Contents:
dir /B release
echo.
echo Next steps:
echo 1. Copy the 'release' folder to your Linux server
echo 2. On the server, run: chmod +x *.sh ^&^& sudo ./install_server.sh
echo 3. After installation, run: sudo ./configure.sh (for easy setup)
echo.
pause
