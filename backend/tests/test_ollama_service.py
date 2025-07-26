import pytest
import requests
import json
from unittest.mock import Mock, patch, MagicMock
from app.main import OllamaService

class TestOllamaServiceUnit:
    """Unit Tests für den Ollama Service"""
    
    @pytest.fixture
    def ollama_service(self):
        """Fixture für OllamaService"""
        return OllamaService()
    
    def test_init(self, ollama_service):
        """Test der Initialisierung"""
        assert ollama_service.base_url == "http://localhost:11434"
        assert ollama_service.model == "llama3.2-vision"
    
    @pytest.mark.asyncio
    async def test_check_connection_timeout(self, ollama_service):
        """Test Timeout-Behandlung"""
        with patch('requests.get') as mock_get:
            mock_get.side_effect = requests.Timeout("Timeout")
            
            result = await ollama_service.check_ollama_connection()
            assert result is False
    
    @pytest.mark.asyncio
    async def test_analyze_image_network_error(self, ollama_service):
        """Test Netzwerk-Fehler bei Bildanalyse"""
        with patch('requests.post') as mock_post:
            mock_post.side_effect = requests.ConnectionError("Network error")
            
            with pytest.raises(Exception):
                await ollama_service.analyze_image("test_image")
    
    @pytest.mark.asyncio
    async def test_analyze_image_malformed_json(self, ollama_service):
        """Test fehlerhaftes JSON in Antwort"""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": '{"score": "not_a_number", "explanation": "test"}'
            }
            mock_post.return_value = mock_response
            
            result = await ollama_service.analyze_image("test_image")
            
            # Sollte Fallback-Werte verwenden
            assert result.score == 50
            assert result.confidence == 0.3
    
    @pytest.mark.asyncio
    async def test_analyze_image_empty_response(self, ollama_service):
        """Test leere Antwort"""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"response": ""}
            mock_post.return_value = mock_response
            
            result = await ollama_service.analyze_image("test_image")
            
            assert result.score == 50
            assert "konnte nicht vollständig verarbeitet werden" in result.explanation

class TestPromptConstruction:
    """Tests für Prompt-Konstruktion und KI-Interaktion"""
    
    @pytest.fixture
    def ollama_service(self):
        return OllamaService()
    
    @pytest.mark.asyncio
    async def test_prompt_includes_key_indicators(self, ollama_service):
        """Test dass der Prompt wichtige Scam-Indikatoren enthält"""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": '{"score": 70, "explanation": "test", "risk_level": "HOCH", "confidence": 0.8}'
            }
            mock_post.return_value = mock_response
            
            await ollama_service.analyze_image("test_image")
            
            # Prüfe dass der POST-Call gemacht wurde
            assert mock_post.called
            
            # Prüfe Prompt-Inhalt
            call_args = mock_post.call_args
            payload = call_args[1]['json']
            prompt = payload['prompt']
            
            # Wichtige Scam-Typen sollten im Prompt enthalten sein
            expected_terms = [
                "Phishing",
                "Fake-Online-Shops", 
                "Tech-Support-Betrug",
                "Investment-Betrug",
                "Romance Scams",
                "Grammatik- und Rechtschreibfehler"
            ]
            
            for term in expected_terms:
                assert term in prompt
    
    @pytest.mark.asyncio
    async def test_json_format_in_prompt(self, ollama_service):
        """Test dass JSON-Format im Prompt spezifiziert ist"""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": '{"score": 30, "explanation": "test", "risk_level": "MITTEL", "confidence": 0.6}'
            }
            mock_post.return_value = mock_response
            
            await ollama_service.analyze_image("test_image")
            
            call_args = mock_post.call_args
            payload = call_args[1]['json']
            prompt = payload['prompt']
            
            # JSON-Format sollte spezifiziert sein
            assert '"score":' in prompt
            assert '"explanation":' in prompt
            assert '"risk_level":' in prompt
            assert '"confidence":' in prompt

