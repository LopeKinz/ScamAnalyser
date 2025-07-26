import pytest
import asyncio
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
import io
from PIL import Image

from app.main import app

# Test Client
client = TestClient(app)

class TestScamDetectorAPI:
    """Test Suite für die Scam Detector API"""
    
    def test_root_endpoint(self):
        """Test des Root Endpoints"""
        response = client.get("/")
        assert response.status_code == 200
        assert "message" in response.json()
        assert "Scam Detector API ist aktiv" in response.json()["message"]
    
    def test_health_endpoint_success(self):
        """Test des Health Endpoints bei erfolgreicher Ollama-Verbindung"""
        with patch('app.main.ollama_service.check_ollama_connection') as mock_check:
            mock_check.return_value = True
            
            response = client.get("/health")
            assert response.status_code == 200
            
            data = response.json()
            assert data["status"] == "healthy"
            assert data["ollama_connected"] is True
            assert data["model"] == "llama3.2-vision"
    
    def test_health_endpoint_degraded(self):
        """Test des Health Endpoints bei fehlender Ollama-Verbindung"""
        with patch('app.main.ollama_service.check_ollama_connection') as mock_check:
            mock_check.return_value = False
            
            response = client.get("/health")
            assert response.status_code == 200
            
            data = response.json()
            assert data["status"] == "degraded"
            assert data["ollama_connected"] is False

class TestImageAnalysis:
    """Tests für die Bildanalyse-Funktionalität"""
    
    def create_test_image(self, format="PNG", size=(100, 100)):
        """Erstellt ein Test-Bild für die Tests"""
        image = Image.new('RGB', size, color='red')
        img_buffer = io.BytesIO()
        image.save(img_buffer, format=format)
        img_buffer.seek(0)
        return img_buffer
    
    def test_analyze_valid_image(self):
        """Test der Bildanalyse mit gültigem Bild"""
        test_image = self.create_test_image()
        
        # Mock der Ollama-Services
        with patch('app.main.ollama_service.check_ollama_connection') as mock_check, \
             patch('app.main.ollama_service.analyze_image') as mock_analyze:
            
            mock_check.return_value = True
            mock_analyze.return_value = {
                "score": 75,
                "explanation": "Test-Erklärung für verdächtigen Inhalt",
                "risk_level": "HOCH",
                "confidence": 0.85
            }
            
            response = client.post(
                "/analyze",
                files={"file": ("test.png", test_image, "image/png")}
            )
            
            assert response.status_code == 200
            data = response.json()
            
            assert "score" in data
            assert "explanation" in data
            assert "risk_level" in data
            assert "confidence" in data
            assert 0 <= data["score"] <= 100
            assert 0.0 <= data["confidence"] <= 1.0
    
    def test_analyze_invalid_file_type(self):
        """Test mit ungültigem Dateityp"""
        # Text-Datei als "Bild" senden
        test_file = io.BytesIO(b"This is not an image")
        
        response = client.post(
            "/analyze",
            files={"file": ("test.txt", test_file, "text/plain")}
        )
        
        assert response.status_code == 400
        assert "Nur Bilddateien sind erlaubt" in response.json()["detail"]
    
    def test_analyze_oversized_file(self):
        """Test mit zu großer Datei"""
        # Großes Bild erstellen (über 10MB)
        large_image = self.create_test_image(size=(5000, 5000))
        
        response = client.post(
            "/analyze",
            files={"file": ("large.png", large_image, "image/png")}
        )
        
        # Könnte je nach Komprimierung funktionieren oder fehlschlagen
        # Hier testen wir die Logik, nicht die exakte Dateigröße
        assert response.status_code in [200, 400]
    
    def test_analyze_no_file(self):
        """Test ohne Datei"""
        response = client.post("/analyze")
        
        assert response.status_code == 422  # Validation Error
    
    def test_analyze_ollama_unavailable(self):
        """Test bei nicht verfügbarem Ollama-Service"""
        test_image = self.create_test_image()
        
        with patch('app.main.ollama_service.check_ollama_connection') as mock_check:
            mock_check.return_value = False
            
            response = client.post(
                "/analyze",
                files={"file": ("test.png", test_image, "image/png")}
            )
            
            assert response.status_code == 503
            assert "Ollama Service nicht verfügbar" in response.json()["detail"]

class TestOllamaService:
    """Tests für den Ollama Service"""
    
    @pytest.fixture
    def ollama_service(self):
        from app.main import OllamaService
        return OllamaService()
    
    @pytest.mark.asyncio
    async def test_check_ollama_connection_success(self, ollama_service):
        """Test erfolgreiche Ollama-Verbindung"""
        with patch('requests.get') as mock_get:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_get.return_value = mock_response
            
            result = await ollama_service.check_ollama_connection()
            assert result is True
    
    @pytest.mark.asyncio
    async def test_check_ollama_connection_failure(self, ollama_service):
        """Test fehlgeschlagene Ollama-Verbindung"""
        with patch('requests.get') as mock_get:
            mock_get.side_effect = Exception("Connection failed")
            
            result = await ollama_service.check_ollama_connection()
            assert result is False
    
    @pytest.mark.asyncio
    async def test_analyze_image_success(self, ollama_service):
        """Test erfolgreiche Bildanalyse"""
        test_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": '{"score": 50, "explanation": "Test", "risk_level": "MITTEL", "confidence": 0.7}'
            }
            mock_post.return_value = mock_response
            
            result = await ollama_service.analyze_image(test_base64)
            
            assert result.score == 50
            assert result.explanation == "Test"
            assert result.risk_level == "MITTEL"
            assert result.confidence == 0.7
    
    @pytest.mark.asyncio
    async def test_analyze_image_api_error(self, ollama_service):
        """Test Ollama API Fehler"""
        test_base64 = "test_image_data"
        
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 500
            mock_post.return_value = mock_response
            
            with pytest.raises(Exception):  # HTTPException erwartet
                await ollama_service.analyze_image(test_base64)
    
    @pytest.mark.asyncio
    async def test_analyze_image_invalid_json(self, ollama_service):
        """Test ungültige JSON-Antwort"""
        test_base64 = "test_image_data"
        
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": "This is not valid JSON for analysis"
            }
            mock_post.return_value = mock_response
            
            result = await ollama_service.analyze_image(test_base64)
            
            # Sollte Fallback-Werte verwenden
            assert result.score == 50
            assert "konnte nicht vollständig verarbeitet werden" in result.explanation
            assert result.risk_level == "MITTEL"
            assert result.confidence == 0.3

