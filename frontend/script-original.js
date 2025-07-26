// Scam Detector Frontend JavaScript

class ScamDetector {
    constructor() {
        this.apiBaseUrl = 'http://localhost:8000';
        this.currentFile = null;
        this.currentResult = null;
        
        this.initializeElements();
        this.bindEvents();
        this.checkApiHealth();
    }

    initializeElements() {
        // DOM-Elemente
        this.fileInput = document.getElementById('fileInput');
        this.uploadArea = document.getElementById('uploadArea');
        this.previewSection = document.getElementById('previewSection');
        this.previewImage = document.getElementById('previewImage');
        this.loadingSection = document.getElementById('loadingSection');
        this.resultsSection = document.getElementById('resultsSection');
        this.errorSection = document.getElementById('errorSection');
        this.analyzeBtn = document.getElementById('analyzeBtn');
        this.toastContainer = document.getElementById('toastContainer');
        
        // Result-Elemente
        this.scoreValue = document.getElementById('scoreValue');
        this.scoreCircle = document.getElementById('scoreCircle');
        this.riskValue = document.getElementById('riskValue');
        this.explanationText = document.getElementById('explanationText');
        this.confidenceFill = document.getElementById('confidenceFill');
        this.confidenceValue = document.getElementById('confidenceValue');
        this.errorMessage = document.getElementById('errorMessage');
    }

    bindEvents() {
        // File Input Events
        this.fileInput.addEventListener('change', (e) => this.handleFileSelect(e));
        
        // Drag & Drop Events
        this.uploadArea.addEventListener('dragover', (e) => this.handleDragOver(e));
        this.uploadArea.addEventListener('dragleave', (e) => this.handleDragLeave(e));
        this.uploadArea.addEventListener('drop', (e) => this.handleDrop(e));
        
        // Prevent default drag behaviors
        document.addEventListener('dragover', (e) => e.preventDefault());
        document.addEventListener('drop', (e) => e.preventDefault());
        
        // Keyboard accessibility
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.resetAnalysis();
            }
        });
    }

    async checkApiHealth() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/health`);
            if (!response.ok) {
                throw new Error('API nicht erreichbar');
            }
            
            const health = await response.json();
            if (!health.ollama_connected) {
                this.showToast('Warnung: Ollama ist nicht verbunden. Stellen Sie sicher, dass Ollama läuft.', 'error');
            }
        } catch (error) {
            console.error('Health check failed:', error);
            this.showToast('Backend-Service nicht erreichbar. Starten Sie den Server.', 'error');
        }
    }

    handleDragOver(e) {
        e.preventDefault();
        this.uploadArea.classList.add('dragover');
    }

    handleDragLeave(e) {
        e.preventDefault();
        this.uploadArea.classList.remove('dragover');
    }

    handleDrop(e) {
        e.preventDefault();
        this.uploadArea.classList.remove('dragover');
        
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            this.processFile(files[0]);
        }
    }

    handleFileSelect(e) {
        const file = e.target.files[0];
        if (file) {
            this.processFile(file);
        }
    }

    processFile(file) {
        // Dateivalidierung
        if (!file.type.startsWith('image/')) {
            this.showToast('Bitte wählen Sie eine Bilddatei aus.', 'error');
            return;
        }

        if (file.size > 10 * 1024 * 1024) { // 10MB
            this.showToast('Datei ist zu groß. Maximum: 10MB', 'error');
            return;
        }

        this.currentFile = file;
        this.displayPreview(file);
        this.hideAllSections();
        this.previewSection.style.display = 'block';
        
        this.showToast('Bild erfolgreich geladen', 'success');
    }

    displayPreview(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            this.previewImage.src = e.target.result;
        };
        reader.readAsDataURL(file);
    }

    async analyzeImage() {
        if (!this.currentFile) {
            this.showToast('Kein Bild ausgewählt', 'error');
            return;
        }

        // Loading anzeigen
        this.hideAllSections();
        this.loadingSection.style.display = 'block';
        this.analyzeBtn.disabled = true;

        try {
            const formData = new FormData();
            formData.append('file', this.currentFile);

            const response = await fetch(`${this.apiBaseUrl}/analyze`, {
                method: 'POST',
                body: formData
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.detail || `HTTP ${response.status}`);
            }

            const result = await response.json();
            this.currentResult = result;
            this.displayResults(result);
            
        } catch (error) {
            console.error('Analysis error:', error);
            this.showError(error.message);
        } finally {
            this.analyzeBtn.disabled = false;
        }
    }

    displayResults(result) {
        this.hideAllSections();
        this.resultsSection.style.display = 'block';

        // Score anzeigen
        this.scoreValue.textContent = result.score;
        const scoreDeg = (result.score / 100) * 360;
        this.scoreCircle.style.setProperty('--score-deg', `${scoreDeg}deg`);

        // Risiko-Level
        this.riskValue.textContent = result.risk_level;
        this.riskValue.className = `risk-value risk-${result.risk_level.toLowerCase()}`;

        // Erklärung
        this.explanationText.textContent = result.explanation;

        // Vertrauen
        const confidencePercent = Math.round(result.confidence * 100);
        this.confidenceFill.style.width = `${confidencePercent}%`;
        this.confidenceValue.textContent = `${confidencePercent}%`;

        // Scroll zu Ergebnissen
        this.resultsSection.scrollIntoView({ behavior: 'smooth' });
        
        this.showToast('Analyse erfolgreich abgeschlossen', 'success');
    }

    showError(message) {
        this.hideAllSections();
        this.errorSection.style.display = 'block';
        this.errorMessage.textContent = message;
        this.showToast('Fehler bei der Analyse', 'error');
    }

    hideAllSections() {
        this.previewSection.style.display = 'none';
        this.loadingSection.style.display = 'none';
        this.resultsSection.style.display = 'none';
        this.errorSection.style.display = 'none';
    }

    resetAnalysis() {
        this.currentFile = null;
        this.currentResult = null;
        this.fileInput.value = '';
        this.hideAllSections();
        
        // Scroll zum Upload-Bereich
        this.uploadArea.scrollIntoView({ behavior: 'smooth' });
    }

    removeImage() {
        this.resetAnalysis();
        this.showToast('Bild entfernt', 'success');
    }

    shareResult() {
        if (!this.currentResult) {
            this.showToast('Kein Ergebnis zum Teilen verfügbar', 'error');
            return;
        }

        const shareData = {
            title: 'Scam Detector Ergebnis',
            text: `Scam-Risiko: ${this.currentResult.score}/100 (${this.currentResult.risk_level})\n\n${this.currentResult.explanation}`,
            url: window.location.href
        };

        if (navigator.share && navigator.canShare && navigator.canShare(shareData)) {
            navigator.share(shareData)
                .then(() => this.showToast('Ergebnis geteilt', 'success'))
                .catch((error) => console.error('Error sharing:', error));
        } else {
            // Fallback: Copy to clipboard
            const textToCopy = `${shareData.title}\n\n${shareData.text}\n\n${shareData.url}`;
            
            if (navigator.clipboard && window.isSecureContext) {
                navigator.clipboard.writeText(textToCopy)
                    .then(() => this.showToast('Ergebnis in Zwischenablage kopiert', 'success'))
                    .catch(() => this.fallbackCopyToClipboard(textToCopy));
            } else {
                this.fallbackCopyToClipboard(textToCopy);
            }
        }
    }

    fallbackCopyToClipboard(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        try {
            document.execCommand('copy');
            this.showToast('Ergebnis in Zwischenablage kopiert', 'success');
        } catch (err) {
            console.error('Fallback copy failed:', err);
            this.showToast('Kopieren fehlgeschlagen', 'error');
        }
        
        document.body.removeChild(textArea);
    }

    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <div style="display: flex; align-items: center; gap: 0.5rem;">
                <i class="fas fa-${this.getToastIcon(type)}"></i>
                <span>${message}</span>
            </div>
        `;
        
        this.toastContainer.appendChild(toast);
        
        // Auto-remove nach 5 Sekunden
        setTimeout(() => {
            if (toast.parentNode) {
                toast.style.animation = 'slideIn 0.3s ease reverse';
                setTimeout(() => {
                    if (toast.parentNode) {
                        this.toastContainer.removeChild(toast);
                    }
                }, 300);
            }
        }, 5000);
        
        // Click to close
        toast.addEventListener('click', () => {
            if (toast.parentNode) {
                this.toastContainer.removeChild(toast);
            }
        });
    }

    getToastIcon(type) {
        switch (type) {
            case 'success': return 'check-circle';
            case 'error': return 'exclamation-triangle';
            case 'warning': return 'exclamation-circle';
            default: return 'info-circle';
        }
    }
}

