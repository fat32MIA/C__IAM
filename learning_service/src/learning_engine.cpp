#include "learning_engine.h"
#include <iostream>
#include <fstream>
#include <algorithm>
#include <regex>
#include <chrono>
#include <openssl/sha.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

LearningEngine::LearningEngine(const std::string& dbPath) {
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        throw std::runtime_error("Error al abrir la base de datos de aprendizaje");
    }
}

LearningEngine::~LearningEngine() {
    if (db) {
        sqlite3_close(db);
    }
}

void LearningEngine::recordInteraction(const std::string& query, const std::string& response, float confidence) {
    std::string queryHash = hashQuery(query);
    
    const char* sql = "INSERT OR REPLACE INTO query_cache (query_hash, query_text, response_text, confidence, last_used, use_count, valid_until) "
                      "VALUES (?, ?, ?, ?, datetime('now'), COALESCE((SELECT use_count + 1 FROM query_cache WHERE query_hash = ?), 1), datetime('now', '+3 days'))";
    
    sqlite3_stmt* stmt;
    std::lock_guard<std::mutex> lock(dbMutex);
    
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        std::cerr << "Error al preparar la consulta: " << sqlite3_errmsg(db) << std::endl;
        return;
    }
    
    sqlite3_bind_text(stmt, 1, queryHash.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, query.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 3, response.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_double(stmt, 4, confidence);
    sqlite3_bind_text(stmt, 5, queryHash.c_str(), -1, SQLITE_STATIC);
    
    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE) {
        std::cerr << "Error al insertar en caché: " << sqlite3_errmsg(db) << std::endl;
    }
    
    sqlite3_finalize(stmt);
}

void LearningEngine::recordFeedback(int queryId, int userId, int score, const std::string& feedbackText) {
    const char* sql = "INSERT INTO learning_feedback (query_id, user_id, feedback_score, feedback_text) VALUES (?, ?, ?, ?)";
    
    sqlite3_stmt* stmt;
    std::lock_guard<std::mutex> lock(dbMutex);
    
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        std::cerr << "Error al preparar la inserción de feedback: " << sqlite3_errmsg(db) << std::endl;
        return;
    }
    
    sqlite3_bind_int(stmt, 1, queryId);
    sqlite3_bind_int(stmt, 2, userId);
    sqlite3_bind_int(stmt, 3, score);
    sqlite3_bind_text(stmt, 4, feedbackText.c_str(), -1, SQLITE_STATIC);
    
    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE) {
        std::cerr << "Error al insertar feedback: " << sqlite3_errmsg(db) << std::endl;
    }
    
    sqlite3_finalize(stmt);
    
    // Si el feedback es positivo, considerar aprender de él
    if (score >= 4) {
        // Obtener la consulta relacionada
        sql = "SELECT query_text, response_text FROM query_cache WHERE id = ?";
        rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
        if (rc != SQLITE_OK) {
            return;
        }
        
        sqlite3_bind_int(stmt, 1, queryId);
        
        std::string query, response;
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            query = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            response = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        }
        
        sqlite3_finalize(stmt);
        
        if (!query.empty() && !response.empty()) {
            // Extraer posibles patrones
            auto patterns = extractPossiblePatterns(query);
            for (const auto& pattern : patterns) {
                // Verificar si ya existe un patrón similar
                if (calculatePatternSuccessRate(pattern) > 0.7) {
                    learnNewPattern(pattern, response);
                }
            }
        }
    }
}

void LearningEngine::updatePatterns() {
    std::lock_guard<std::mutex> lock(dbMutex);
    
    // Buscar consultas frecuentes con buen feedback
    const char* sql = "SELECT qc.query_text, qc.response_text, AVG(lf.feedback_score) as avg_score, COUNT(lf.id) as feedback_count "
                      "FROM query_cache qc "
                      "JOIN learning_feedback lf ON qc.id = lf.query_id "
                      "GROUP BY qc.id "
                      "HAVING avg_score >= 4.0 AND feedback_count >= 3 "
                      "ORDER BY feedback_count DESC, avg_score DESC "
                      "LIMIT 100";
    
    sqlite3_stmt* stmt;
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        std::cerr << "Error al preparar actualización de patrones: " << sqlite3_errmsg(db) << std::endl;
        return;
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        std::string query = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        std::string response = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        
        // Generar patrones a partir de consultas populares
        auto patterns = extractPossiblePatterns(query);
        for (const auto& pattern : patterns) {
            if (!pattern.empty()) {
                learnNewPattern(pattern, response);
            }
        }
    }
    
    sqlite3_finalize(stmt);
}