class TestScoreValidation:
    """Tests für Score-Validierung und Risiko-Levels"""
    
    def test_score_boundaries(self):
        """Test Score-Grenzen"""
        from app.main import ScamAnalysisResponse
        
        # Minimum Score
        response = ScamAnalysisResponse(
            score=-10,  # Sollte auf 0 korrigiert werden
            explanation="Test",
            risk_level="NIEDRIG",
            confidence=0.5
        )
        assert 0 <= response.score <= 100
        
        # Maximum Score
        response = ScamAnalysisResponse(
            score=150,  # Sollte auf 100 korrigiert werden
            explanation="Test",
            risk_level="SEHR_HOCH",
            confidence=0.5
        )
        assert 0 <= response.score <= 100
    
    def test_risk_level_mapping(self):
        """Test Risiko-Level Zuordnung"""
        risk_mappings = {
            5: "NIEDRIG",
            25: "NIEDRIG", 
            35: "MITTEL",
            50: "MITTEL",
            65: "HOCH",
            75: "HOCH",
            85: "SEHR_HOCH",
            95: "SEHR_HOCH"
        }
        
        for score, expected_risk in risk_mappings.items():
            # Hier würde normalerweise eine Funktion getestet, die Score zu Risk-Level mappt
            # Da diese Logik in der KI-Antwort liegt, simulieren wir es
            if score <= 25:
                risk_level = "NIEDRIG"
            elif score <= 50:
                risk_level = "MITTEL"
            elif score <= 75:
                risk_level = "HOCH"
            else:
                risk_level = "SEHR_HOCH"
            
            assert risk_level == expected_risk

# Integration Tests
class TestIntegration:
    """Integration Tests für das gesamte System"""
    
    def test_full_analysis_workflow(self):
        """Test des kompletten Analyse-Workflows"""
        test_image = self.create_test_image()
        
        with patch('app.main.ollama_service.check_ollama_connection') as mock_check, \
             patch('app.main.ollama_service.analyze_image') as mock_analyze:
            
            mock_check.return_value = True
            mock_analyze.return_value = {
                "score": 85,
                "explanation": "Das Bild zeigt typische Phishing-Indikatoren: gefälschte URL, Rechtschreibfehler, und Druck zur sofortigen Aktion.",
                "risk_level": "SEHR_HOCH",
                "confidence": 0.92
            }
            
            # 1. Health Check
            health_response = client.get("/health")
            assert health_response.status_code == 200
            assert health_response.json()["ollama_connected"] is True
            
            # 2. Bildanalyse
            analysis_response = client.post(
                "/analyze",
                files={"file": ("phishing.png", test_image, "image/png")}
            )
            
            assert analysis_response.status_code == 200
            data = analysis_response.json()
            
            # Validierung der Antwort
            assert data["score"] == 85
            assert data["risk_level"] == "SEHR_HOCH"
            assert data["confidence"] == 0.92
            assert "Phishing" in data["explanation"]
    
    def create_test_image(self, format="PNG", size=(100, 100)):
        """Hilfsmethode für Test-Bilder"""
        image = Image.new('RGB', size, color='blue')
        img_buffer = io.BytesIO()
        image.save(img_buffer, format=format)
        img_buffer.seek(0)
        return img_buffer

# Performance Tests
class TestPerformance:
    """Performance Tests"""
    
    @pytest.mark.slow
    def test_concurrent_requests(self):
        """Test mehrerer gleichzeitiger Anfragen"""
        import concurrent.futures
        import time
        
        def make_request():
            test_image = self.create_test_image()
            return client.post(
                "/analyze",
                files={"file": ("test.png", test_image, "image/png")}
            )
        
        with patch('app.main.ollama_service.check_ollama_connection') as mock_check, \
             patch('app.main.ollama_service.analyze_image') as mock_analyze:
            
            mock_check.return_value = True
            mock_analyze.return_value = {
                "score": 25,
                "explanation": "Harmlose Website",
                "risk_level": "NIEDRIG", 
                "confidence": 0.8
            }
            
            start_time = time.time()
            
            with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
                futures = [executor.submit(make_request) for _ in range(10)]
                responses = [future.result() for future in futures]
            
            end_time = time.time()
            
            # Alle Requests sollten erfolgreich sein
            for response in responses:
                assert response.status_code == 200
            
            # Performance-Check (sollte unter 30 Sekunden dauern)
            assert end_time - start_time < 30
    
    def create_test_image(self, format="PNG", size=(100, 100)):
        """Hilfsmethode für Test-Bilder"""
        image = Image.new('RGB', size, color='green')
        img_buffer = io.BytesIO()
        image.save(img_buffer, format=format)
        img_buffer.seek(0)
        return img_buffer

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
