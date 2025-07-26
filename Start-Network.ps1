# Scam Detector Netzwerk-Starter
# Automatisiert das Setup für Heimnetzwerk-Hosting

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Start", "Stop", "Restart", "Status", "Setup", "Configure")]
    [string]$Action = "Start",
    
    [Parameter(Mandatory=$false)]
    [switch]$OpenFirewall = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowQR = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Monitoring = $false
)

# Konfiguration
$WebPort = 80
$ApiPort = 8000
$ComposeFiles = @("docker-compose.yml", "docker-compose.network.yml")

# Farben
$Colors = @{
    Info = "Blue"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
}

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Colors[$Level]
}

function Test-Prerequisites {
    Write-Log "🔍 Prüfe Voraussetzungen..." "Info"
    
    # Docker prüfen
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Docker verfügbar: $dockerVersion" "Success"
        } else {
            throw "Docker nicht gefunden"
        }
    } catch {
        Write-Log "❌ Docker ist nicht installiert oder nicht verfügbar!" "Error"
        Write-Log "   Installieren Sie Docker Desktop von: https://docker.com" "Warning"
        return $false
    }
    
    # Docker Compose prüfen
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Docker Compose verfügbar: $composeVersion" "Success"
        } else {
            throw "Docker Compose nicht gefunden"
        }
    } catch {
        Write-Log "❌ Docker Compose ist nicht verfügbar!" "Error"
        return $false
    }
    
    # Ollama prüfen
    try {
        $ollamaTest = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 2>$null
        Write-Log "✅ Ollama läuft und ist erreichbar" "Success"
        
        # Modell prüfen
        $hasVisionModel = $ollamaTest.models | Where-Object { $_.name -like "*llama3.2-vision*" }
        if ($hasVisionModel) {
            Write-Log "✅ Llama3.2-vision Modell verfügbar" "Success"
        } else {
            Write-Log "⚠️ Llama3.2-vision Modell nicht gefunden" "Warning"
            Write-Log "   Führen Sie aus: ollama pull llama3.2-vision" "Warning"
        }
    } catch {
        Write-Log "⚠️ Ollama ist nicht erreichbar (http://localhost:11434)" "Warning"
        Write-Log "   Starten Sie Ollama oder führen Sie setup-ollama.sh aus" "Warning"
    }
    
    return $true
}

function Get-LocalIP {
    try {
        $ip = Get-NetIPAddress -AddressFamily IPv4 | 
              Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.PrefixOrigin -in @("Dhcp", "Manual") } |
              Select-Object -First 1
        return $ip.IPAddress
    } catch {
        return "127.0.0.1"
    }
}

function Start-ScamDetector {
    Write-Log "🚀 Starte Scam Detector für Netzwerk-Hosting..." "Info"
    
    if (-not (Test-Prerequisites)) {
        Write-Log "❌ Voraussetzungen nicht erfüllt. Abbruch." "Error"
        return
    }
    
    # Compose-Files Parameter erstellen
    $composeParams = @()
    foreach ($file in $ComposeFiles) {
        $composeParams += "-f"
        $composeParams += $file
    }
    
    # Optional: Monitoring Profile
    if ($Monitoring) {
        $composeParams += "--profile"
        $composeParams += "monitoring"
    }
    
    try {
        Write-Log "📦 Starte Docker Container..." "Info"
        $startProcess = Start-Process -FilePath "docker-compose" -ArgumentList ($composeParams + @("up", "-d")) -NoNewWindow -Wait -PassThru
        
        if ($startProcess.ExitCode -eq 0) {
            Write-Log "✅ Container erfolgreich gestartet!" "Success"
            
            # Warten auf Services
            Write-Log "⏳ Warte auf Service-Verfügbarkeit..." "Info"
            Start-Sleep -Seconds 15
            
            Show-NetworkInfo
            
        } else {
            Write-Log "❌ Fehler beim Starten der Container!" "Error"
        }
        
    } catch {
        Write-Log "❌ Fehler beim Ausführen von docker-compose: $($_.Exception.Message)" "Error"
    }
}