bool LearningEngine::learnNewPattern(const std::string& pattern, const std::string& responseTemplate) {
    // Evitar patrones muy cortos o genéricos
    if (pattern.length() < 10) {
        return false;
    }
    
    const char* sql = "INSERT OR REPLACE INTO learned_patterns (pattern_type, pattern_text, response_template, confidence) "
                      "VALUES ('regex', ?, ?, 0.8)";
    
    sqlite3_stmt* stmt;
    std::lock_guard<std::mutex> lock(dbMutex);
    
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        std::cerr << "Error al preparar inserción de patrón: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }
    
    sqlite3_bind_text(stmt, 1, pattern.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, responseTemplate.c_str(), -1, SQLITE_STATIC);
    
    rc = sqlite3_step(stmt);
    bool success = (rc == SQLITE_DONE);
    
    sqlite3_finalize(stmt);
    return success;
}

LearningEngine::PatternMatch LearningEngine::findMatchingPattern(const std::string& query) {
    PatternMatch result;
    result.confidence = 0.0;
    result.isExactMatch = false;
    
    // Primero buscar en caché para consulta exacta
    std::string queryHash = hashQuery(query);
    const char* cacheSql = "SELECT response_text, confidence FROM query_cache "
                          "WHERE query_hash = ? AND valid_until > datetime('now') "
                          "ORDER BY use_count DESC, last_used DESC LIMIT 1";
    
    sqlite3_stmt* stmt;
    std::lock_guard<std::mutex> lock(dbMutex);
    
    int rc = sqlite3_prepare_v2(db, cacheSql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        return result;
    }
    
    sqlite3_bind_text(stmt, 1, queryHash.c_str(), -1, SQLITE_STATIC);
    
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        result.responseTemplate = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        result.confidence = sqlite3_column_double(stmt, 1);
        result.isExactMatch = true;
        
        // Actualizar estadísticas de uso
        const char* updateSql = "UPDATE query_cache SET use_count = use_count + 1, last_used = datetime('now') WHERE query_hash = ?";
        sqlite3_stmt* updateStmt;
        sqlite3_prepare_v2(db, updateSql, -1, &updateStmt, nullptr);
        sqlite3_bind_text(updateStmt, 1, queryHash.c_str(), -1, SQLITE_STATIC);
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    
    sqlite3_finalize(stmt);
    
    // Si no hay coincidencia exacta, buscar patrones aprendidos
    if (!result.isExactMatch) {
        const char* patternSql = "SELECT pattern_text, response_template, confidence FROM learned_patterns "
                               "ORDER BY confidence DESC, use_count DESC";
        
        rc = sqlite3_prepare_v2(db, patternSql, -1, &stmt, nullptr);
        if (rc != SQLITE_OK) {
            return result;
        }
        
        std::string normalizedQuery = normalizeQuery(query);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::string pattern = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            std::string response = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
            float confidence = sqlite3_column_double(stmt, 2);
            
            try {
                std::regex re(pattern, std::regex::icase);
                if (std::regex_search(normalizedQuery, re)) {
                    // Actualizar estadísticas del patrón
                    const char* updateSql = "UPDATE learned_patterns SET use_count = use_count + 1, last_used = datetime('now') WHERE pattern_text = ?";
                    sqlite3_stmt* updateStmt;
                    sqlite3_prepare_v2(db, updateSql, -1, &updateStmt, nullptr);
                    sqlite3_bind_text(updateStmt, 1, pattern.c_str(), -1, SQLITE_STATIC);
                    sqlite3_step(updateStmt);
                    sqlite3_finalize(updateStmt);
                    
                    // Si encontramos un patrón con mayor confianza, actualizamos el resultado
                    if (confidence > result.confidence) {
                        result.responseTemplate = response;
                        result.confidence = confidence;
                    }
                }
            } catch (const std::regex_error& e) {
                // Ignorar patrones con expresiones regulares inválidas
                continue;
            }
        }
        
        sqlite3_finalize(stmt);
    }
    
    return result;
}

