@echo off
setlocal
echo ==========================================
echo   Offline Downloader (Admin + Nginx)
echo ==========================================
echo.
echo This script requires:
echo  1. Internet Access
echo  2. Docker Desktop (to pull/save the Nginx image)
echo.

echo [1/2] Downloading Synapse Admin (Static)...
curl -L -o synapse-admin.tar.gz https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.11.1/synapse-admin-0.11.1.tar.gz

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Static download failed. Check internet connection.
    pause
    exit /b 1
)

echo.
echo [2/2] Downloading Nginx Docker Image...
echo      (If this fails, ensure Docker Desktop is running)
docker pull nginx:alpine
docker save -o nginx.tar nginx:alpine

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker pull/save failed.
    echo         You must use a machine with Docker installed to get the Nginx image.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Files ready for transfer:
echo   - synapse-admin.tar.gz (Static UI)
echo   - nginx.tar            (Web Server Image)
echo.
echo ==========================================
echo   INSTRUCTIONS FOR SERVER INSTALLATION
echo ==========================================
echo 1. Copy both files to your server's release directory.
echo.
echo 2. Load the Nginx image on the server:
echo    docker load -i nginx.tar
echo.
echo 3. Extract the Admin Panel files:
echo    mkdir -p data/synapse-admin
echo    tar -xzf synapse-admin.tar.gz -C data/synapse-admin --strip-components=1
echo.
echo 4. Run './configure.sh' to set up Nginx and start everything.
echo.
echo 5. Access at: http://YOUR_SERVER_IP/admin
echo.
pause
