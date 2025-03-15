#include "tts_client.h"
#include <iostream>
#include <random>

TTSClient::TTSResult TTSClient::synthesizeSpeech(const std::string& text, const TTSOptions& options) {
    TTSResult result;
    
    // En un sistema real, aquí utilizaríamos eSpeak o alguna otra biblioteca TTS
    // Para este ejemplo, simularemos la generación de audio
    
    // Calcular duración aproximada (1 palabra = ~0.3 segundos)
    int wordCount = 1;
    size_t pos = 0;
    while ((pos = text.find(' ', pos + 1)) != std::string::npos) {
        wordCount++;
    }
    
    result.durationSeconds = wordCount * 0.3 * (1.0 / options.speed);
    
    // Generar datos binarios aleatorios para simular el audio
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> distrib(0, 255);
    
    // Calcular tamaño aproximado (1 segundo = ~16KB para WAV mono)
    size_t bytesPerSecond = 16000;
    if (options.format == AudioFormat::MP3) {
        bytesPerSecond = 2000;  // MP3 es más comprimido
    } else if (options.format == AudioFormat::OGG) {
        bytesPerSecond = 4000;  // OGG está en el medio
    }
    
    size_t dataSize = static_cast<size_t>(result.durationSeconds * bytesPerSecond);
    result.audioData.resize(dataSize);
    
    for (size_t i = 0; i < dataSize; i++) {
        result.audioData[i] = static_cast<uint8_t>(distrib(gen));
    }
    
    result.sizeBytes = result.audioData.size();
    
    // Establecer el tipo MIME según el formato
    switch (options.format) {
        case AudioFormat::MP3:
            result.mimeType = "audio/mpeg";
            break;
        case AudioFormat::OGG:
            result.mimeType = "audio/ogg";
            break;
        case AudioFormat::WAV:
        default:
            result.mimeType = "audio/wav";
            break;
    }
    
    return result;
}

std::vector<std::string> TTSClient::getAvailableVoices() {
    // En un sistema real, aquí consultaríamos las voces disponibles
    // Para este ejemplo, devolvemos una lista fija
    return {
        "es_female_clara",
        "es_male_carlos",
        "en_female_lisa",
        "en_male_john"
    };
}
