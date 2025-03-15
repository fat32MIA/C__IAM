#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>
#include <sqlite3.h>

class LearningEngine {
public:
    LearningEngine(const std::string& dbPath);
    ~LearningEngine();

    // Registro de interacciones
    void recordInteraction(const std::string& query, const std::string& response, float confidence);
    void recordFeedback(int queryId, int userId, int score, const std::string& feedbackText);
    
    // Aprendizaje
    void updatePatterns();
    bool learnNewPattern(const std::string& pattern, const std::string& responseTemplate);
    
    // Aplicación de conocimiento aprendido
    struct PatternMatch {
        std::string responseTemplate;
        float confidence;
        bool isExactMatch;
    };
    
    PatternMatch findMatchingPattern(const std::string& query);
    
    // Estadísticas
    struct LearningStats {
        int totalPatterns;
        int totalQueries;
        int feedbackCount;
        float averageConfidence;
        int patternsLastMonth;
    };
    
    LearningStats getStatistics();

private:
    sqlite3* db;
    std::mutex dbMutex;
    
    // Hash para consultas
    std::string hashQuery(const std::string& query);
    
    // Extracción de patrones
    std::vector<std::string> extractPossiblePatterns(const std::string& query);
    
    // Análisis de éxito
    float calculatePatternSuccessRate(const std::string& pattern);
    
    // Procesamiento de texto
    std::string normalizeQuery(const std::string& query);
    
    // Generación de respuestas
    std::string fillResponseTemplate(const std::string& templ, const std::unordered_map<std::string, std::string>& vars);
};
