# Windows-Firewall-Konfiguration für Scam Detector Netzwerk-Hosting
# Als Administrator ausführen!

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Configure", "Remove", "Status")]
    [string]$Action = "Configure",
    
    [Parameter(Mandatory=$false)]
    [int]$WebPort = 80,
    
    [Parameter(Mandatory=$false)]
    [int]$ApiPort = 8000,
    
    [Parameter(Mandatory=$false)]
    [int]$HttpsPort = 443
)

# Farben für Output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-LocalIPAddress {
    $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.IPAddress -ne "127.0.0.1" -and 
        $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual" 
    } | Select-Object -First 1
    return $ip.IPAddress
}

function Configure-Firewall {
    Write-ColorOutput "🔧 Konfiguriere Windows-Firewall für Scam Detector..." $Blue
    
    try {
        # Eingehende Regeln für Web-Interface
        Write-ColorOutput "📡 Erstelle Regel für Web-Interface (Port $WebPort)..." $Blue
        New-NetFirewallRule -DisplayName "Scam Detector - Web Interface" `
            -Direction Inbound `
            -Port $WebPort `
            -Protocol TCP `
            -Action Allow `
            -Profile Domain,Private `
            -Description "Ermöglicht Zugriff auf Scam Detector Web-Interface über lokales Netzwerk" `
            -ErrorAction Stop

        # Eingehende Regeln für API
        Write-ColorOutput "🔌 Erstelle Regel für API (Port $ApiPort)..." $Blue
        New-NetFirewallRule -DisplayName "Scam Detector - API" `
            -Direction Inbound `
            -Port $ApiPort `
            -Protocol TCP `
            -Action Allow `
            -Profile Domain,Private `
            -Description "Ermöglicht Zugriff auf Scam Detector API über lokales Netzwerk" `
            -ErrorAction Stop

        # Optional: HTTPS
        if ($HttpsPort -ne 80 -and $HttpsPort -ne $ApiPort) {
            Write-ColorOutput "🔒 Erstelle Regel für HTTPS (Port $HttpsPort)..." $Blue
            New-NetFirewallRule -DisplayName "Scam Detector - HTTPS" `
                -Direction Inbound `
                -Port $HttpsPort `
                -Protocol TCP `
                -Action Allow `
                -Profile Domain,Private `
                -Description "Ermöglicht sicheren HTTPS-Zugriff auf Scam Detector" `
                -ErrorAction Stop
        }

        # Optional: Docker-interne Kommunikation
        Write-ColorOutput "🐳 Erstelle Regel für Docker-Kommunikation..." $Blue
        New-NetFirewallRule -DisplayName "Scam Detector - Docker Internal" `
            -Direction Inbound `
            -LocalAddress 172.16.0.0/12 `
            -Protocol TCP `
            -Action Allow `
            -Profile Private `
            -Description "Ermöglicht Docker-interne Kommunikation für Scam Detector" `
            -ErrorAction Stop

        Write-ColorOutput "✅ Firewall-Regeln erfolgreich erstellt!" $Green
        
        # IP-Adresse anzeigen
        $localIP = Get-LocalIPAddress
        Write-ColorOutput "📍 Ihre lokale IP-Adresse: $localIP" $Green
        Write-ColorOutput "🌐 Zugriff von anderen Geräten:" $Green
        Write-ColorOutput "   Web-Interface: http://$localIP" $Green
        Write-ColorOutput "   API-Zugriff:   http://$localIP`:$ApiPort" $Green
        
        if ($HttpsPort -ne 80 -and $HttpsPort -ne $ApiPort) {
            Write-ColorOutput "   HTTPS:         https://$localIP`:$HttpsPort" $Green
        }
        
    } catch {
        Write-ColorOutput "❌ Fehler beim Konfigurieren der Firewall: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Remove-FirewallRules {
    Write-ColorOutput "🗑️ Entferne Scam Detector Firewall-Regeln..." $Yellow
    
    try {
        $rules = @(
            "Scam Detector - Web Interface",
            "Scam Detector - API", 
            "Scam Detector - HTTPS",
            "Scam Detector - Docker Internal"
        )
        
        foreach ($ruleName in $rules) {
            try {
                Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                Write-ColorOutput "   ✅ Entfernt: $ruleName" $Green
            } catch {
                Write-ColorOutput "   ⚠️ Nicht gefunden: $ruleName" $Yellow
            }
        }
        
        Write-ColorOutput "✅ Firewall-Regeln entfernt!" $Green
        
    } catch {
        Write-ColorOutput "❌ Fehler beim Entfernen: $($_.Exception.Message)" $Red
    }
}

function Show-FirewallStatus {
    Write-ColorOutput "📊 Scam Detector Firewall-Status:" $Blue
    Write-ColorOutput "=================================" $Blue
    
    # Firewall-Status allgemein
    $firewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled
    Write-ColorOutput "🔥 Windows Firewall Status:" $Blue
    $firewallStatus | Format-Table -AutoSize | Out-String | Write-Host
    
    # Scam Detector spezifische Regeln
    Write-ColorOutput "🛡️ Scam Detector Regeln:" $Blue
    try {
        $scamRules = Get-NetFirewallRule | Where-Object { 
            $_.DisplayName -like "*Scam Detector*" 
        } | Select-Object DisplayName, Enabled, Direction, Action
        
        if ($scamRules.Count -gt 0) {
            $scamRules | Format-Table -AutoSize | Out-String | Write-Host
        } else {
            Write-ColorOutput "   Keine Scam Detector Regeln gefunden" $Yellow
        }
    } catch {
        Write-ColorOutput "   Fehler beim Abrufen der Regeln" $Red
    }
    
    # Netzwerk-Informationen
    Write-ColorOutput "🌐 Netzwerk-Informationen:" $Blue
    $localIP = Get-LocalIPAddress
    $networkAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    Write-ColorOutput "   Lokale IP: $localIP" $Green
    Write-ColorOutput "   Adapter: $($networkAdapter.Name)" $Green
    
    # Port-Tests
    Write-ColorOutput "🔍 Port-Tests:" $Blue
    Test-PortAccess -Port $WebPort -Name "Web"
    Test-PortAccess -Port $ApiPort -Name "API"
}

function Test-PortAccess {
    param(
        [int]$Port,
        [string]$Name
    )
    
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        Write-ColorOutput "   ✅ Port $Port ($Name) ist verfügbar" $Green
    } catch {
        Write-ColorOutput "   ❌ Port $Port ($Name) ist belegt oder blockiert" $Red
    }
}

function Test-NetworkConnectivity {
    Write-ColorOutput "🔍 Teste Netzwerk-Konnektivität..." $Blue
    
    $localIP = Get-LocalIPAddress
    
    # Test lokale Ports
    $ports = @($WebPort, $ApiPort)
    foreach ($port in $ports) {
        try {
            $connection = Test-NetConnection -ComputerName $localIP -Port $port -WarningAction SilentlyContinue
            if ($connection.TcpTestSucceeded) {
                Write-ColorOutput "   ✅ Port $port erreichbar" $Green
            } else {
                Write-ColorOutput "   ❌ Port $port nicht erreichbar" $Red
            }
        } catch {
            Write-ColorOutput "   ⚠️ Port $port Test fehlgeschlagen" $Yellow
        }
    }
}

function Show-Help {
    Write-ColorOutput "🛡️ Scam Detector Firewall-Konfiguration" $Blue
    Write-ColorOutput "=======================================" $Blue
    Write-ColorOutput ""
    Write-ColorOutput "Verwendung:" $Blue
    Write-ColorOutput "  .\Configure-Firewall.ps1 [Parameter]" $Blue
    Write-ColorOutput ""
    Write-ColorOutput "Parameter:" $Blue
    Write-ColorOutput "  -Action       Configure|Remove|Status (Standard: Configure)" $Blue
    Write-ColorOutput "  -WebPort      Web-Interface Port (Standard: 80)" $Blue
    Write-ColorOutput "  -ApiPort      API Port (Standard: 8000)" $Blue
    Write-ColorOutput "  -HttpsPort    HTTPS Port (Standard: 443)" $Blue
    Write-ColorOutput ""
    Write-ColorOutput "Beispiele:" $Blue
    Write-ColorOutput "  .\Configure-Firewall.ps1                    # Standardkonfiguration" $Blue
    Write-ColorOutput "  .\Configure-Firewall.ps1 -Action Status     # Status anzeigen" $Blue
    Write-ColorOutput "  .\Configure-Firewall.ps1 -Action Remove     # Regeln entfernen" $Blue
    Write-ColorOutput "  .\Configure-Firewall.ps1 -WebPort 8080      # Anderen Port verwenden" $Blue
}

# Hauptlogik
Write-ColorOutput "🛡️ Scam Detector Firewall-Manager" $Blue
Write-ColorOutput "===================================" $Blue

# Administrator-Rechte prüfen
if (-not (Test-AdminRights)) {
    Write-ColorOutput "❌ Dieses Script muss als Administrator ausgeführt werden!" $Red
    Write-ColorOutput "   Rechtsklick auf PowerShell -> 'Als Administrator ausführen'" $Yellow
    exit 1
}

switch ($Action.ToLower()) {
    "configure" {
        Configure-Firewall
        Write-ColorOutput ""
        Test-NetworkConnectivity
        Write-ColorOutput ""
        Write-ColorOutput "🎉 Konfiguration abgeschlossen!" $Green
        Write-ColorOutput "   Ihr Scam Detector ist jetzt im Netzwerk verfügbar!" $Green
    }
    
    "remove" {
        Remove-FirewallRules
    }
    
    "status" {
        Show-FirewallStatus
        Write-ColorOutput ""
        Test-NetworkConnectivity
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-ColorOutput "❌ Unbekannte Aktion: $Action" $Red
        Show-Help
        exit 1
    }
}

Write-ColorOutput ""
Write-ColorOutput "💡 Tipp: Führen Sie 'Configure-Firewall.ps1 -Action Status' aus, um den Status zu prüfen" $Blue
