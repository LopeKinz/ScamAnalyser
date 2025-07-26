# 🚀 EINFACHER START - Scam Detector im Heimnetzwerk

## ✅ Super einfache Lösung (3 Klicks!)

### 1. Als Administrator starten
**Rechtsklick auf `start-network.bat` → "Als Administrator ausführen"**

### 2. Fertig! 🎉
Das Script:
- ✅ Konfiguriert automatisch die Windows-Firewall
- ✅ Zeigt Ihre lokale IP-Adresse an
- ✅ Startet den Scam Detector für das ganze Netzwerk

### 3. Von anderen Geräten zugreifen
**Smartphone/Tablet/PC:** `http://IHRE_IP` im Browser öffnen

---

## 📁 Verfügbare Dateien

- **`start-network.bat`** - System starten (als Administrator)
- **`stop-network.bat`** - System stoppen  
- **`status.bat`** - Status prüfen

---

## 🔧 Was passiert automatisch?

1. **Firewall-Regeln erstellen:**
   - Port 80 (Web-Interface) öffnen
   - Port 8000 (API) öffnen

2. **Docker Container starten:**
   - Backend-API mit Ollama-Integration
   - Frontend-Webserver (Nginx)

3. **Netzwerk-Zugriff aktivieren:**
   - Alle Geräte im Heimnetzwerk können zugreifen

---

## 📱 Beispiel-Zugriff

**Wenn Ihre IP `192.168.1.100` ist:**
- Web-Interface: `http://192.168.1.100`
- API direkt: `http://192.168.1.100:8000`
- Health-Check: `http://192.168.1.100:8000/health`

---

## 🛠️ Troubleshooting

### Problem: "Zugriff verweigert"
➤ **Lösung:** Als Administrator ausführen

### Problem: "Docker nicht gefunden"  
➤ **Lösung:** Docker Desktop installieren und starten

### Problem: "Ollama API Error"
➤ **Lösung:** 
```cmd
ollama serve
ollama pull llama3.2-vision
```

### Problem: "Seite nicht erreichbar"
➤ **Lösung:** `status.bat` ausführen und IP prüfen

---

## 🔍 Status prüfen

**Einfach `status.bat` doppelklicken:**
- Zeigt alle Container an
- Zeigt Ihre IP-Adresse
- Testet API-Verbindungen
- Zeigt Logs

---

## 🛑 System stoppen

**Einfach `stop-network.bat` doppelklicken**

---

## 🎯 Das war's!

**Keine komplexen Befehle, keine PowerShell-Syntax - einfach klicken und läuft! 🚀**

**Tipp:** Bookmark `http://IHRE_IP` auf allen Geräten für schnellen Zugriff!