function Stop-ScamDetector {
    Write-Log "🛑 Stoppe Scam Detector..." "Info"
    
    $composeParams = @()
    foreach ($file in $ComposeFiles) {
        $composeParams += "-f"
        $composeParams += $file
    }
    
    try {
        $stopProcess = Start-Process -FilePath "docker-compose" -ArgumentList ($composeParams + @("down")) -NoNewWindow -Wait -PassThru
        
        if ($stopProcess.ExitCode -eq 0) {
            Write-Log "✅ Container erfolgreich gestoppt!" "Success"
        } else {
            Write-Log "❌ Fehler beim Stoppen der Container!" "Error"
        }
        
    } catch {
        Write-Log "❌ Fehler: $($_.Exception.Message)" "Error"
    }
}

function Show-Status {
    Write-Log "📊 Scam Detector Netzwerk-Status:" "Info"
    Write-Log "=================================" "Info"
    
    # Container Status
    Write-Log "🐳 Docker Container:" "Info"
    try {
        docker-compose -f docker-compose.yml -f docker-compose.network.yml ps
    } catch {
        Write-Log "   Fehler beim Abrufen der Container-Informationen" "Error"
    }
    
    # Service-Tests
    Write-Log "🔍 Service-Tests:" "Info"
    Test-Service -Url "http://localhost:$ApiPort/health" -Name "Backend API"
    Test-Service -Url "http://localhost:$WebPort/status" -Name "Frontend"
    
    # Netzwerk-Informationen
    Show-NetworkInfo
    
    # Logs anzeigen (letzte 10 Zeilen)
    Write-Log "📝 Aktuelle Logs (letzte 10 Zeilen):" "Info"
    try {
        docker-compose -f docker-compose.yml -f docker-compose.network.yml logs --tail=10
    } catch {
        Write-Log "   Fehler beim Abrufen der Logs" "Error"
    }
}

function Test-Service {
    param([string]$Url, [string]$Name)
    
    try {
        $response = Invoke-RestMethod -Uri $Url -TimeoutSec 5
        Write-Log "   ✅ $Name ist erreichbar" "Success"
    } catch {
        Write-Log "   ❌ $Name ist nicht erreichbar ($Url)" "Error"
    }
}

function Show-NetworkInfo {
    $localIP = Get-LocalIP
    
    Write-Log "🌐 Netzwerk-Zugriff:" "Success"
    Write-Log "=====================" "Success"
    Write-Log "📱 Web-Interface:     http://$localIP" "Success"
    Write-Log "🔌 API-Endpoint:      http://$localIP`:$ApiPort" "Success"
    Write-Log "📖 API-Dokumentation: http://$localIP`:$ApiPort/docs" "Success"
    Write-Log "❤️  Health-Check:     http://$localIP`:$ApiPort/health" "Success"
    
    if ($Monitoring) {
        Write-Log "📊 Monitoring:        http://$localIP`:9000 (admin/scamdetector)" "Success"
    }
    
    Write-Log "" "Info"
    Write-Log "💡 Teilen Sie diese URLs mit anderen Geräten in Ihrem Netzwerk!" "Info"
    
    # QR-Code anzeigen (falls angefordert)
    if ($ShowQR) {
        Show-QRCode -Url "http://$localIP"
    }
}

function Show-QRCode {
    param([string]$Url)
    
    Write-Log "📱 QR-Code für mobilen Zugriff:" "Info"
    Write-Log "Erstellen Sie einen QR-Code mit: $Url" "Info"
    Write-Log "Online QR-Generator: https://qr-code-generator.com" "Info"
}

