@echo off
:: Vereinfachter Scam Detector Netzwerk-Starter

echo ===========================================
echo    🛡️ Scam Detector Netzwerk-Setup
echo ===========================================
echo.

:: Admin-Rechte prüfen
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ Keine Administrator-Rechte erkannt.
    echo    Firewall wird übersprungen.
    echo    Für automatische Firewall-Konfiguration als Administrator ausführen.
    echo.
    goto :skip_firewall
)

:: Firewall konfigurieren (nur wenn Admin)
echo 🔥 Konfiguriere Windows-Firewall...
netsh advfirewall firewall delete rule name="Scam Detector Web" >nul 2>&1
netsh advfirewall firewall delete rule name="Scam Detector API" >nul 2>&1
netsh advfirewall firewall add rule name="Scam Detector Web" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
netsh advfirewall firewall add rule name="Scam Detector API" dir=in action=allow protocol=TCP localport=8000 >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo ✅ Firewall-Regeln erstellt!
) else (
    echo ⚠️ Firewall-Konfiguration teilweise fehlgeschlagen.
)

:skip_firewall

echo.

:: Lokale IP anzeigen
echo 🌐 Ihre lokale IP-Adresse:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4" ^| findstr /V "127.0.0.1"') do (
    set ip=%%a
    set ip=!ip: =!
    echo    ➤ !ip!
)

echo.

:: Prüfe ob Docker läuft
echo 🐳 Prüfe Docker...
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker ist nicht verfügbar!
    echo    Installieren Sie Docker Desktop und starten Sie es.
    echo.
    goto :end
)

docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker läuft nicht!
    echo    Starten Sie Docker Desktop.
    echo.
    goto :end
)

echo ✅ Docker ist verfügbar!

:: Alte Container stoppen (falls vorhanden)
echo 🔄 Stoppe alte Container...
docker-compose down >nul 2>&1

:: Docker Container starten (nur die grundlegenden Services)
echo 🚀 Starte Scam Detector...
docker-compose -f docker-compose.simple.yml up -d

if %ERRORLEVEL% EQU 0 (
    echo ✅ Scam Detector gestartet!
    
    :: Warte kurz bis Services bereit sind
    echo ⏳ Warte auf Services...
    timeout /t 10 /nobreak >nul
    
    echo.
    echo 📱 Zugriff von anderen Geräten:
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4" ^| findstr /V "127.0.0.1"') do (
        set ip=%%a
        set ip=!ip: =!
        echo    🌐 Web-Interface: http://!ip!
        echo    🔌 API-Zugriff:   http://!ip!:8000
        goto :show_success
    )
    
    :show_success
    echo.
    echo 💡 Tipp: Öffnen Sie http://localhost um zu testen!
    
) else (
    echo ❌ Fehler beim Starten!
    echo.
    echo 🔍 Troubleshooting:
    echo    1. Prüfen Sie ob Ollama läuft: ollama serve
    echo    2. Prüfen Sie Docker-Logs: docker-compose logs
    echo    3. Starten Sie Docker Desktop neu
)

:end
echo.
echo Drücken Sie eine beliebige Taste zum Beenden...
pause >nul
