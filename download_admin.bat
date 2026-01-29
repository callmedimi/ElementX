@echo off
setlocal
echo ==========================================
echo   Synapse Admin Downloader (Static)
echo ==========================================
echo.
echo 1. Downloading Synapse Admin 0.11.1...
curl -L -o synapse-admin.tar.gz https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.11.1/synapse-admin-0.11.1.tar.gz

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Download failed. Check internet.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Download complete: synapse-admin.tar.gz
echo.
echo ==========================================
echo   INSTRUCTIONS FOR SERVER INSTALLATION
echo ==========================================
echo 1. Copy 'synapse-admin.tar.gz' to your server.
echo.
echo 2. SSH into your server and run these commands:
echo    mkdir -p /var/www/synapse-admin
echo    tar -xzf synapse-admin.tar.gz -C /var/www/synapse-admin --strip-components=1
echo    chown -R www-data:www-data /var/www/synapse-admin
echo.
echo 3. Run './configure.sh' (choose 'y' for HTTPS/Proxy setup) to install Nginx.
echo.
echo 4. Access at: http://YOUR_SERVER_IP/admin
echo.
pause
