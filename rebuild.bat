@echo off
setlocal enabledelayedexpansion

set IMAGE_NAME=code-server:test
set CONTAINER_NAME=code-server
set VOLUME_NAME=code-server-vol

echo ========================================
echo  Rebuilding Code-Server Docker Image
echo ========================================
echo.

echo [1/5] Removing old container...
docker rm -f %CONTAINER_NAME% 2>nul
echo     Done.
echo.

echo [2/5] Removing old image...
docker rmi %IMAGE_NAME% 2>nul
echo     Done.
echo.

echo [3/5] Removing old volume...
docker volume rm %VOLUME_NAME% 2>nul
echo     Done.
echo.

echo [4/5] Building new image...
docker build -t %IMAGE_NAME% .
if errorlevel 1 (
    echo     Build FAILED!
    exit /b 1
)
echo     Done.
echo.

echo [5/5] Starting new container...
docker run -d ^
  --name %CONTAINER_NAME% ^
  -p 8080:8080 ^
  -v %VOLUME_NAME%:/home/coder ^
  -e PASSWORD=123 ^
  %IMAGE_NAME%
if errorlevel 1 (
    echo     Start FAILED!
    exit /b 1
)
echo     Done.
echo.

echo ========================================
echo  Build and Start Complete!
echo ========================================
echo.
echo Access code-server at: http://localhost:8080
echo.

pause
