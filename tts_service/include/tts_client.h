#pragma once

#include <string>
#include <vector>

class TTSClient {
public:
    enum class AudioFormat {
        WAV,
        MP3,
        OGG
    };
    
    struct TTSOptions {
        std::string voice;      // "es_female", "en_male", etc.
        float speed;            // 1.0 = normal
        AudioFormat format;     // Formato de salida
        int sampleRate;         // Tasa de muestreo (Hz)
    };
    
    struct TTSResult {
        std::vector<uint8_t> audioData;
        std::string mimeType;
        float durationSeconds;
        size_t sizeBytes;
    };
    
    static TTSResult synthesizeSpeech(const std::string& text, const TTSOptions& options);
    
    static std::vector<std::string> getAvailableVoices();
};
