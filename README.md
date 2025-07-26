# Scam Detector 🛡️

Ein KI-basiertes System zur Erkennung von Online-Betrug und verdächtigen Inhalten. Nutzt Ollama mit Llama3.2-vision für die Bildanalyse.

## Features ✨

- **KI-basierte Analyse**: Verwendet Llama3.2-vision für präzise Scam-Erkennung
- **Moderne Web-UI**: Responsive Design mit Drag & Drop Upload
- **Production-Ready**: Docker-basierte Bereitstellung mit Nginx
- **Umfassende Analyse**: Bewertung von 0-100 mit detaillierter Erklärung
- **Mehrere Scam-Typen**: Erkennt Phishing, Fake-Shops, Tech-Support-Betrug uvm.
- **Sicherheit**: Rate-Limiting, Eingabevalidierung, sichere Headers

## Voraussetzungen 📋

### Lokale Entwicklung
- Python 3.11+
- Node.js (optional, für Frontend-Entwicklung)
- Ollama mit Llama3.2-vision Modell

### Production Deployment
- Docker & Docker Compose
- Ollama (läuft auf Host-System)

## Installation & Setup 🚀

### 1. Ollama Setup

Installieren Sie Ollama von [ollama.ai](https://ollama.ai) und laden Sie das Modell:

```bash
# Ollama installieren (je nach Betriebssystem)
curl -fsSL https://ollama.ai/install.sh | sh

# Llama3.2-vision Modell herunterladen
ollama pull llama3.2-vision

# Ollama Server starten (läuft auf Port 11434)
ollama serve
```

### 2. Projekt klonen/herunterladen

```bash
git clone <your-repo-url>
cd scam-detector
```

### 3. Lokale Entwicklung

#### Backend
```bash
cd backend
pip install -r requirements.txt
python -m app.main
```

Das Backend läuft auf: http://localhost:8000

#### Frontend
Öffnen Sie `frontend/index.html` direkt im Browser oder verwenden Sie einen lokalen Server:

```bash
cd frontend
python -m http.server 3000
# oder
npx serve .
```

### 4. Production mit Docker

```bash
# Alle Services starten
docker-compose up -d

# Oder nur Haupt-Services (ohne Monitoring)
docker-compose up -d scam-detector-api nginx

# Logs anzeigen
docker-compose logs -f scam-detector-api

# Services stoppen
docker-compose down
```

Die Anwendung ist verfügbar unter:
- Frontend: http://localhost
- Backend API: http://localhost:8000
- API Dokumentation: http://localhost:8000/docs

## Konfiguration ⚙️

### Umgebungsvariablen

#### Backend (.env oder docker-compose.yml)
```env
OLLAMA_BASE_URL=http://localhost:11434  # Ollama Server URL
MODEL_NAME=llama3.2-vision              # Verwendetes Modell
LOG_LEVEL=INFO                          # Logging Level
```

#### Frontend (script.js)
```javascript
// API Base URL anpassen
this.apiBaseUrl = 'http://localhost:8000';
```

### Nginx Konfiguration

Passen Sie `nginx.conf` für produktive Verwendung an:
- SSL-Zertifikate konfigurieren
- Domain-spezifische Einstellungen
- Rate-Limiting anpassen

## API Dokumentation 📚

### Endpoints

#### `GET /health`
Health Check für Service-Status

**Response:**
```json
{
  "status": "healthy",
  "ollama_connected": true,
  "model": "llama3.2-vision"
}
```

#### `POST /analyze`
Bildanalyse für Scam-Erkennung

**Request:**
- Content-Type: `multipart/form-data`
- Body: `file` (Bilddatei, max 10MB)

**Response:**
```json
{
  "score": 85,
  "explanation": "Das Bild zeigt eine verdächtige E-Mail mit...",
  "risk_level": "HOCH",
  "confidence": 0.92
}
```

### Risiko-Level
- `NIEDRIG`: Score 0-25
- `MITTEL`: Score 26-50  
- `HOCH`: Score 51-75
- `SEHR_HOCH`: Score 76-100

## Verwendung 💡

### Web-Interface

1. **Bild hochladen**: Ziehen Sie ein Bild in den Upload-Bereich oder klicken Sie auf "Datei auswählen"
2. **Vorschau prüfen**: Überprüfen Sie das hochgeladene Bild
3. **Analyse starten**: Klicken Sie auf "Analysieren"
4. **Ergebnis interpretieren**: Bewerten Sie Score, Risiko-Level und Erklärung

### Programmatische Nutzung

```python
import requests

# Bild analysieren
with open('suspicious_image.png', 'rb') as f:
    response = requests.post(
        'http://localhost:8000/analyze',
        files={'file': f}
    )
    result = response.json()
    print(f"Scam Score: {result['score']}/100")
```

## Entwicklung 🛠️

### Projektstruktur
```
scam-detector/
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   └── main.py         # Haupt-API Code
│   ├── requirements.txt    # Python Dependencies
│   └── Dockerfile         # Backend Container
├── frontend/              # Web Frontend
│   ├── index.html        # Haupt-HTML
│   ├── styles.css        # CSS Styling
│   └── script.js         # JavaScript Logic
├── docker-compose.yml    # Container Orchestrierung
├── nginx.conf           # Webserver Konfiguration
└── README.md           # Diese Datei
```

### Code-Style

#### Python (Backend)
- PEP 8 Standards
- Type Hints verwenden
- Async/Await für I/O Operations
- Structured Logging

#### JavaScript (Frontend)
- ES6+ Features
- Modular Classes
- Error Handling
- Accessibility Features

### Testing

```bash
# Backend Tests
cd backend
pytest

# Frontend Tests (falls implementiert)
cd frontend
npm test
```

## Monitoring & Logging 📊

### Production Monitoring

Aktivieren Sie das Monitoring-Stack:

```bash
# Mit Prometheus & Grafana
docker-compose --profile monitoring up -d

# Zugriff:
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin)
```

### Logs

```bash
# Backend Logs
docker-compose logs -f scam-detector-api

# Nginx Logs
docker-compose logs -f nginx

# Alle Logs
docker-compose logs -f
```

## Sicherheit 🔒

### Implementierte Maßnahmen
- **Input Validation**: Dateityp und -größe Prüfung
- **Rate Limiting**: Schutz vor Missbrauch
- **CORS Policy**: Kontrollierte Cross-Origin Requests
- **Security Headers**: XSS, Clickjacking Schutz
- **No Data Storage**: Bilder werden nicht gespeichert

### Produktive Bereitstellung
- HTTPS einrichten (SSL-Zertifikate)
- Firewall konfigurieren
- Regular Updates
- Backup-Strategien

## Troubleshooting 🔧

### Häufige Probleme

#### "Ollama Service nicht verfügbar"
```bash
# Ollama Status prüfen
ollama list

# Modell verfügbar?
ollama pull llama3.2-vision

# Server läuft?
curl http://localhost:11434/api/tags
```

#### "Backend nicht erreichbar"
```bash
# Container Status
docker-compose ps

# Backend Logs
docker-compose logs scam-detector-api

# Netzwerk prüfen
docker network ls
```

#### Langsame Analyse
- GPU-Unterstützung für Ollama aktivieren
- Mehr RAM für Docker zuweisen
- Modell-Parameter optimieren

### Performance Optimierung

#### Ollama
```bash
# GPU-Unterstützung (NVIDIA)
docker run --gpus all ollama/ollama

# Mehr RAM zuweisen
OLLAMA_HOST=0.0.0.0:11434 OLLAMA_MODELS=/path/to/models ollama serve
```

#### Backend
- Gunicorn Worker erhöhen
- Redis Caching implementieren
- Bild-Komprimierung optimieren

## Contributing 🤝

1. Fork das Repository
2. Feature Branch erstellen (`git checkout -b feature/amazing-feature`)
3. Änderungen committen (`git commit -m 'Add amazing feature'`)
4. Branch pushen (`git push origin feature/amazing-feature`)
5. Pull Request erstellen

## License 📄

Dieses Projekt steht unter der MIT License - siehe [LICENSE](LICENSE) für Details.

## Support & Kontakt 💬

- **Issues**: Verwenden Sie GitHub Issues für Bug Reports
- **Diskussionen**: GitHub Discussions für Fragen
- **Security**: Sicherheitsprobleme privat melden

## Roadmap 🗺️

### Geplante Features
- [ ] Multi-Sprachen Support
- [ ] API Rate Limiting per User
- [ ] Erweiterte Scam-Kategorien
- [ ] Batch-Verarbeitung
- [ ] Mobile App
- [ ] Plugin für Browser

### Verbesserungen
- [ ] Performance Optimierung
- [ ] Erweiterte Tests
- [ ] CI/CD Pipeline
- [ ] Kubernetes Deployment
- [ ] Erweiterte Monitoring

---

**Wichtiger Hinweis**: Diese Software dient als Hilfsmittel zur Scam-Erkennung. Die Ergebnisse sind Empfehlungen und keine Garantien. Bei verdächtigen Inhalten konsultieren Sie immer Sicherheitsexperten oder entsprechende Behörden.
