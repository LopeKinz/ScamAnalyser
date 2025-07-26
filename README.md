
# Scam Detector 🛡️

An AI-powered system for detecting online scams and suspicious content. Uses Ollama with Llama3.2-vision for image analysis.

## Features ✨

- **AI-Based Analysis**: Utilizes Llama3.2-vision for precise scam detection  
- **Modern Web UI**: Responsive design with drag & drop upload  
- **Production-Ready**: Docker-based deployment with Nginx  
- **Comprehensive Analysis**: Score from 0–100 with detailed explanation  
- **Multiple Scam Types**: Detects phishing, fake shops, tech support scams, and more  
- **Security**: Rate limiting, input validation, secure headers  

## Requirements 📋

### Local Development
- Python 3.11+
- Node.js (optional, for frontend development)
- Ollama with Llama3.2-vision model

### Production Deployment
- Docker & Docker Compose
- Ollama (runs on the host system)

## Installation & Setup 🚀

### 1. Ollama Setup

Install Ollama from [ollama.ai](https://ollama.ai) and download the model:

```bash
# Install Ollama (according to your OS)
curl -fsSL https://ollama.ai/install.sh | sh

# Download the Llama3.2-vision model
ollama pull llama3.2-vision

# Start the Ollama server (runs on port 11434)
ollama serve
````

### 2. Clone/Download the Project

```bash
git clone <your-repo-url>
cd scam-detector
```

### 3. Local Development

#### Backend

```bash
cd backend
pip install -r requirements.txt
python -m app.main
```

The backend runs at: [http://localhost:8000](http://localhost:8000)

#### Frontend

Open `frontend/index.html` directly in your browser, or use a local server:

```bash
cd frontend
python -m http.server 3000
# or
npx serve .
```

### 4. Production with Docker

```bash
# Start all services
docker-compose up -d

# Or only core services (without monitoring)
docker-compose up -d scam-detector-api nginx

# Show logs
docker-compose logs -f scam-detector-api

# Stop services
docker-compose down
```

The application is available at:

* Frontend: [http://localhost](http://localhost)
* Backend API: [http://localhost:8000](http://localhost:8000)
* API Docs: [http://localhost:8000/docs](http://localhost:8000/docs)

## Configuration ⚙️

### Environment Variables

#### Backend (`.env` or `docker-compose.yml`)

```env
OLLAMA_BASE_URL=http://localhost:11434  # Ollama server URL
MODEL_NAME=llama3.2-vision              # Used model
LOG_LEVEL=INFO                          # Logging level
```

#### Frontend (`script.js`)

```javascript
// Set API base URL
this.apiBaseUrl = 'http://localhost:8000';
```

### Nginx Configuration

Edit `nginx.conf` for production use:

* Configure SSL certificates
* Add domain-specific settings
* Adjust rate-limiting

## API Documentation 📚

### Endpoints

#### `GET /health`

Health check for service status

**Response:**

```json
{
  "status": "healthy",
  "ollama_connected": true,
  "model": "llama3.2-vision"
}
```

#### `POST /analyze`

Image analysis for scam detection

**Request:**

* Content-Type: `multipart/form-data`
* Body: `file` (image file, max 10MB)

**Response:**

```json
{
  "score": 85,
  "explanation": "The image shows a suspicious email with...",
  "risk_level": "HIGH",
  "confidence": 0.92
}
```

### Risk Levels

* `LOW`: Score 0–25
* `MEDIUM`: Score 26–50
* `HIGH`: Score 51–75
* `VERY_HIGH`: Score 76–100

## Usage 💡

### Web Interface

1. **Upload image**: Drag and drop an image or use the file picker
2. **Check preview**: Review the uploaded image
3. **Start analysis**: Click the “Analyze” button
4. **Interpret results**: Review the score, risk level, and explanation

### Programmatic Usage

```python
import requests

# Analyze image
with open('suspicious_image.png', 'rb') as f:
    response = requests.post(
        'http://localhost:8000/analyze',
        files={'file': f}
    )
    result = response.json()
    print(f"Scam Score: {result['score']}/100")
```

## Development 🛠️

### Project Structure

```
scam-detector/
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   └── main.py          # Main API code
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile           # Backend container
├── frontend/                # Web frontend
│   ├── index.html           # Main HTML
│   ├── styles.css           # CSS styling
│   └── script.js            # JavaScript logic
├── docker-compose.yml       # Container orchestration
├── nginx.conf               # Webserver configuration
└── README.md                # This file
```

### Code Style

#### Python (Backend)

* Follows PEP 8
* Uses type hints
* Async/await for I/O operations
* Structured logging

#### JavaScript (Frontend)

* ES6+ features
* Modular classes
* Error handling
* Accessibility considerations

### Testing

```bash
# Backend tests
cd backend
pytest

# Frontend tests (if implemented)
cd frontend
npm test
```

## Monitoring & Logging 📊

### Production Monitoring

Enable monitoring stack:

```bash
# With Prometheus & Grafana
docker-compose --profile monitoring up -d

# Access:
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin)
```

### Logs

```bash
# Backend logs
docker-compose logs -f scam-detector-api

# Nginx logs
docker-compose logs -f nginx

# All logs
docker-compose logs -f
```

## Security 🔒

### Implemented Measures

* **Input Validation**: File type and size check
* **Rate Limiting**: Prevents abuse
* **CORS Policy**: Controlled cross-origin requests
* **Security Headers**: XSS and clickjacking protection
* **No Data Storage**: Images are not saved

### Production Recommendations

* Set up HTTPS (SSL certificates)
* Configure firewall
* Apply regular updates
* Define backup strategies

## Troubleshooting 🔧

### Common Issues

#### "Ollama service unavailable"

```bash
# Check Ollama status
ollama list

# Is the model available?
ollama pull llama3.2-vision

# Is the server running?
curl http://localhost:11434/api/tags
```

#### "Backend not reachable"

```bash
# Check container status
docker-compose ps

# Backend logs
docker-compose logs scam-detector-api

# Check network
docker network ls
```

#### Slow Analysis

* Enable GPU support in Ollama
* Allocate more RAM to Docker
* Optimize model parameters

### Performance Tuning

#### Ollama

```bash
# GPU support (NVIDIA)
docker run --gpus all ollama/ollama

# Allocate more memory
OLLAMA_HOST=0.0.0.0:11434 OLLAMA_MODELS=/path/to/models ollama serve
```

#### Backend

* Increase Gunicorn workers
* Implement Redis caching
* Optimize image compression

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push the branch (`git push origin feature/amazing-feature`)
5. Open a pull request

## License 📄

This project is licensed under the MIT License – see [LICENSE](LICENSE) for details.

## Support & Contact 💬

* **Issues**: Use GitHub Issues for bug reports
* **Discussions**: Use GitHub Discussions for general questions
* **Security**: Report security issues privately

## Roadmap 🗺️

### Planned Features

* [ ] Multi-language support
* [ ] Per-user API rate limiting
* [ ] Extended scam categories
* [ ] Batch processing
* [ ] Mobile app
* [ ] Browser plugin

### Improvements

* [ ] Performance optimization
* [ ] Extended testing
* [ ] CI/CD pipeline
* [ ] Kubernetes deployment
* [ ] Enhanced monitoring

---

**Important Note**: This software is an aid for scam detection. Results are recommendations, not guarantees. Always consult security experts or authorities when in doubt.


