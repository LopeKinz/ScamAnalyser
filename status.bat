@echo off
:: Vereinfachter Status-Check

echo ===========================================
echo    📊 Scam Detector Status
echo ===========================================
echo.

:: Docker Status
echo 🐳 Docker Status:
docker --version 2>nul
if %ERRORLEVEL% EQU 0 (
    echo    ✅ Docker installiert
) else (
    echo    ❌ Docker nicht gefunden
    goto :end
)

docker info >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    ✅ Docker läuft
) else (
    echo    ❌ Docker läuft nicht
    goto :end
)

echo.

:: Container Status
echo 🏃 Container Status:
docker-compose -f docker-compose.simple.yml ps 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo    ℹ️ Keine Container mit docker-compose.simple.yml gefunden
    docker ps -a --filter "name=scam-detector" 2>nul
)

echo.

:: IP-Adresse
echo 🌐 Netzwerk-Information:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4" ^| findstr /V "127.0.0.1"') do (
    set ip=%%a
    set ip=!ip: =!
    echo    📍 Ihre IP: !ip!
    echo    🌐 Web-Interface: http://!ip!
    echo    🔌 API-Endpoint: http://!ip!:8000
    goto :services
)

:services
echo.

:: Service Tests
echo 🔍 Service-Tests:

:: Test lokale Services
curl -s -m 5 http://localhost:8000/health >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    ✅ Backend API erreichbar (Port 8000)
) else (
    echo    ❌ Backend API nicht erreichbar
)

curl -s -m 5 http://localhost:80 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    ✅ Frontend erreichbar (Port 80)
) else (
    echo    ❌ Frontend nicht erreichbar
)

:: Test Ollama
curl -s -m 5 http://localhost:11434/api/tags >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    ✅ Ollama erreichbar (Port 11434)
) else (
    echo    ⚠️ Ollama nicht erreichbar - starten Sie: ollama serve
)

echo.

:: Firewall Status
echo 🔥 Firewall-Status:
netsh advfirewall firewall show rule name="Scam Detector Web" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    ✅ Web-Port (80) ist geöffnet
) else (
    echo    ⚠️ Web-Port (80) nicht konfiguriert
)

netsh advfirewall firewall show rule name="Scam Detector API" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    ✅ API-Port (8000) ist geöffnet  
) else (
    echo    ⚠️ API-Port (8000) nicht konfiguriert
)

:end
echo.
echo 💡 Tipp: Führen Sie start-network.bat als Administrator aus für vollständige Konfiguration
echo.
echo Drücken Sie eine beliebige Taste...
pause >nul
