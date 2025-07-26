import asyncio
import base64
import io
import json
import os
import requests
from typing import Optional
from PIL import Image
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
import logging

# Logging konfigurieren
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Scam Detector API",
    description="KI-basierter Scam-Detector mit Ollama und Llama3.2-vision",
    version="1.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In Production spezifische Domains angeben
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Konfiguration
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
MODEL_NAME = "llama3.2-vision:11b"

class ScamAnalysisResponse(BaseModel):
    score: int
    explanation: str
    risk_level: str
    confidence: float

class OllamaService:
    def __init__(self):
        self.base_url = OLLAMA_BASE_URL
        self.model = MODEL_NAME
    
    async def check_ollama_connection(self) -> bool:
        """Prüft die Verbindung zu Ollama"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Ollama connection failed: {e}")
            return False
    
    async def analyze_image(self, image_base64: str) -> ScamAnalysisResponse:
        """Analysiert ein Bild auf Scam-Indikatoren"""
        
        prompt = """
Du bist ein Experte für die Erkennung von Online-Betrug und Scams. Analysiere das bereitgestellte Bild sorgfältig und bewerte es auf mögliche Betrugs-Indikatoren.

Achte besonders auf:
- Phishing-Versuche (gefälschte Login-Seiten, verdächtige URLs)
- Fake-Online-Shops (unrealistische Preise, unprofessionelles Design)
- Social Media Scams (gefälschte Profile, verdächtige Nachrichten)
- Tech-Support-Betrug (gefälschte Fehlermeldungen, Pop-ups)
- Investment-Betrug (unrealistische Gewinnversprechen)
- Romance Scams (verdächtige Dating-Profile)
- Finanzielle Betrugsversuche
- Grammatik- und Rechtschreibfehler
- Druck und Zeitlimits
- Ungewöhnliche Zahlungsmethoden

Gib deine Antwort im folgenden JSON-Format zurück:
{
    "score": <Nummer von 0-100, wobei 100 = definitiv Scam>,
    "explanation": "<Detaillierte Erklärung in deutscher Sprache>",
    "risk_level": "<NIEDRIG|MITTEL|HOCH|SEHR_HOCH>",
    "confidence": <Vertrauen in die Bewertung von 0.0-1.0>
}

Sei präzise und erkläre deine Bewertung nachvollziehbar.
"""

        try:
            payload = {
                "model": self.model,
                "prompt": prompt,
                "images": [image_base64],
                "stream": False,
                "options": {
                    "temperature": 0.3,
                    "top_p": 0.9,
                    "num_predict": 1000
                }
            }
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=300  # Timeout auf 5 Minuten erhöhen
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=500, 
                    detail=f"Ollama API Error: {response.status_code}"
                )
            
            result = response.json()
            ai_response = result.get("response", "")
            
            # JSON aus der Antwort extrahieren
            try:
                # Versuche JSON-Block zu finden
                start_idx = ai_response.find('{')
                end_idx = ai_response.rfind('}') + 1
                
                if start_idx == -1 or end_idx == 0:
                    raise ValueError("Kein JSON gefunden")
                
                json_str = ai_response[start_idx:end_idx]
                analysis = json.loads(json_str)
                
                return ScamAnalysisResponse(
                    score=max(0, min(100, analysis.get("score", 50))),
                    explanation=analysis.get("explanation", "Keine Erklärung verfügbar"),
                    risk_level=analysis.get("risk_level", "MITTEL"),
                    confidence=max(0.0, min(1.0, analysis.get("confidence", 0.5)))
                )
                
            except (json.JSONDecodeError, ValueError) as e:
                logger.error(f"JSON parsing error: {e}")
                # Fallback-Antwort
                return ScamAnalysisResponse(
                    score=50,
                    explanation="Die KI-Analyse konnte nicht vollständig verarbeitet werden. Bitte versuchen Sie es erneut.",
                    risk_level="MITTEL",
                    confidence=0.3
                )
                
        except requests.RequestException as e:
            logger.error(f"Request error: {e}")
            raise HTTPException(
                status_code=503, 
                detail="Ollama Service nicht verfügbar"
            )

# Service initialisieren
ollama_service = OllamaService()

@app.get("/")
async def root():
    return {"message": "Scam Detector API ist aktiv"}

@app.get("/health")
async def health_check():
    """Health Check Endpoint"""
    ollama_status = await ollama_service.check_ollama_connection()
    
    return {
        "status": "healthy" if ollama_status else "degraded",
        "ollama_connected": ollama_status,
        "model": MODEL_NAME
    }

@app.post("/analyze", response_model=ScamAnalysisResponse)
async def analyze_screenshot(file: UploadFile = File(...)):
    """Analysiert einen Screenshot auf Scam-Indikatoren"""
    
    # Dateivalidierung
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400, 
            detail="Nur Bilddateien sind erlaubt"
        )
    
    # Dateigröße prüfen (max 10MB)
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=400, 
            detail="Datei zu groß (max 10MB)"
        )
    
    try:
        # Bild verarbeiten
        image = Image.open(io.BytesIO(contents))
        
        # Bild komprimieren falls nötig
        if image.size[0] > 1920 or image.size[1] > 1080:
            image.thumbnail((1920, 1080), Image.Resampling.LANCZOS)
        
        # Zu Base64 konvertieren
        buffer = io.BytesIO()
        format = image.format if image.format else 'PNG'
        image.save(buffer, format=format)
        image_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        
        # Ollama-Verbindung prüfen
        if not await ollama_service.check_ollama_connection():
            raise HTTPException(
                status_code=503, 
                detail="Ollama Service nicht verfügbar. Stellen Sie sicher, dass Ollama läuft und das llama3.2-vision Modell verfügbar ist."
            )
        
        # Analyse durchführen
        result = await ollama_service.analyze_image(image_base64)
        
        logger.info(f"Analyse durchgeführt - Score: {result.score}, Risk: {result.risk_level}")
        
        return result
        
    except Exception as e:
        logger.error(f"Analysis error: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Fehler bei der Bildanalyse: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True,
        log_level="info"
    )
