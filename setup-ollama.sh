#!/bin/bash

# Ollama Setup Script für Scam Detector
# Automatisiert die Installation und Konfiguration von Ollama mit Llama3.2-vision

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Betriebssystem erkennen
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        print_error "Nicht unterstütztes Betriebssystem: $OSTYPE"
        exit 1
    fi
    print_status "Erkanntes OS: $OS"
}

# Ollama installieren
install_ollama() {
    print_status "Installiere Ollama..."
    
    if command -v ollama &> /dev/null; then
        print_warning "Ollama ist bereits installiert"
        ollama --version
        return 0
    fi
    
    case $OS in
        "linux"|"macos")
            curl -fsSL https://ollama.ai/install.sh | sh
            ;;
        "windows")
            print_status "Für Windows: Laden Sie Ollama von https://ollama.ai herunter"
            print_status "Oder verwenden Sie: winget install ollama"
            exit 1
            ;;
    esac
    
    if command -v ollama &> /dev/null; then
        print_success "Ollama erfolgreich installiert"
        ollama --version
    else
        print_error "Ollama Installation fehlgeschlagen"
        exit 1
    fi
}

# Ollama Service starten
start_ollama_service() {
    print_status "Starte Ollama Service..."
    
    # Prüfen ob bereits läuft
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "Ollama Service läuft bereits"
        return 0
    fi
    
    # Service starten
    case $OS in
        "linux")
            sudo systemctl start ollama || ollama serve &
            ;;
        "macos")
            brew services start ollama || ollama serve &
            ;;
        "windows")
            # Windows Service wird automatisch gestartet
            print_status "Windows Service sollte automatisch laufen"
            ;;
    esac
    
    # Warten bis Service verfügbar
    print_status "Warte auf Ollama Service..."
    for i in {1..30}; do
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            print_success "Ollama Service ist verfügbar"
            return 0
        fi
        sleep 2
    done
    
    print_error "Ollama Service konnte nicht gestartet werden"
    exit 1
}

# Llama3.2-vision Modell herunterladen
install_model() {
    print_status "Lade Llama3.2-vision Modell herunter..."
    
    # Prüfen ob Modell bereits vorhanden
    if ollama list | grep -q "llama3.2-vision"; then
        print_success "llama3.2-vision ist bereits verfügbar"
        ollama list | grep llama3.2
        return 0
    fi
    
    # Modell herunterladen
    print_status "Lade Modell herunter (dies kann einige Minuten dauern)..."
    ollama pull llama3.2-vision:latest
    
    if ollama list | grep -q "llama3.2-vision"; then
        print_success "llama3.2-vision erfolgreich heruntergeladen"
        ollama list | grep llama3.2
    else
        print_error "Modell-Download fehlgeschlagen"
        exit 1
    fi
}

# Modell testen
test_model() {
    print_status "Teste Llama3.2-vision Modell..."
    
    # Einfacher Test ohne Bild
    test_prompt="Respond with exactly: 'Model is working'"
    
    response=$(ollama run llama3.2-vision "$test_prompt" 2>/dev/null | head -1)
    
    if [[ "$response" == *"working"* ]]; then
        print_success "Modell funktioniert korrekt"
    else
        print_warning "Modell antwortet, aber möglicherweise nicht wie erwartet"
        print_status "Antwort: $response"
    fi
}

# Konfiguration optimieren
optimize_configuration() {
    print_status "Optimiere Ollama-Konfiguration..."
    
    # GPU-Unterstützung prüfen
    if command -v nvidia-smi &> /dev/null; then
        print_status "NVIDIA GPU erkannt - GPU-Acceleration verfügbar"
        export OLLAMA_GPU=1
    elif command -v rocm-smi &> /dev/null; then
        print_status "AMD GPU erkannt - ROCm-Acceleration verfügbar"
        export OLLAMA_GPU=1
    else
        print_warning "Keine GPU-Acceleration verfügbar - läuft auf CPU"
    fi
    
    # Memory-Einstellungen
    export OLLAMA_MAX_LOADED_MODELS=1
    export OLLAMA_NUM_PARALLEL=1
    export OLLAMA_MAX_QUEUE=10
    
    print_success "Konfiguration optimiert"
}