LearningEngine::LearningStats LearningEngine::getStatistics() {
    LearningStats stats;
    stats.totalPatterns = 0;
    stats.totalQueries = 0;
    stats.feedbackCount = 0;
    stats.averageConfidence = 0.0;
    stats.patternsLastMonth = 0;
    
    std::lock_guard<std::mutex> lock(dbMutex);
    
    // Contar patrones totales
    const char* patternCountSql = "SELECT COUNT(*) FROM learned_patterns";
    sqlite3_stmt* stmt;
    
    if (sqlite3_prepare_v2(db, patternCountSql, -1, &stmt, nullptr) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            stats.totalPatterns = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    
    // Contar consultas en caché
    const char* queriesCountSql = "SELECT COUNT(*) FROM query_cache";
    if (sqlite3_prepare_v2(db, queriesCountSql, -1, &stmt, nullptr) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            stats.totalQueries = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    
    // Contar feedback
    const char* feedbackCountSql = "SELECT COUNT(*) FROM learning_feedback";
    if (sqlite3_prepare_v2(db, feedbackCountSql, -1, &stmt, nullptr) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            stats.feedbackCount = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    
    // Calcular confianza promedio
    const char* avgConfidenceSql = "SELECT AVG(confidence) FROM learned_patterns";
    if (sqlite3_prepare_v2(db, avgConfidenceSql, -1, &stmt, nullptr) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            stats.averageConfidence = sqlite3_column_double(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    
    // Contar patrones aprendidos en el último mes
    const char* recentPatternsSql = "SELECT COUNT(*) FROM learned_patterns WHERE created_at > datetime('now', '-30 days')";
    if (sqlite3_prepare_v2(db, recentPatternsSql, -1, &stmt, nullptr) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            stats.patternsLastMonth = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    }
    
    return stats;
}

std::string LearningEngine::hashQuery(const std::string& query) {
    // Normalizar la consulta antes de calcular el hash
    std::string normalized = normalizeQuery(query);
    
    // Calcular SHA-256
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, normalized.c_str(), normalized.length());
    SHA256_Final(hash, &sha256);
    
    // Convertir a hexadecimal
    std::stringstream ss;
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(hash[i]);
    }
    return ss.str();
}

std::vector<std::string> LearningEngine::extractPossiblePatterns(const std::string& query) {
    std::vector<std::string> patterns;
    std::string normalized = normalizeQuery(query);
    
    // Extraer frases completas
    patterns.push_back(normalized);
    
    // Extraer palabras clave de inmigración
    std::vector<std::string> keywords = {
        "visa", "green card", "ciudadanía", "citizenship", "i-485", "i-130", 
        "ajuste de estatus", "tps", "daca", "asylum", "asilo", "permiso de trabajo",
        "work permit", "naturalización", "naturalization", "deportación", "deportation",
        "eb1", "eb2", "eb3", "h1b", "f1", "j1", "b1", "b2"
    };
    
    std::string pattern;
    for (const auto& keyword : keywords) {
        if (normalized.find(keyword) != std::string::npos) {
            pattern += keyword + "|";
        }
    }
    
    if (!pattern.empty()) {
        pattern.pop_back(); // Eliminar el último '|'
        patterns.push_back(".*(" + pattern + ").*");
    }
    
    // Intentar identificar patrones de preguntas
    if (normalized.find("cómo") != std::string::npos || 
        normalized.find("como") != std::string::npos || 
        normalized.find("how") != std::string::npos) {
        patterns.push_back(".*\\b(como|cómo|how)\\b.*");
    }
    
    if (normalized.find("qué") != std::string::npos || 
        normalized.find("que") != std::string::npos || 
        normalized.find("what") != std::string::npos) {
        patterns.push_back(".*\\b(que|qué|what)\\b.*");
    }
    
    return patterns;
}

float LearningEngine::calculatePatternSuccessRate(const std::string& pattern) {
    const char* sql = "SELECT AVG(lf.feedback_score) "
                     "FROM learned_patterns lp "
                     "JOIN query_cache qc ON qc.response_text = lp.response_template "
                     "JOIN learning_feedback lf ON lf.query_id = qc.id "
                     "WHERE lp.pattern_text = ?";
    
    sqlite3_stmt* stmt;
    std::lock_guard<std::mutex> lock(dbMutex);
    
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        return 0.0;
    }
    
    sqlite3_bind_text(stmt, 1, pattern.c_str(), -1, SQLITE_STATIC);
    
    float rate = 0.0;
    if (sqlite3_step(stmt) == SQLITE_ROW && sqlite3_column_type(stmt, 0) != SQLITE_NULL) {
        rate = sqlite3_column_double(stmt, 0) / 5.0; // Normalizar a 0-1
    }
    
    sqlite3_finalize(stmt);
    return rate;
}

std::string LearningEngine::normalizeQuery(const std::string& query) {
    std::string result = query;
    
    // Convertir a minúsculas
    std::transform(result.begin(), result.end(), result.begin(), ::tolower);
    
    // Eliminar caracteres especiales y acentos
    std::string accents = "áéíóúüñÁÉÍÓÚÜÑ";
    std::string replacements = "aeiouunAEIOUUN";
    
    for (size_t i = 0; i < result.length(); i++) {
        size_t pos = accents.find(result[i]);
        if (pos != std::string::npos) {
            result[i] = replacements[pos];
        }
    }
    
    // Eliminar signos de puntuación extra
    std::regex punct_re("[!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~]{2,}");
    result = std::regex_replace(result, punct_re, " ");
    
    // Eliminar espacios extras
    std::regex space_re("\\s+");
    result = std::regex_replace(result, space_re, " ");
    
    // Recortar espacios al inicio y final
    result = std::regex_replace(result, std::regex("^\\s+|\\s+$"), "");
    
    return result;
}

std::string LearningEngine::fillResponseTemplate(const std::string& templ, const std::unordered_map<std::string, std::string>& vars) {
    std::string result = templ;
    
    // Reemplazar variables en el template
    for (const auto& var : vars) {
        std::string placeholder = "{{" + var.first + "}}";
        size_t pos = result.find(placeholder);
        while (pos != std::string::npos) {
            result.replace(pos, placeholder.length(), var.second);
            pos = result.find(placeholder, pos + var.second.length());
        }
    }
    
    return result;
}
