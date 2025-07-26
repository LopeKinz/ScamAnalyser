#!/bin/bash

# Scam Detector Startup Script
# Verwendung: ./start.sh [development|production|stop]

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktionen
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

# Ollama prüfen
check_ollama() {
    print_status "Prüfe Ollama-Verbindung..."
    
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "Ollama läuft auf Port 11434"
        
        # Modell prüfen
        if curl -s http://localhost:11434/api/tags | grep -q "llama3.2-vision"; then
            print_success "llama3.2-vision Modell verfügbar"
        else
            print_warning "llama3.2-vision Modell nicht gefunden"
            print_status "Lade Modell herunter..."
            ollama pull llama3.2-vision
        fi
    else
        print_error "Ollama nicht erreichbar!"
        print_status "Stellen Sie sicher, dass Ollama läuft:"
        echo "  ollama serve"
        exit 1
    fi
}

# Docker prüfen
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker ist nicht installiert!"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose ist nicht installiert!"
        exit 1
    fi
    
    print_success "Docker ist verfügbar"
}

# Development Setup
start_development() {
    print_status "Starte Development-Umgebung..."
    
    check_ollama
    check_docker
    
    # .env Datei erstellen falls nicht vorhanden
    if [ ! -f .env ]; then
        print_status "Erstelle .env Datei..."
        cp .env.example .env
        print_warning "Bitte prüfen Sie die .env Datei und passen Sie sie an!"
    fi
    
    # Development Stack starten
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    
    print_success "Development-Umgebung gestartet!"
    echo ""
    echo "Verfügbare Services:"
    echo "  📱 Frontend:     http://localhost:3000"
    echo "  🔧 Backend API:  http://localhost:8000"
    echo "  📖 API Docs:     http://localhost:8000/docs"
    echo "  ❤️  Health:      http://localhost:8000/health"
    echo ""
    echo "Development Tools (falls aktiviert):"
    echo "  🗄️  PgAdmin:     http://localhost:5050"
    echo "  📧 MailHog:     http://localhost:8025"
    echo "  🔴 Redis UI:    http://localhost:8081"
    echo ""
    echo "Logs anzeigen:"
    echo "  docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f"
}

# Production Setup
start_production() {
    print_status "Starte Production-Umgebung..."
    
    check_ollama
    check_docker
    
    # Production Build
    docker-compose build
    docker-compose up -d
    
    print_success "Production-Umgebung gestartet!"
    echo ""
    echo "Verfügbare Services:"
    echo "  🌐 Anwendung:   http://localhost"
    echo "  🔧 Backend API: http://localhost:8000"
    echo "  📖 API Docs:    http://localhost:8000/docs"
    echo ""
    echo "Monitoring (falls aktiviert):"
    echo "  📊 Prometheus:  http://localhost:9090"
    echo "  📈 Grafana:     http://localhost:3000"
}

# Services stoppen
stop_services() {
    print_status "Stoppe alle Services..."
    
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
    docker-compose down
    
    print_success "Alle Services gestoppt!"
}

# Status anzeigen
show_status() {
    print_status "Service Status:"
    docker-compose ps
    
    echo ""
    print_status "Ollama Status:"
    curl -s http://localhost:11434/api/tags | jq '.[].name' 2>/dev/null || echo "Ollama nicht erreichbar"
}

# Logs anzeigen
show_logs() {
    print_status "Zeige Logs... (Ctrl+C zum Beenden)"
    docker-compose logs -f
}

# Health Check
health_check() {
    print_status "Führe Health Check durch..."
    
    echo "🔍 Ollama:"
    curl -s http://localhost:11434/api/tags > /dev/null && echo "  ✅ Erreichbar" || echo "  ❌ Nicht erreichbar"
    
    echo "🔍 Backend:"
    curl -s http://localhost:8000/health > /dev/null && echo "  ✅ Erreichbar" || echo "  ❌ Nicht erreichbar"
    
    echo "🔍 Frontend:"
    curl -s http://localhost > /dev/null && echo "  ✅ Erreichbar" || echo "  ❌ Nicht erreichbar"
}

# Hilfe anzeigen
show_help() {
    echo "Scam Detector - Startup Script"
    echo ""
    echo "Verwendung: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  development, dev    Starte Development-Umgebung"
    echo "  production, prod    Starte Production-Umgebung"
    echo "  stop               Stoppe alle Services"
    echo "  status             Zeige Service-Status"
    echo "  logs               Zeige Service-Logs"
    echo "  health             Führe Health Check durch"
    echo "  help               Zeige diese Hilfe"
    echo ""
    echo "Beispiele:"
    echo "  $0 development     # Entwicklung starten"
    echo "  $0 prod           # Production starten"
    echo "  $0 stop           # Alles stoppen"
    echo "  $0 health         # System prüfen"
}

# Hauptlogik
case "${1:-help}" in
    "development"|"dev")
        start_development
        ;;
    "production"|"prod")
        start_production
        ;;
    "stop")
        stop_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "health")
        health_check
        ;;
    "help"|*)
        show_help
        ;;
esac