# API-Test
test_api() {
    print_status "Teste Ollama API..."
    
    # Basis-API Test
    api_response=$(curl -s http://localhost:11434/api/tags)
    
    if echo "$api_response" | grep -q "llama3.2-vision"; then
        print_success "API funktioniert - llama3.2-vision verfügbar"
    else
        print_error "API-Test fehlgeschlagen"
        print_status "API Response: $api_response"
        exit 1
    fi
    
    # Modell-spezifischer Test
    print_status "Teste Modell-API..."
    
    test_payload='{
        "model": "llama3.2-vision",
        "prompt": "Say hello",
        "stream": false,
        "options": {
            "temperature": 0.1,
            "num_predict": 10
        }
    }'
    
    model_response=$(curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "$test_payload")
    
    if echo "$model_response" | grep -q "response"; then
        print_success "Modell-API funktioniert korrekt"
    else
        print_warning "Modell-API antwortet ungewöhnlich"
        print_status "Response: $model_response"
    fi
}

# Systeminfo anzeigen
show_system_info() {
    print_status "System-Information:"
    echo "  OS: $OS"
    echo "  Ollama Version: $(ollama --version 2>/dev/null || echo 'Nicht installiert')"
    echo "  Verfügbare Modelle:"
    ollama list | grep -E "(NAME|llama)" || echo "  Keine Modelle gefunden"
    echo "  API Endpoint: http://localhost:11434"
    echo "  Status: $(curl -s http://localhost:11434/api/tags > /dev/null && echo 'Läuft' || echo 'Nicht verfügbar')"
}

# Service-Status
show_service_status() {
    print_status "Service-Status:"
    
    # Ollama Service
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        print_success "✅ Ollama Service läuft"
    else
        print_error "❌ Ollama Service nicht erreichbar"
    fi
    
    # Modell-Verfügbarkeit
    if ollama list | grep -q "llama3.2-vision"; then
        print_success "✅ llama3.2-vision verfügbar"
    else
        print_error "❌ llama3.2-vision nicht verfügbar"
    fi
    
    # GPU-Status
    if command -v nvidia-smi &> /dev/null; then
        print_success "✅ NVIDIA GPU verfügbar"
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader
    elif command -v rocm-smi &> /dev/null; then
        print_success "✅ AMD GPU verfügbar"
    else
        print_warning "⚠️  CPU-only Modus"
    fi
}

# Hauptfunktion
main() {
    echo "======================================"
    echo "  Ollama Setup für Scam Detector"
    echo "======================================"
    echo ""
    
    case "${1:-install}" in
        "install")
            detect_os
            install_ollama
            start_ollama_service
            install_model
            optimize_configuration
            test_model
            test_api
            show_system_info
            show_service_status
            ;;
        "start")
            start_ollama_service
            show_service_status
            ;;
        "test")
            test_model
            test_api
            ;;
        "status")
            show_service_status
            ;;
        "info")
            show_system_info
            ;;
        "help")
            echo "Verwendung: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  install    Vollständige Installation (Standard)"
            echo "  start      Nur Service starten"
            echo "  test       Modell und API testen"
            echo "  status     Service-Status anzeigen"
            echo "  info       System-Information anzeigen"
            echo "  help       Diese Hilfe anzeigen"
            ;;
        *)
            print_error "Unbekannter Befehl: $1"
            $0 help
            exit 1
            ;;
    esac
    
    print_success "Setup abgeschlossen!"
    echo ""
    echo "Nächste Schritte:"
    echo "  1. Backend starten: cd backend && python -m app.main"
    echo "  2. Frontend öffnen: http://localhost:8000"
    echo "  3. API testen: curl http://localhost:11434/api/tags"
}

# Script ausführen
main "$@"
