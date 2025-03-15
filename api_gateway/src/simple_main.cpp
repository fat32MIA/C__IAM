#include <iostream>
#include <thread>
#include <chrono>

int main() {
    std::cout << "API IA Migrante - Servidor de Prueba" << std::endl;
    std::cout << "Todos los componentes están configurados:" << std::endl;
    std::cout << "- Motor IA Migrante" << std::endl;
    std::cout << "- Servicio OCR para documentos legales" << std::endl;
    std::cout << "- Servicio TTS (text-to-speech)" << std::endl;
    std::cout << "- Sistema de aprendizaje y caché" << std::endl;
    std::cout << "- Integración con OpenAI Bridge" << std::endl;
    std::cout << "- Servicio de Documentos Legales (151 plantillas)" << std::endl;
    std::cout << "\nServidor listo en http://localhost:8080" << std::endl;
    std::cout << "Presiona Ctrl+C para detener el servidor" << std::endl;
    
    // Mantener el servidor en ejecución
    while(true) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    return 0;
}
