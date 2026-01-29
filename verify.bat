@echo off
REM Verification script for Element X deployment bundle

echo.
echo ========================================
echo   Release Bundle Verification
echo ========================================
echo.

if not exist "release" (
    echo [ERROR] Release folder not found!
    echo Please run deploy.bat first.
    pause
    exit /b 1
)

echo Checking release folder contents...
echo.

REM Check docker-compose.yml
if exist "release\docker-compose.yml" (
    echo [OK] docker-compose.yml found
) else (
    echo [ERROR] docker-compose.yml missing!
    set ERROR=1
)

REM Check install_server.sh
if exist "release\install_server.sh" (
    echo [OK] install_server.sh found
) else (
    echo [ERROR] install_server.sh missing!
    set ERROR=1
)

echo.
echo ========================================
echo   Release Folder Contents:
echo ========================================
dir /B release
echo.

if defined ERROR (
    echo [FAILED] Some required files are missing!
    echo Please run deploy.bat again.
) else (
    echo [SUCCESS] Release bundle is complete and ready!
    echo.
    echo You can now transfer the 'release' folder to your server.
    echo.
    echo Transfer methods:
    echo   - USB drive
    echo   - SCP: scp -r release user@server:/opt/matrix
    echo   - WinSCP or any SFTP client
    echo.
    echo On the server, run:
    echo   cd /opt/matrix/release
    echo   chmod +x install_server.sh
    echo   sudo ./install_server.sh
)

echo.
pause