// Globale Funktionen für HTML onclick Events
function removeImage() {
    scamDetector.removeImage();
}

function analyzeImage() {
    scamDetector.analyzeImage();
}

function resetAnalysis() {
    scamDetector.resetAnalysis();
}

function shareResult() {
    scamDetector.shareResult();
}

// Service Worker für PWA (Progressive Web App)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then((registration) => {
                console.log('SW registered: ', registration);
            })
            .catch((registrationError) => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}

// Performance monitoring
function measurePerformance() {
    if ('performance' in window) {
        window.addEventListener('load', () => {
            setTimeout(() => {
                const navigation = performance.getEntriesByType('navigation')[0];
                console.log('Page load time:', navigation.loadEventEnd - navigation.loadEventStart, 'ms');
            }, 0);
        });
    }
}

// Error handling
window.addEventListener('error', (e) => {
    console.error('Global error:', e.error);
    if (window.scamDetector) {
        scamDetector.showToast('Ein unerwarteter Fehler ist aufgetreten', 'error');
    }
});

window.addEventListener('unhandledrejection', (e) => {
    console.error('Unhandled promise rejection:', e.reason);
    if (window.scamDetector) {
        scamDetector.showToast('Ein unerwarteter Fehler ist aufgetreten', 'error');
    }
});

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
    window.scamDetector = new ScamDetector();
    measurePerformance();
    
    // Add loading animation to body
    document.body.classList.add('loaded');
});

// CSS for smooth loading
const style = document.createElement('style');
style.textContent = `
    body {
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    body.loaded {
        opacity: 1;
    }
`;
document.head.appendChild(style);

// Utility functions
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Export for potential module use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ScamDetector };
}
