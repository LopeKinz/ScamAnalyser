@echo off
:: Vereinfachter Stop-Script

echo ===========================================
echo    🛑 Scam Detector stoppen  
echo ===========================================
echo.

echo 🔄 Stoppe Container...

:: Versuche beide möglichen Compose-Dateien
docker-compose -f docker-compose.simple.yml down 2>nul
docker-compose down 2>nul

echo ✅ Container gestoppt!

echo.
echo 🧹 Aufräumen...
docker system prune -f >nul 2>&1

echo ✅ Aufräumen abgeschlossen!

echo.
echo Drücken Sie eine beliebige Taste...
pause >nul
