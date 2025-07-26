# 🏠 SCHNELLSTART: Scam Detector im Heimnetzwerk

## ⚡ 1-Minute Setup

### Schritt 1: PowerShell als Administrator öffnen
```powershell
# Rechtsklick auf PowerShell -> "Als Administrator ausführen"
cd C:\Users\Acer Nitro V15\Documents\code\scam-detector
```

### Schritt 2: Firewall konfigurieren
```powershell
.\Configure-Firewall.ps1
```

### Schritt 3: Netzwerk-Hosting starten
```powershell
.\Start-Network.ps1 -Action Setup -OpenFirewall
.\Start-Network.ps1 -Action Start
```

### Schritt 4: Ihre IP herausfinden
```powershell
# Zeigt Ihre lokale IP an (z.B. 192.168.1.100)
ipconfig | findstr IPv4
```

### Schritt 5: Von anderen Geräten zugreifen
- **Smartphone/Tablet:** `http://IHRE_IP` (z.B. http://192.168.1.100)
- **Andere PCs:** `http://IHRE_IP` im Browser öffnen

---

## 🎯 Quick Commands

```powershell
# System starten
.\Start-Network.ps1

# Status prüfen  
.\Start-Network.ps1 -Action Status

# System stoppen
.\Start-Network.ps1 -Action Stop

# Firewall-Status
.\Configure-Firewall.ps1 -Action Status
```

---

## 📱 Für Familie/Mitbewohner

**Einfach diese URL teilen:**
- `http://192.168.1.XXX` (Ihre lokale IP)

**QR-Code erstellen:** 
- Gehen Sie zu: https://qr-code-generator.com
- URL eingeben: `http://IHRE_IP`
- QR-Code drucken/teilen

---

## 🔧 Erweiterte Optionen

### Mit Monitoring Dashboard:
```powershell
.\Start-Network.ps1 -Monitoring
# Zugriff: http://IHRE_IP:9000 (admin/scamdetector)
```

### Nur Backend-API nutzen:
```powershell
# Direkter API-Zugriff von anderen Apps:
curl http://IHRE_IP:8000/health
```

### HTTPS einrichten (optional):
```powershell
# SSL-Zertifikat erstellen
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/cert.key -out ssl/cert.crt
```

---

## 🛡️ Sicherheitshinweise

✅ **Sicher für Heimnetzwerk:**
- Zugriff nur aus lokalem Netzwerk
- Keine Daten werden gespeichert
- Firewall-Regeln nur für lokale IPs

⚠️ **Nicht empfohlen:**
- Port-Forwarding für Internet-Zugang
- Ohne HTTPS über Internet

---

## 🔍 Troubleshooting

### Problem: "Seite nicht erreichbar"
```powershell
# 1. Service-Status prüfen
.\Start-Network.ps1 -Action Status

# 2. Firewall prüfen
.\Configure-Firewall.ps1 -Action Status

# 3. IP-Adresse bestätigen
ipconfig
```

### Problem: "Ollama API Error"
```powershell
# Ollama starten
ollama serve

# Modell laden
ollama pull llama3.2-vision

# Testen
curl http://localhost:11434/api/tags
```

### Problem: "CORS Error" 
```powershell
# Frontend neu konfigurieren
.\Start-Network.ps1 -Action Configure
```

---

## 🚀 Performance-Tipps

- **RAM:** Mindestens 8GB für flüssigen Betrieb
- **CPU:** Mehr Cores = schnellere Analyse
- **Netzwerk:** Gigabit LAN für beste Performance
- **Speicher:** SSD empfohlen

---

## 📞 Support

Bei Problemen:
1. `.\Start-Network.ps1 -Action Status` ausführen
2. Log-Dateien in `./logs/` prüfen
3. Docker-Logs: `docker-compose logs`

---

**🎉 Fertig! Ihr Scam Detector läuft jetzt im gesamten Heimnetzwerk!**