function Setup-Environment {
    Write-Log "⚙️ Umgebung einrichten..." "Info"
    
    # Verzeichnisse erstellen
    $directories = @("./data/redis", "./logs/nginx")
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "✅ Verzeichnis erstellt: $dir" "Success"
        }
    }
    
    # .env Datei erstellen falls nicht vorhanden
    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Log "✅ .env Datei aus Vorlage erstellt" "Success"
        Write-Log "⚠️ Bitte prüfen und anpassen Sie die .env Datei!" "Warning"
    }
    
    # Firewall konfigurieren (falls angefordert)
    if ($OpenFirewall) {
        Write-Log "🔥 Konfiguriere Windows-Firewall..." "Info"
        try {
            & ".\Configure-Firewall.ps1" -Action Configure -WebPort $WebPort -ApiPort $ApiPort
            Write-Log "✅ Firewall konfiguriert!" "Success"
        } catch {
            Write-Log "⚠️ Firewall-Konfiguration fehlgeschlagen. Führen Sie Configure-Firewall.ps1 manuell aus." "Warning"
        }
    }
    
    Write-Log "✅ Umgebung eingerichtet!" "Success"
}

function Configure-Frontend {
    Write-Log "🎨 Konfiguriere Frontend für Netzwerk..." "Info"
    
    $localIP = Get-LocalIP
    $scriptPath = "./frontend/script.js"
    
    if (Test-Path $scriptPath) {
        # API-URL in script.js anpassen
        $scriptContent = Get-Content $scriptPath -Raw
        $newApiUrl = "http://$localIP`:$ApiPort"
        
        # Backup erstellen
        Copy-Item $scriptPath "$scriptPath.backup"
        
        # API-URL ersetzen
        $scriptContent = $scriptContent -replace "http://localhost:8000", $newApiUrl
        $scriptContent | Set-Content $scriptPath
        
        Write-Log "✅ Frontend API-URL angepasst: $newApiUrl" "Success"
    } else {
        Write-Log "⚠️ Frontend script.js nicht gefunden" "Warning"
    }
}

function Show-Help {
    Write-Log "🛡️ Scam Detector Netzwerk-Starter" "Info"
    Write-Log "==================================" "Info"
    Write-Log "" "Info"
    Write-Log "Verwendung: .\Start-Network.ps1 [Parameter]" "Info"
    Write-Log "" "Info"
    Write-Log "Parameter:" "Info"
    Write-Log "  -Action          Start|Stop|Restart|Status|Setup|Configure" "Info"
    Write-Log "  -OpenFirewall    Firewall automatisch konfigurieren" "Info"
    Write-Log "  -ShowQR          QR-Code-Informationen anzeigen" "Info"
    Write-Log "  -Monitoring      Monitoring-Tools aktivieren" "Info"
    Write-Log "" "Info"
    Write-Log "Beispiele:" "Info"
    Write-Log "  .\Start-Network.ps1                                    # Einfach starten" "Info"
    Write-Log "  .\Start-Network.ps1 -Action Setup -OpenFirewall        # Vollständiges Setup" "Info"
    Write-Log "  .\Start-Network.ps1 -Action Status                     # Status prüfen" "Info"
    Write-Log "  .\Start-Network.ps1 -Action Start -Monitoring -ShowQR  # Mit allem" "Info"
}

# Hauptlogik
Write-Log "🛡️ Scam Detector Netzwerk-Manager" "Info"
Write-Log "===================================" "Info"

switch ($Action.ToLower()) {
    "start" {
        if ($OpenFirewall) {
            Setup-Environment
        }
        Start-ScamDetector
    }
    
    "stop" {
        Stop-ScamDetector
    }
    
    "restart" {
        Stop-ScamDetector
        Start-Sleep -Seconds 5
        Start-ScamDetector
    }
    
    "status" {
        Show-Status
    }
    
    "setup" {
        Setup-Environment
        Configure-Frontend
        Write-Log "🎉 Setup abgeschlossen! Führen Sie jetzt 'Start' aus." "Success"
    }
    
    "configure" {
        Configure-Frontend
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-Log "❌ Unbekannte Aktion: $Action" "Error"
        Show-Help
    }
}

Write-Log "" "Info"
Write-Log "💡 Für Hilfe: .\Start-Network.ps1 -Action Help" "Info"