class TestResponseParsing:
    """Tests für die Antwort-Verarbeitung"""
    
    @pytest.fixture
    def ollama_service(self):
        return OllamaService()
    
    @pytest.mark.asyncio
    async def test_parse_valid_json_response(self, ollama_service):
        """Test Parsing einer gültigen JSON-Antwort"""
        test_response = {
            "score": 85,
            "explanation": "Das Bild zeigt eine verdächtige Phishing-E-Mail mit mehreren Indikatoren für Betrug.",
            "risk_level": "SEHR_HOCH", 
            "confidence": 0.95
        }
        
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": json.dumps(test_response)
            }
            mock_post.return_value = mock_response
            
            result = await ollama_service.analyze_image("test_image")
            
            assert result.score == 85
            assert result.explanation == test_response["explanation"]
            assert result.risk_level == "SEHR_HOCH"
            assert result.confidence == 0.95
    
    @pytest.mark.asyncio
    async def test_parse_json_with_extra_text(self, ollama_service):
        """Test Parsing von JSON mit zusätzlichem Text"""
        json_part = {
            "score": 60,
            "explanation": "Moderate Gefahr erkannt",
            "risk_level": "MITTEL",
            "confidence": 0.7
        }
        
        response_with_extra = f"""
        Hier ist meine Analyse des Bildes:
        
        {json.dumps(json_part)}
        
        Zusätzliche Erklärungen hier...
        """
        
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"response": response_with_extra}
            mock_post.return_value = mock_response
            
            result = await ollama_service.analyze_image("test_image")
            
            assert result.score == 60
            assert result.risk_level == "MITTEL"
            assert result.confidence == 0.7
    
    @pytest.mark.asyncio
    async def test_handle_score_out_of_bounds(self, ollama_service):
        """Test Behandlung von Scores außerhalb des gültigen Bereichs"""
        test_cases = [
            {"score": -10, "expected": 0},
            {"score": 150, "expected": 100},
            {"score": 0, "expected": 0},
            {"score": 100, "expected": 100}
        ]
        
        for test_case in test_cases:
            response_data = {
                "score": test_case["score"],
                "explanation": "Test",
                "risk_level": "MITTEL",
                "confidence": 0.5
            }
            
            with patch('requests.post') as mock_post:
                mock_response = Mock()
                mock_response.status_code = 200
                mock_response.json.return_value = {
                    "response": json.dumps(response_data)
                }
                mock_post.return_value = mock_response
                
                result = await ollama_service.analyze_image("test_image")
                
                assert 0 <= result.score <= 100
                # Da die Score-Begrenzung in ScamAnalysisResponse erfolgt
                # müssen wir das dort testen

class TestErrorHandling:
    """Tests für Fehlerbehandlung"""
    
    @pytest.fixture
    def ollama_service(self):
        return OllamaService()
    
    @pytest.mark.asyncio
    async def test_http_error_status_codes(self, ollama_service):
        """Test verschiedener HTTP-Fehlercodes"""
        error_codes = [400, 401, 403, 404, 500, 502, 503]
        
        for status_code in error_codes:
            with patch('requests.post') as mock_post:
                mock_response = Mock()
                mock_response.status_code = status_code
                mock_post.return_value = mock_response
                
                with pytest.raises(Exception):
                    await ollama_service.analyze_image("test_image")
    
    @pytest.mark.asyncio
    async def test_request_timeout(self, ollama_service):
        """Test Request-Timeout"""
        with patch('requests.post') as mock_post:
            mock_post.side_effect = requests.Timeout("Request timeout")
            
            with pytest.raises(Exception):
                await ollama_service.analyze_image("test_image")
    
    @pytest.mark.asyncio
    async def test_json_decode_error(self, ollama_service):
        """Test JSON-Decode-Fehler"""
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.side_effect = json.JSONDecodeError("Invalid JSON", "", 0)
            mock_post.return_value = mock_response
            
            with pytest.raises(Exception):
                await ollama_service.analyze_image("test_image")

class TestConfigurationOptions:
    """Tests für Konfigurationsoptionen"""
    
    def test_custom_base_url(self):
        """Test benutzerdefinierte Basis-URL"""
        import os
        
        # Temporär Umgebungsvariable setzen
        original_url = os.environ.get('OLLAMA_BASE_URL')
        os.environ['OLLAMA_BASE_URL'] = 'http://custom-ollama:11434'
        
        try:
            service = OllamaService()
            assert service.base_url == 'http://custom-ollama:11434'
        finally:
            # Umgebungsvariable zurücksetzen
            if original_url:
                os.environ['OLLAMA_BASE_URL'] = original_url
            elif 'OLLAMA_BASE_URL' in os.environ:
                del os.environ['OLLAMA_BASE_URL']
    
    @pytest.mark.asyncio
    async def test_model_configuration(self):
        """Test Modell-Konfiguration in Requests"""
        service = OllamaService()
        
        with patch('requests.post') as mock_post:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "response": '{"score": 50, "explanation": "test", "risk_level": "MITTEL", "confidence": 0.5}'
            }
            mock_post.return_value = mock_response
            
            await service.analyze_image("test_image")
            
            # Prüfe dass das richtige Modell verwendet wird
            call_args = mock_post.call_args
            payload = call_args[1]['json']
            assert payload['model'] == 'llama3.2-vision'
            assert 'temperature' in payload['options']
            assert 'top_p' in payload['options']

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
