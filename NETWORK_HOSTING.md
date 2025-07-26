# Scam Detector - Heimnetzwerk Hosting Guide

## 🏠 Lokales Netzwerk Setup

### Option 1: Einfaches Hosting (alle Geräte im Netzwerk)

#### Backend konfigurieren
1. **Backend IP ändern:**
   ```bash
   cd backend
   # Statt localhost, alle IPs erlauben
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

2. **Frontend API-URL anpassen:**
   ```javascript
   // In frontend/script.js ändern:
   this.apiBaseUrl = 'http://IHRE_PC_IP:8000';
   // Beispiel: this.apiBaseUrl = 'http://192.168.1.100:8000';
   ```

### Option 2: Docker Compose für Netzwerk

#### docker-compose.yml anpassen:
```yaml
version: '3.8'

services:
  scam-detector-api:
    build: ./backend
    ports:
      - "0.0.0.0:8000:8000"  # Alle Netzwerk-Interfaces
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "0.0.0.0:80:80"      # Web auf Port 80
      - "0.0.0.0:443:443"    # HTTPS auf Port 443 (optional)
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx-network.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped
```

### Ihre PC-IP herausfinden:

#### Windows:
```cmd
ipconfig | findstr IPv4
```

#### Linux/Mac:
```bash
ip addr show | grep inet
# oder
ifconfig | grep inet
```

### Zugriff von anderen Geräten:

Nach dem Setup können andere Geräte zugreifen:
- **Web-Interface:** `http://IHRE_PC_IP` (Port 80)
- **Direkte API:** `http://IHRE_PC_IP:8000`

Beispiel: `http://192.168.1.100`

---

## 🔧 Erweiterte Konfiguration

### Windows Firewall konfigurieren:

```powershell
# PowerShell als Administrator
New-NetFirewallRule -DisplayName "Scam Detector Web" -Direction Inbound -Port 80 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Scam Detector API" -Direction Inbound -Port 8000 -Protocol TCP -Action Allow
```

### Router Port-Forwarding (für externen Zugriff):

Falls Sie externen Zugriff wollen:
1. Router-Interface öffnen (meist `192.168.1.1`)
2. Port-Forwarding einrichten:
   - Port 80 → IHRE_PC_IP:80
   - Port 8000 → IHRE_PC_IP:8000

⚠️ **Sicherheitshinweis:** Nur mit HTTPS und Authentifizierung!

---

## 🚀 Produktions-Setup

### Mit Reverse Proxy (Empfohlen):

```nginx
# nginx-network.conf
server {
    listen 80;
    server_name _;
    
    # Frontend
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }
    
    # API Proxy
    location /api/ {
        proxy_pass http://scam-detector-api:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # Health Check
    location /health {
        proxy_pass http://scam-detector-api:8000/health;
    }
}
```

### Mit SSL/HTTPS (Sicher):

```bash
# Selbstsigniertes Zertifikat erstellen
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/selfsigned.key -out ssl/selfsigned.crt \
    -subj "/C=DE/ST=State/L=City/O=Organization/CN=scam-detector.local"
```

---

## 📱 Mobile & Geräte-Zugriff

### QR-Code für einfachen Zugriff:
Erstellen Sie einen QR-Code mit Ihrer lokalen URL:
`http://192.168.1.100` (Ihre IP)

### PWA Installation:
Auf Smartphones: "Zum Startbildschirm hinzufügen"

---

## 🔍 Troubleshooting

### Häufige Probleme:

#### 1. "Seite nicht erreichbar"
```bash
# Firewall prüfen
sudo ufw status  # Linux
Get-NetFirewallRule  # Windows PowerShell

# Service Status
docker-compose ps
curl http://localhost:8000/health
```

#### 2. "API nicht erreichbar"
```bash
# Backend Logs
docker-compose logs scam-detector-api

# Ollama Status
curl http://localhost:11434/api/tags
```

#### 3. "CORS Fehler"
Frontend script.js anpassen:
```javascript
// Vollständige URL verwenden
this.apiBaseUrl = 'http://192.168.1.100:8000';
```

---

## 🌐 Domain-Name Setup (Optional)

### Lokale Domain einrichten:

#### 1. Router DNS (Fritz!Box, etc.):
- `scam-detector.local` → `IHRE_PC_IP`

#### 2. Hosts-Datei (auf Client-Geräten):
```
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux/Mac: /etc/hosts
192.168.1.100 scam-detector.local
```

#### 3. mDNS/Bonjour (automatisch):
```bash
# Linux: Avahi installieren
sudo apt install avahi-daemon avahi-utils

# Service als "scam-detector.local" bewerben
```

---

## 📊 Monitoring & Logs

### Einfaches Monitoring:

```bash
# System-Status anzeigen
docker-compose ps
docker-compose logs -f

# Zugriffs-Logs
tail -f /var/log/nginx/access.log

# Performance überwachen
htop
iotop
```

### Automatisches Update-Script:

```bash
#!/bin/bash
# update-scam-detector.sh

cd /path/to/scam-detector
git pull
docker-compose build
docker-compose up -d
echo "Update completed: $(date)"
```

---

## ⚡ Performance-Optimierung

### Für mehrere Nutzer:

```yaml
# docker-compose.yml
services:
  scam-detector-api:
    deploy:
      replicas: 3  # Mehrere Backend-Instanzen
    environment:
      - WORKERS=4  # Mehr Worker-Prozesse
      
  redis:
    image: redis:alpine
    # Für Caching und Session-Management
```

### Hardware-Empfehlungen:
- **CPU:** Mindestens 4 Cores für Ollama
- **RAM:** 8GB+ (Ollama braucht viel Speicher)
- **Storage:** SSD empfohlen
- **Netzwerk:** Gigabit LAN für beste Performance

---

## 🎯 Quick Start Commands

```bash
# 1. Ihre IP herausfinden
hostname -I  # Linux
ipconfig  # Windows

# 2. Projekt starten
docker-compose up -d

# 3. Firewall öffnen (Linux)
sudo ufw allow 80
sudo ufw allow 8000

# 4. Zugriff testen
curl http://YOUR_IP/health
```

**Ihre Anwendung ist dann erreichbar unter:**
- `http://IHRE_IP` (Web-Interface)
- `http://IHRE_IP:8000` (API)

🎉 **Fertig!** Alle Geräte in Ihrem Netzwerk können jetzt auf den Scam Detector zugreifen!
