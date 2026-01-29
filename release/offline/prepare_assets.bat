@echo off
setlocal
echo ==========================================
echo   Element X Offline Packager (Windows)
echo ==========================================
echo.
echo This script prepares all necessary files for an offline installation.
echo specific requirements:
echo  1. Internet Access
echo  2. Docker Desktop (to pull/save images)
echo.

if not exist assets mkdir assets

echo [1/3] Downloading Synapse Admin (Static UI)...
curl -L -o assets\synapse-admin.tar.gz https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.11.1/synapse-admin-0.11.1.tar.gz
if %ERRORLEVEL% NEQ 0 goto error

echo.
echo [2/3] Pulling & Saving Docker Images...

echo    - Nginx (Alpine)...
docker pull nginx:alpine
docker save -o assets\nginx_image.tar nginx:alpine
if %ERRORLEVEL% NEQ 0 goto error

echo    - Matrix Synapse (Latest)...
docker pull matrixdotorg/synapse:latest
docker save -o assets\synapse_image.tar matrixdotorg/synapse:latest
if %ERRORLEVEL% NEQ 0 goto error

echo.
echo [3/3] Copying Helper Scripts...
REM We assume the user will copy the entire 'offline' folder, so scripts are already there.

echo.
echo [SUCCESS] All assets run in 'assets\' folder.
echo.
echo INSTRUCTIONS:
echo 1. Copy the entire 'offline' folder to your air-gapped server.
echo 2. Run 'install_server.sh' on the server.
pause
exit /b 0

:error
echo.
echo [ERROR] A step failed. Please check your connection and Docker status.
pause
exit /b 1
