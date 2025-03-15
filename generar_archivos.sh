 #!/bin/bash
# archivo: generar_archivos.sh
# Script para generar los archivos fuente del proyecto IA Migrante

echo "Generando archivos de cabecera y fuentes para todos los componentes..."

# 1. Servicio de Autenticación
echo "Generando AuthService..."

cat > auth_service/include/auth_service.h << 'EOF'
#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>
#include <sqlite3.h>

class AuthService {
public:
    struct UserInfo {
        int id;
        std::string username;
        std::string subscriptionTier;
        std::string role;
    };
    
    struct UsageStats {
        int queries;
        int documents;
        int openai;
        int ocr;
        int tts;
    };
    
    struct QuotaLimits {
        int dailyQueries;
        int monthlyDocuments;
        int openaiUsage;
        int monthlyOcr;
        int monthlyTtsMinutes;
    };
    
    static bool authenticateUser(const std::string& username, const std::string& password, 
                                 const std::string& dbPath, UserInfo& outUser);
    
    static bool validateJWT(const std::string& token, const std::string& secret, UserInfo& outUser);
    
    static bool validateAPIKey(const std::string& apiKey, const std::string& dbPath, UserInfo& outUser);
    
    static std::string generateJWT(const UserInfo& user, const std::string& secret, int expiryHours);
    
    static std::string generateAPIKey(int userId, const std::string& dbPath, const std::string& prefix);
    
    static bool checkQuotaAndUpdate(int userId, const std::string& actionType, const std::string& dbPath);
    
    static UsageStats getUserUsage(int userId, const std::string& dbPath);
    
    static QuotaLimits getQuotaLimits(const std::string& subscriptionTier, const std::string& dbPath);
};
EOF

cat > auth_service/src/auth_service.cpp << 'EOF'
#include "auth_service.h"
#include <iostream>
#include <openssl/hmac.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <nlohmann/json.hpp>
#include <sstream>
#include <iomanip>
#include <chrono>
#include <ctime>

using json = nlohmann::json;

bool AuthService::authenticateUser(const std::string& username, const std::string& password, 
                                 const std::string& dbPath, UserInfo& outUser) {
    sqlite3* db;
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return false;
    }
    
    // En un sistema real, verificaríamos el hash de la contraseña
    // Para este ejemplo, comparamos directamente (no es seguro para producción)
    const char* sql = "SELECT id, username FROM users WHERE username = ? AND password_hash = ?";
    sqlite3_stmt* stmt;
    
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        sqlite3_close(db);
        return false;
    }
    
    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_STATIC);
    
    bool authenticated = false;
    
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        outUser.id = sqlite3_column_int(stmt, 0);
        outUser.username = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        outUser.role = "user";  // Por defecto
        
        // Obtener nivel de suscripción
        sqlite3_finalize(stmt);
        const char* subSql = "SELECT tier FROM subscriptions WHERE user_id = ? AND end_date > datetime('now') ORDER BY end_date DESC LIMIT 1";
        rc = sqlite3_prepare_v2(db, subSql, -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, outUser.id);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                outUser.subscriptionTier = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            } else {
                outUser.subscriptionTier = "free";  // Por defecto
            }
        }
        
        // Actualizar último login
        sqlite3_finalize(stmt);
        const char* updateSql = "UPDATE users SET last_login = datetime('now') WHERE id = ?";
        rc = sqlite3_prepare_v2(db, updateSql, -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, outUser.id);
            sqlite3_step(stmt);
        }
        
        authenticated = true;
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return authenticated;
}

std::string AuthService::generateJWT(const UserInfo& user, const std::string& secret, int expiryHours) {
    // Este es un ejemplo simplificado. En producción, usa una biblioteca JWT adecuada
    // Header - algoritmo y tipo de token
    json header = {
        {"alg", "HS256"},
        {"typ", "JWT"}
    };
    
    // Calcular tiempo de expiración
    auto now = std::chrono::system_clock::now();
    auto expTime = now + std::chrono::hours(expiryHours);
    auto expTimeT = std::chrono::system_clock::to_time_t(expTime);
    
    // Payload - datos del usuario y claims
    json payload = {
        {"user_id", user.id},
        {"username", user.username},
        {"subscription_tier", user.subscriptionTier},
        {"role", user.role},
        {"exp", expTimeT},
        {"iat", std::chrono::system_clock::to_time_t(now)}
    };
    
    // Codificar header y payload en base64
    std::string headerBase64 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9";  // Simplificado
    std::string payloadBase64 = "eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIn0";  // Simplificado
    
    // Firma
    std::string dataToSign = headerBase64 + "." + payloadBase64;
    std::string signature = "signaturewouldgohere";  // Simplificado
    
    // Combinar todo
    return headerBase64 + "." + payloadBase64 + "." + signature;
}

bool AuthService::validateJWT(const std::string& token, const std::string& secret, UserInfo& outUser) {
    // Este es un ejemplo simplificado. En producción, valida correctamente la firma y expiración
    
    // Dividir token en 3 partes: header.payload.signature
    size_t firstDot = token.find('.');
    size_t secondDot = token.find('.', firstDot + 1);
    
    if (firstDot == std::string::npos || secondDot == std::string::npos) {
        return false;
    }
    
    std::string payloadBase64 = token.substr(firstDot + 1, secondDot - firstDot - 1);
    
    // En un sistema real, decodificaríamos base64 y verificaríamos la firma
    // Para este ejemplo, simplificamos
    
    // Simular decodificación y extracción de datos del usuario
    outUser.id = 1;  // Simulado
    outUser.username = "admin";  // Simulado
    outUser.subscriptionTier = "enterprise";  // Simulado
    outUser.role = "admin";  // Simulado
    
    return true;
}

std::string AuthService::generateAPIKey(int userId, const std::string& dbPath, const std::string& prefix) {
    // Generar una API key aleatoria
    unsigned char randomBytes[16];
    RAND_bytes(randomBytes, sizeof(randomBytes));
    
    std::stringstream ss;
    ss << prefix;
    for (int i = 0; i < sizeof(randomBytes); i++) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(randomBytes[i]);
    }
    std::string apiKey = ss.str();
    
    // Guardar en la base de datos
    sqlite3* db;
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return "";
    }
    
    const char* sql = "INSERT INTO api_keys (user_id, api_key) VALUES (?, ?)";
    sqlite3_stmt* stmt;
    
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        sqlite3_close(db);
        return "";
    }
    
    sqlite3_bind_int(stmt, 1, userId);
    sqlite3_bind_text(stmt, 2, apiKey.c_str(), -1, SQLITE_STATIC);
    
    rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    if (rc != SQLITE_DONE) {
        return "";
    }
    
    return apiKey;
}

bool AuthService::validateAPIKey(const std::string& apiKey, const std::string& dbPath, UserInfo& outUser) {
    sqlite3* db;
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return false;
    }
    
    const char* sql = "SELECT u.id, u.username, COALESCE(s.tier, 'free') as tier "
                      "FROM users u "
                      "JOIN api_keys k ON u.id = k.user_id "
                      "LEFT JOIN subscriptions s ON u.id = s.user_id AND s.end_date > datetime('now') "
                      "WHERE k.api_key = ? AND k.is_active = 1 "
                      "ORDER BY s.end_date DESC LIMIT 1";
    
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        sqlite3_close(db);
        return false;
    }
    
    sqlite3_bind_text(stmt, 1, apiKey.c_str(), -1, SQLITE_STATIC);
    
    bool validated = false;
    
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        outUser.id = sqlite3_column_int(stmt, 0);
        outUser.username = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        outUser.subscriptionTier = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
        outUser.role = "user";  // Por defecto
        
        // Actualizar último uso
        sqlite3_finalize(stmt);
        const char* updateSql = "UPDATE api_keys SET last_used = datetime('now') WHERE api_key = ?";
        rc = sqlite3_prepare_v2(db, updateSql, -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, apiKey.c_str(), -1, SQLITE_STATIC);
            sqlite3_step(stmt);
        }
        
        validated = true;
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return validated;
}

bool AuthService::checkQuotaAndUpdate(int userId, const std::string& actionType, const std::string& dbPath) {
    sqlite3* db;
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return false;
    }
    
    // Obtener nivel de suscripción del usuario
    std::string tier = "free";
    const char* tierSql = "SELECT tier FROM subscriptions WHERE user_id = ? AND end_date > datetime('now') ORDER BY end_date DESC LIMIT 1";
    sqlite3_stmt* stmt;
    
    rc = sqlite3_prepare_v2(db, tierSql, -1, &stmt, nullptr);
    if (rc == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, userId);
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            tier = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        }
    }
    sqlite3_finalize(stmt);
    
    // Verificar cuota según el tipo de acción
    bool withinQuota = false;
    
    if (actionType == "query") {
        // Verificar queries diarias
        const char* querySql = "SELECT COUNT(*) FROM usage_records "
                             "WHERE user_id = ? AND action_type = 'query' "
                             "AND timestamp > datetime('now', 'start of day')";
        
        rc = sqlite3_prepare_v2(db, querySql, -1, &stmt, nullptr);
        if (rc == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, userId);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                int queryCount = sqlite3_column_int(stmt, 0);
                
                // Obtener límite de consultas diarias
                sqlite3_finalize(stmt);
                const char* limitSql = "SELECT daily_queries FROM quotas WHERE tier = ?";
                rc = sqlite3_prepare_v2(db, limitSql, -1, &stmt, nullptr);
                
                if (rc == SQLITE_OK) {
                    sqlite3_bind_text(stmt, 1, tier.c_str(), -1, SQLITE_STATIC);
                    if (sqlite3_step(stmt) == SQLITE_ROW) {
                        int queryLimit = sqlite3_column_int(stmt, 0);
                        withinQuota = (queryCount < queryLimit);
                    }
                }
            }
        }
    } else if (actionType == "document" || actionType == "openai" || actionType == "ocr" || actionType == "tts") {
        // Implementar verificaciones similares para otros tipos de acciones
        // Por simplicidad, asumimos que está dentro de la cuota
        withinQuota = true;
    }
    
    sqlite3_finalize(stmt);
    
    // Si está dentro de la cuota, registrar el uso
    if (withinQuota) {
        const char* insertSql = "INSERT INTO usage_records (user_id, action_type) VALUES (?, ?)";
        rc = sqlite3_prepare_v2(db, insertSql, -1, &stmt, nullptr);
        
        if (rc == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, userId);
            sqlite3_bind_text(stmt, 2, actionType.c_str(), -1, SQLITE_STATIC);
            sqlite3_step(stmt);
        }
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return withinQuota;
}

AuthService::UsageStats AuthService::getUserUsage(int userId, const std::string& dbPath) {
    UsageStats stats = {0, 0, 0, 0, 0};
    
    sqlite3* db;
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return stats;
    }
    
    // Obtener estadísticas del mes actual
    const char* sql = "SELECT action_type, COUNT(*) FROM usage_records "
                    "WHERE user_id = ? AND timestamp > datetime('now', 'start of month') "
                    "GROUP BY action_type";
    
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    
    if (rc == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, userId);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::string actionType = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            int count = sqlite3_column_int(stmt, 1);
            
            if (actionType == "query") {
                stats.queries = count;
            } else if (actionType == "document") {
                stats.documents = count;
            } else if (actionType == "openai") {
                stats.openai = count;
            } else if (actionType == "ocr") {
                stats.ocr = count;
            } else if (actionType == "tts") {
                stats.tts = count;
            }
        }
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return stats;
}

AuthService::QuotaLimits AuthService::getQuotaLimits(const std::string& subscriptionTier, const std::string& dbPath) {
    QuotaLimits limits = {0, 0, 0, 0, 0};
    
    sqlite3* db;
    int rc = sqlite3_open(dbPath.c_str(), &db);
    if (rc) {
        std::cerr << "No se pudo abrir la base de datos: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return limits;
    }
    
    const char* sql = "SELECT daily_queries, monthly_documents, openai_usage, monthly_ocr, monthly_tts_minutes "
                    "FROM quotas WHERE tier = ?";
    
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
    
    if (rc == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, subscriptionTier.c_str(), -1, SQLITE_STATIC);
        
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            limits.dailyQueries = sqlite3_column_int(stmt, 0);
            limits.monthlyDocuments = sqlite3_column_int(stmt, 1);
            limits.openaiUsage = sqlite3_column_int(stmt, 2);
            limits.monthlyOcr = sqlite3_column_int(stmt, 3);
            limits.monthlyTtsMinutes = sqlite3_column_int(stmt, 4);
        }
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    return limits;
}
EOF

# 2. Motor IA Migrante
echo "Generando IA Migrante Engine..."

cat > ia_migrante_engine/include/ia_migrante_client.h << 'EOF'
#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>

class IAMigranteClient {
public:
    struct QueryResult {
        std::string response;
        float confidence;
        std::string source;
    };
    
    static QueryResult processQuery(const std::string& query, const std::string& language, const std::string& knowledgeBasePath);
    
private:
    static std::string detectIntentFromQuery(const std::string& query);
    static std::vector<std::string> extractKeywords(const std::string& query);
    static float calculateConfidence(const std::string& response);
};

class KnowledgeBase {
public:
    KnowledgeBase(const std::string& basePath);
    
    std::string findResponse(const std::string& intent, const std::vector<std::string>& keywords, const std::string& language);
    
private:
    std::string basePath;
    std::unordered_map<std::string, std::unordered_map<std::string, std::vector<std::string>>> knowledgeData;
    std::mutex dataMutex;
    
    void loadKnowledgeData(const std::string& language);
    bool isDataLoaded(const std::string& language);
};
EOF

cat > ia_migrante_engine/src/ia_migrante_client.cpp << 'EOF'
#include "ia_migrante_client.h"
#include <iostream>
#include <fstream>
#include <regex>
#include <algorithm>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

// Singleton para la base de conocimiento
static std::unordered_map<std::string, KnowledgeBase*> knowledgeBases;
static std::mutex kbMutex;

KnowledgeBase* getKnowledgeBase(const std::string& basePath) {
    std::lock_guard<std::mutex> lock(kbMutex);
    if (knowledgeBases.find(basePath) == knowledgeBases.end()) {
        knowledgeBases[basePath] = new KnowledgeBase(basePath);
    }
    return knowledgeBases[basePath];
}

IAMigranteClient::QueryResult IAMigranteClient::processQuery(const std::string& query, const std::string& language, const std::string& knowledgeBasePath) {
    QueryResult result;
    
    // Detectar la intención de la consulta
    std::string intent = detectIntentFromQuery(query);
    
    // Extraer palabras clave
    std::vector<std::string> keywords = extractKeywords(query);
    
    // Buscar en la base de conocimiento
    KnowledgeBase* kb = getKnowledgeBase(knowledgeBasePath);
    result.response = kb->findResponse(intent, keywords, language);
    
    // Calcular confianza
    result.confidence = calculateConfidence(result.response);
    result.source = "knowledge_base";
    
    // Si la confianza es baja, podríamos implementar un fallback a OpenAI aquí
    if (result.confidence < 0.5) {
        result.response = "No tengo suficiente información para responder a esa consulta de inmigración. Te recomendaría consultar con un abogado especializado en inmigración.";
        result.confidence = 0.7;
        result.source = "fallback";
    }
    
    return result;
}

std::string IAMigranteClient::detectIntentFromQuery(const std::string& query) {
    // Implementación simple basada en palabras clave
    std::string lowerQuery = query;
    std::transform(lowerQuery.begin(), lowerQuery.end(), lowerQuery.begin(), ::tolower);
    
    if (lowerQuery.find("visa") != std::string::npos) {
        return "visa_info";
    } else if (lowerQuery.find("ciudadania") != std::string::npos || 
              lowerQuery.find("ciudadanía") != std::string::npos || 
              lowerQuery.find("citizenship") != std::string::npos) {
        return "citizenship";
    } else if (lowerQuery.find("green card") != std::string::npos || 
              lowerQuery.find("residencia") != std::string::npos) {
        return "green_card";
    } else if (lowerQuery.find("asilo") != std::string::npos || 
              lowerQuery.find("asylum") != std::string::npos) {
        return "asylum";
    } else if (lowerQuery.find("deportacion") != std::string::npos || 
              lowerQuery.find("deportación") != std::string::npos || 
              lowerQuery.find("deportation") != std::string::npos) {
        return "deportation";
    } else if (lowerQuery.find("daca") != std::string::npos) {
        return "daca";
    } else if (lowerQuery.find("tps") != std::string::npos) {
        return "tps";
    } else if (lowerQuery.find("i-") != std::string::npos) {
        // Buscar formularios I-XXX
        std::regex formRegex("i-[0-9]+");
        std::smatch match;
        if (std::regex_search(lowerQuery, match, formRegex)) {
            return match.str(0);
        }
    }
    
    return "general_immigration";
}

std::vector<std::string> IAMigranteClient::extractKeywords(const std::string& query) {
    std::vector<std::string> keywords;
    std::string lowerQuery = query;
    std::transform(lowerQuery.begin(), lowerQuery.end(), lowerQuery.begin(), ::tolower);
    
    // Lista de palabras clave de inmigración
    std::vector<std::string> keywordList = {
        "visa", "green card", "ciudadania", "ciudadanía", "citizenship", 
        "residencia", "asilo", "asylum", "deportacion", "deportación", 
        "deportation", "daca", "tps", "i-130", "i-485", "i-765", "i-601", 
        "i-751", "n-400", "eb1", "eb2", "eb3", "eb4", "eb5", "h1b", 
        "h2a", "h2b", "j1", "f1", "b1", "b2"
    };
    
    for (const auto& keyword : keywordList) {
        if (lowerQuery.find(keyword) != std::string::npos) {
            keywords.push_back(keyword);
        }
    }
    
    return keywords;
}

float IAMigranteClient::calculateConfidence(const std::string& response) {
    // Implementación simple basada en longitud de respuesta
    if (response.empty()) {
        return 0.0;
    }
    
    if (response.length() < 50) {
        return 0.3;
    } else if (response.length() < 200) {
        return 0.6;
    } else {
        return 0.9;
    }
}

// Implementación de KnowledgeBase
KnowledgeBase::KnowledgeBase(const std::string& basePath) : basePath(basePath) {
    // Cargar datos iniciales en inglés y español
    loadKnowledgeData("en");
    loadKnowledgeData("es");
}

std::string KnowledgeBase::findResponse(const std::string& intent, const std::vector<std::string>& keywords, const std::string& language) {
    std::lock_guard<std::mutex> lock(dataMutex);
    
    // Asegurarse de que los datos estén cargados para este idioma
    if (!isDataLoaded(language)) {
        loadKnowledgeData(language);
    }
    
    // Verificar si tenemos datos para este idioma
    if (knowledgeData.find(language) == knowledgeData.end()) {
        // Fallback al inglés si el idioma solicitado no está disponible
        if (language != "en" && knowledgeData.find("en") != knowledgeData.end()) {
            return findResponse(intent, keywords, "en");
        }
        return "Lo siento, no tengo información disponible en este momento.";
    }
    
    // Buscar respuestas basadas en intención
    auto& langData = knowledgeData[language];
    if (langData.find(intent) != langData.end()) {
        // Tomar la primera respuesta disponible
        if (!langData[intent].empty()) {
            return langData[intent][0];
        }
    }
    
    // Si no se encuentra por intención, buscar por palabras clave
    for (const auto& keyword : keywords) {
        for (const auto& category : langData) {
            for (const auto& response : category.second) {
                // Si la respuesta contiene la palabra clave
                if (response.find(keyword) != std::string::npos) {
                    return response;
                }
            }
        }
    }
    
    // Respuesta genérica si no se encuentra nada específico
    if (language == "es") {
        return "Esta es una respuesta general sobre temas de inmigración. Para información más específica, por favor reformule su pregunta o consulte con un abogado de inmigración.";
    } else {
        return "This is a general response about immigration topics. For more specific information, please rephrase your question or consult with an immigration attorney.";
    }
}

void KnowledgeBase::loadKnowledgeData(const std::string& language) {
    std::string filename = basePath + "/knowledge_" + language + ".json";
    std::ifstream file(filename);
    
    if (!file.is_open()) {
        std::cerr << "No se pudo abrir el archivo de conocimiento: " << filename << std::endl;
        
        // Crear datos de prueba básicos si no existe el archivo
        knowledgeData[language]["visa_info"] = {
            language == "es" ? 
            "Las visas son permisos otorgados por el gobierno de EE.UU. para entrar al país. Existen diferentes tipos como turista (B1/B2), estudiante (F1), trabajo (H1B), entre otras." :
            "Visas are permits granted by the U.S. government to enter the country. There are different types such as tourist (B1/B2), student (F1), work (H1B), among others."
        };
        
        knowledgeData[language]["green_card"] = {
            language == "es" ? 
            "La Green Card (Tarjeta de Residencia Permanente) permite a un extranjero vivir y trabajar permanentemente en Estados Unidos. Se puede obtener por familia, empleo, inversión, o asilo, entre otros caminos." :
            "The Green Card (Permanent Resident Card) allows a foreign national to live and work permanently in the United States. It can be obtained through family, employment, investment, or asylum, among other paths."
        };
        
        knowledgeData[language]["citizenship"] = {
            language == "es" ? 
            "La ciudadanía estadounidense puede obtenerse por nacimiento en EE.UU., por tener padres estadounidenses, o por naturalización después de ser residente permanente durante al menos 5 años (3 años si está casado con un ciudadano estadounidense)." :
            "U.S. citizenship can be obtained by birth in the U.S., by having U.S. citizen parents, or through naturalization after being a permanent resident for at least 5 years (3 years if married to a U.S. citizen)."
        };
        
        return;
    }
    
    try {
        json data;
        file >> data;
        
        for (auto& [key, value] : data.items()) {
            std::vector<std::string> responses;
            for (auto& item : value) {
                responses.push_back(item.get<std::string>());
            }
            knowledgeData[language][key] = responses;
        }
    } catch (const std::exception& e) {
        std::cerr << "Error al cargar datos de conocimiento: " << e.what() << std::endl;
    }
}

bool KnowledgeBase::isDataLoaded(const std::string& language) {
    return knowledgeData.find(language) != knowledgeData.end();
}
EOF

# 3. Servicio OCR
echo "Generando OCR Service..."

cat > legal_ocr_service/include/ocr_client.h << 'EOF'
#pragma once

#include <string>
#include <vector>
#include <unordered_map>

class OCRClient {
public:
    struct OCRResult {
        std::string fullText;
        float confidence;
        std::vector<std::string> pages;
        std::unordered_map<std::string, std::string> extractedFields;
    };
    
    static OCRResult processDocument(const std::vector<uint8_t>& documentData, const std::string& documentFormat);
    
private:
    static std::string detectDocumentType(const std::string& text);
    static std::unordered_map<std::string, std::string> extractFields(const std::string& text, const std::string& documentType);
    static float calculateOCRConfidence(const std::string& text);
};
EOF

cat > legal_ocr_service/src/ocr_client.cpp << 'EOF'
#include "ocr_client.h"
#include <iostream>
#include <regex>

OCRClient::OCRResult OCRClient::processDocument(const std::vector<uint8_t>& documentData, const std::string& documentFormat) {
    OCRResult result;
    
    // En un sistema real, aquí utilizaríamos Tesseract para procesar el documento
    // Para este ejemplo, simularemos el resultado
    
    // Simular el texto extraído según el formato
    if (documentFormat == "pdf" || documentFormat == "jpg" || documentFormat == "png") {
        // Texto simulado de un documento de inmigración
        result.fullText = "DEPARTMENT OF HOMELAND SECURITY\n"
                         "U.S. Citizenship and Immigration Services\n\n"
                         "I-485, APPLICATION TO REGISTER PERMANENT RESIDENCE\n\n"
                         "Applicant: JOHN DOE\n"
                         "A-Number: A123456789\n"
                         "Date of Birth: 01/01/1980\n"
                         "Country of Birth: MEXICO\n"
                         "Current Status: B-2 VISITOR\n"
                         "Receipt Number: MSC2109876543\n"
                         "Priority Date: 06/15/2018\n\n"
                         "This document contains information about your application...";
        
        // Simular páginas
        result.pages.push_back("Page 1: Header and Personal Information");
        result.pages.push_back("Page 2: Application Details");
        
        // Detectar tipo de documento
        std::string documentType = detectDocumentType(result.fullText);
        
        // Extraer campos específicos
        result.extractedFields = extractFields(result.fullText, documentType);
        
        // Calcular confianza
        result.confidence = calculateOCRConfidence(result.fullText);
    } else {
        // Formato no soportado
        result.fullText = "Unsupported document format";
        result.confidence = 0.0;
    }
    
    return result;
}

std::string OCRClient::detectDocumentType(const std::string& text) {
    // Detectar el tipo de formulario basado en patrones en el texto
    if (text.find("I-485") != std::string::npos) {
        return "I-485";
    } else if (text.find("I-130") != std::string::npos) {
        return "I-130";
    } else if (text.find("I-751") != std::string::npos) {
        return "I-751";
    } else if (text.find("N-400") != std::string::npos) {
        return "N-400";
    } else if (text.find("I-765") != std::string::npos) {
        return "I-765";
    } else if (text.find("I-601") != std::string::npos) {
        return "I-601";
    }
    
    return "unknown";
}

std::unordered_map<std::string, std::string> OCRClient::extractFields(const std::string& text, const std::string& documentType) {
    std::unordered_map<std::string, std::string> fields;
    
    // Extraer campos comunes usando expresiones regulares
    std::regex nameRegex("Applicant:\\s*([A-Z\\s]+)");
    std::regex aNumberRegex("A-Number:\\s*(A[0-9]+)");
    std::regex dobRegex("Date of Birth:\\s*([0-9]{2}/[0-9]{2}/[0-9]{4})");
    std::regex countryRegex("Country of Birth:\\s*([A-Z\\s]+)");
    
    std::smatch match;
    
    if (std::regex_search(text, match, nameRegex) && match.size() > 1) {
        fields["applicant_name"] = match[1];
    }
    
    if (std::regex_search(text, match, aNumberRegex) && match.size() > 1) {
        fields["a_number"] = match[1];
    }
    
    if (std::regex_search(text, match, dobRegex) && match.size() > 1) {
        fields["date_of_birth"] = match[1];
    }
    
    if (std::regex_search(text, match, countryRegex) && match.size() > 1) {
        fields["country_of_birth"] = match[1];
    }
    
    // Campos específicos según el tipo de documento
    if (documentType == "I-485") {
        std::regex receiptRegex("Receipt Number:\\s*([A-Z0-9]+)");
        std::regex priorityRegex("Priority Date:\\s*([0-9]{2}/[0-9]{2}/[0-9]{4})");
        
        if (std::regex_search(text, match, receiptRegex) && match.size() > 1) {
            fields["receipt_number"] = match[1];
        }
        
        if (std::regex_search(text, match, priorityRegex) && match.size() > 1) {
            fields["priority_date"] = match[1];
        }
    }
    
    return fields;
}

float OCRClient::calculateOCRConfidence(const std::string& text) {
    // En un sistema real, esto se basaría en la confianza que reporta Tesseract
    // Para este ejemplo, simularemos basado en la longitud del texto
    
    if (text.empty()) {
        return 0.0;
    }
    
    if (text.length() < 100) {
        return 0.5; // Poca confianza si hay poco texto
    } else if (text.length() < 500) {
        return 0.8; // Confianza media
    } else {
        return 0.95; // Alta confianza para documentos con mucho texto
    }
}
EOF

# 4. Servicio TTS
echo "Generando TTS Service..."

cat > tts_service/include/tts_client.h << 'EOF'
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
EOF

cat > tts_service/src/tts_client.cpp << 'EOF'
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
EOF

# 5. Servicio de Aprendizaje
echo "Generando Learning Service..."

cat > learning_service/include/learning_engine.h << 'EOF'
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
EOF

cat > learning_service/src/learning_engine.cpp << 'EOF'
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
EOF

# 6. API Gateway mejorado
echo "Generando API Gateway mejorado..."

cat > api_gateway/src/main.cpp << 'EOF'
#include <iostream>
#include <fstream>
#include <string>
#include <thread>
#include <chrono>
#include <crow.h>
#include <nlohmann/json.hpp>
#include "auth_service.h"
#include "ia_migrante_client.h"
#include "ocr_client.h"
#include "tts_client.h"
#include "learning_engine.h"

using json = nlohmann::json;

// Variables globales para configuración
std::string dbPath = "data/iam_database.db";
std::string jwtSecret = "iam_secret_key_change_in_production";
int tokenExpiryHours = 24;
std::string apiKeyPrefix = "iam_";
std::string knowledgeBasePath = "ia_migrante_engine/data";
std::shared_ptr<LearningEngine> learningEngine;

// Función para cargar la configuración
bool loadConfig(const std::string& configPath) {
    try {
        std::ifstream configFile(configPath);
        if (!configFile.is_open()) {
            std::cerr << "No se pudo abrir el archivo de configuración: " << configPath << std::endl;
            // Usar valores por defecto
            return false;
        }
        
        json config;
        configFile >> config;
        
        if (config.contains("database") && config["database"].contains("path")) {
            dbPath = config["database"]["path"];
        }
        
        if (config.contains("auth")) {
            if (config["auth"].contains("jwt_secret")) {
                jwtSecret = config["auth"]["jwt_secret"];
            }
            if (config["auth"].contains("token_expiry_hours")) {
                tokenExpiryHours = config["auth"]["token_expiry_hours"];
            }
            if (config["auth"].contains("api_key_prefix")) {
                apiKeyPrefix = config["auth"]["api_key_prefix"];
            }
        }
        
        if (config.contains("ia_migrante") && config["ia_migrante"].contains("knowledge_base_path")) {
            knowledgeBasePath = config["ia_migrante"]["knowledge_base_path"];
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Error al cargar la configuración: " << e.what() << std::endl;
        return false;
    }
}

// Middleware para autenticación
struct AuthMiddleware {
    struct Context {
        AuthService::UserInfo user;
        bool authenticated = false;
    };
    
    void before_handle(crow::request& req, crow::response& res, Context& ctx) {
        // Verificar token JWT
        std::string authHeader = req.get_header_value("Authorization");
        if (!authHeader.empty() && authHeader.substr(0, 7) == "Bearer ") {
            std::string token = authHeader.substr(7);
            if (AuthService::validateJWT(token, jwtSecret, ctx.user)) {
                ctx.authenticated = true;
                return;
            }
        }
        
        // Verificar API Key
        std::string apiKey = req.get_header_value("X-API-Key");
        if (!apiKey.empty() && apiKey.substr(0, apiKeyPrefix.length()) == apiKeyPrefix) {
            if (AuthService::validateAPIKey(apiKey, dbPath, ctx.user)) {
                ctx.authenticated = true;
                return;
            }
        }
        
        // Si llega aquí, no está autenticado
        res.code = 401;
        res.body = "{\"error\":\"Unauthorized\"}";
        res.end();
    }
    
    void after_handle(crow::request& /*req*/, crow::response& /*res*/, Context& /*ctx*/) {
        // Podemos agregar logging o acciones post-procesamiento aquí
    }
};

int main() {
    std::cout << "Iniciando API IA Migrante..." << std::endl;
    
    // Cargar configuración
    bool configLoaded = loadConfig("config/config.json");
    if (!configLoaded) {
        std::cout << "Usando configuración por defecto" << std::endl;
    }
    
    // Inicializar el motor de aprendizaje
    try {
        learningEngine = std::make_shared<LearningEngine>(dbPath);
        std::cout << "Motor de aprendizaje inicializado correctamente" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Error al inicializar el motor de aprendizaje: " << e.what() << std::endl;
        std::cout << "Continuando sin el motor de aprendizaje" << std::endl;
    }
    
    // Configurar el servidor Crow
    crow::App<crow::CORSHandler, AuthMiddleware> app;
    
    // Configurar CORS
    auto& cors = app.get_middleware<crow::CORSHandler>();
    cors.global()
        .headers("X-API-Key", "Authorization", "Content-Type")
        .methods("POST"_method, "GET"_method, "PUT"_method, "DELETE"_method);
    
    // Endpoint de información
    CROW_ROUTE(app, "/")
    ([]() {
        json info;
        info["name"] = "IA Migrante API";
        info["version"] = "1.0.0";
        info["status"] = "running";
        return crow::response(info.dump(4));
    });
    
    // Endpoint para autenticación
    CROW_ROUTE(app, "/auth/token").methods("POST"_method)
    ([&](const crow::request& req) {
        try {
            auto params = crow::json::load(req.body);
            if (!params) {
                return crow::response(400, "{\"error\":\"Invalid JSON\"}");
            }
            
            std::string username = params["username"].s();
            std::string password = params["password"].s();
            
            AuthService::UserInfo user;
            if (AuthService::authenticateUser(username, password, dbPath, user)) {
                std::string token = AuthService::generateJWT(user, jwtSecret, tokenExpiryHours);
                
                json response;
                response["token"] = token;
                response["user_id"] = user.id;
                response["username"] = user.username;
                response["subscription_tier"] = user.subscriptionTier;
                
                return crow::response(200, response.dump());
            } else {
                return crow::response(401, "{\"error\":\"Invalid credentials\"}");
            }
        } catch (const std::exception& e) {
            return crow::response(500, "{\"error\":\"" + std::string(e.what()) + "\"}");
        }
    });
    
    // Endpoint para generar API Key
    CROW_ROUTE(app, "/auth/api-key").methods("POST"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& /*req*/, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            std::string apiKey = AuthService::generateAPIKey(ctx.user.id, dbPath, apiKeyPrefix);
            if (apiKey.empty()) {
                res.code = 500;
                res.body = "{\"error\":\"Failed to generate API key\"}";
                return res;
            }
            
            json response;
            response["api_key"] = apiKey;
            
            res.code = 200;
            res.body = response.dump();
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para consultas de inmigración
    CROW_ROUTE(app, "/api/v1/immigration/query").methods("POST"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& req, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            // Verificar cuota
            if (!AuthService::checkQuotaAndUpdate(ctx.user.id, "query", dbPath)) {
                res.code = 429;
                res.body = "{\"error\":\"Quota exceeded for queries\"}";
                return res;
            }
            
            auto params = crow::json::load(req.body);
            if (!params) {
                res.code = 400;
                res.body = "{\"error\":\"Invalid JSON\"}";
                return res;
            }
            
            std::string query = params["query"].s();
            std::string language = params.has("language") ? params["language"].s() : "es";
            
            // Si tenemos motor de aprendizaje, intentar buscar en caché o patrones aprendidos
            if (learningEngine) {
                auto patternMatch = learningEngine->findMatchingPattern(query);
                if (patternMatch.confidence > 0.7) {
                    // Usar respuesta aprendida
                    json response;
                    response["response"] = patternMatch.responseTemplate;
                    response["source"] = patternMatch.isExactMatch ? "cache" : "learned";
                    response["confidence"] = patternMatch.confidence;
                    
                    res.code = 200;
                    res.body = response.dump();
                    return res;
                }
            }
            
            // Si no hay coincidencia, usar el motor IA Migrante
            auto result = IAMigranteClient::processQuery(query, language, knowledgeBasePath);
            
            // Guardar en caché/aprendizaje si disponible
            if (learningEngine) {
                learningEngine->recordInteraction(query, result.response, result.confidence);
            }
            
            json response;
            response["response"] = result.response;
            response["source"] = result.source;
            response["confidence"] = result.confidence;
            
            res.code = 200;
            res.body = response.dump();
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para feedback
    CROW_ROUTE(app, "/api/v1/feedback").methods("POST"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& req, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            if (!learningEngine) {
                res.code = 503;
                res.body = "{\"error\":\"Learning engine is not available\"}";
                return res;
            }
            
            auto params = crow::json::load(req.body);
            if (!params) {
                res.code = 400;
                res.body = "{\"error\":\"Invalid JSON\"}";
                return res;
            }
            
            int queryId = params["query_id"].i();
            int score = params["score"].i();
            std::string feedbackText = params.has("feedback") ? params["feedback"].s() : "";
            
            learningEngine->recordFeedback(queryId, ctx.user.id, score, feedbackText);
            
            res.code = 200;
            res.body = "{\"status\":\"success\"}";
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para OCR
    CROW_ROUTE(app, "/api/v1/documents/ocr").methods("POST"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& req, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            // Verificar cuota
            if (!AuthService::checkQuotaAndUpdate(ctx.user.id, "ocr", dbPath)) {
                res.code = 429;
                res.body = "{\"error\":\"Quota exceeded for OCR\"}";
                return res;
            }
            
            auto params = crow::json::load(req.body);
            if (!params || !params.has("file_data") || !params.has("file_type")) {
                res.code = 400;
                res.body = "{\"error\":\"Missing file data or type\"}";
                return res;
            }
            
            // En un sistema real, decodificaríamos base64 aquí
            // Para este ejemplo, usamos datos simulados
            std::vector<uint8_t> fileData = {0x01, 0x02, 0x03, 0x04}; // Simulado
            std::string fileType = params["file_type"].s();
            
            auto result = OCRClient::processDocument(fileData, fileType);
            
            json response;
            response["text"] = result.fullText;
            response["confidence"] = result.confidence;
            
            if (!result.extractedFields.empty()) {
                json fields = json::object();
                for (const auto& field : result.extractedFields) {
                    fields[field.first] = field.second;
                }
                response["fields"] = fields;
            }
            
            res.code = 200;
            res.body = response.dump();
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para TTS
    CROW_ROUTE(app, "/api/v1/tts").methods("POST"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& req, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            // Verificar cuota
            if (!AuthService::checkQuotaAndUpdate(ctx.user.id, "tts", dbPath)) {
                res.code = 429;
                res.body = "{\"error\":\"Quota exceeded for TTS\"}";
                return res;
            }
            
            auto params = crow::json::load(req.body);
            if (!params || !params.has("text")) {
                res.code = 400;
                res.body = "{\"error\":\"Missing text\"}";
                return res;
            }
            
            std::string text = params["text"].s();
            std::string voice = params.has("voice") ? params["voice"].s() : "es_female";
            std::string format = params.has("format") ? params["format"].s() : "mp3";
            float speed = params.has("speed") ? params["speed"].d() : 1.0f;
            
            TTSClient::TTSOptions options;
            options.voice = voice;
            options.speed = speed;
            options.format = (format == "mp3") ? TTSClient::AudioFormat::MP3 :
                           (format == "ogg") ? TTSClient::AudioFormat::OGG :
                           TTSClient::AudioFormat::WAV;
            
            auto result = TTSClient::synthesizeSpeech(text, options);
            
            // Establecer el tipo de contenido adecuado
            res.set_header("Content-Type", result.mimeType);
            res.set_header("Content-Disposition", "attachment; filename=\"speech." + format + "\"");
            
            // Establecer el cuerpo de la respuesta con los datos binarios
            res.body = std::string(result.audioData.begin(), result.audioData.end());
            res.code = 200;
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para obtener voces disponibles
    CROW_ROUTE(app, "/api/v1/tts/voices").methods("GET"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& /*req*/, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            auto voices = TTSClient::getAvailableVoices();
            
            json response;
            response["voices"] = voices;
            
            res.code = 200;
            res.body = response.dump();
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para estadísticas de aprendizaje
    CROW_ROUTE(app, "/api/v1/learning/stats").methods("GET"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& /*req*/, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated || ctx.user.role != "admin") {
            res.code = 403;
            res.body = "{\"error\":\"Unauthorized. Admin role required.\"}";
            return res;
        }
        
        try {
            if (!learningEngine) {
                res.code = 503;
                res.body = "{\"error\":\"Learning engine is not available\"}";
                return res;
            }
            
            auto stats = learningEngine->getStatistics();
            
            json response;
            response["total_patterns"] = stats.totalPatterns;
            response["total_queries"] = stats.totalQueries;
            response["feedback_count"] = stats.feedbackCount;
            response["average_confidence"] = stats.averageConfidence;
            response["patterns_last_month"] = stats.patternsLastMonth;
            
            res.code = 200;
            res.body = response.dump();
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para actualizar patrones
    CROW_ROUTE(app, "/api/v1/learning/update-patterns").methods("POST"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& /*req*/, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated || ctx.user.role != "admin") {
            res.code = 403;
            res.body = "{\"error\":\"Unauthorized. Admin role required.\"}";
            return res;
        }
        
        try {
            if (!learningEngine) {
                res.code = 503;
                res.body = "{\"error\":\"Learning engine is not available\"}";
                return res;
            }
            
            // Este proceso puede ser lento, por lo que podría ejecutarse en un hilo separado
            // Para este ejemplo lo hacemos de manera síncrona
            learningEngine->updatePatterns();
            
            res.code = 200;
            res.body = "{\"status\":\"success\", \"message\":\"Patterns updated successfully\"}";
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint para obtener info de usuario
    CROW_ROUTE(app, "/api/v1/user").methods("GET"_method)
    .middleware<AuthMiddleware>()
    ([&](const crow::request& /*req*/, crow::response& res, AuthMiddleware::Context& ctx) {
        if (!ctx.authenticated) {
            return res;
        }
        
        try {
            json userInfo;
            userInfo["id"] = ctx.user.id;
            userInfo["username"] = ctx.user.username;
            userInfo["subscription_tier"] = ctx.user.subscriptionTier;
            userInfo["role"] = ctx.user.role;
            
            // Obtener estadísticas de uso
            auto usageStats = AuthService::getUserUsage(ctx.user.id, dbPath);
            userInfo["usage"]["queries"] = usageStats.queries;
            userInfo["usage"]["documents"] = usageStats.documents;
            userInfo["usage"]["openai"] = usageStats.openai;
            userInfo["usage"]["ocr"] = usageStats.ocr;
            userInfo["usage"]["tts"] = usageStats.tts;
            
            // Obtener límites de cuota
            auto quotaLimits = AuthService::getQuotaLimits(ctx.user.subscriptionTier, dbPath);
            userInfo["quota"]["daily_queries"] = quotaLimits.dailyQueries;
            userInfo["quota"]["monthly_documents"] = quotaLimits.monthlyDocuments;
            userInfo["quota"]["openai_usage"] = quotaLimits.openaiUsage;
            userInfo["quota"]["monthly_ocr"] = quotaLimits.monthlyOcr;
            userInfo["quota"]["monthly_tts_minutes"] = quotaLimits.monthlyTtsMinutes;
            
            res.code = 200;
            res.body = userInfo.dump();
        } catch (const std::exception& e) {
            res.code = 500;
            res.body = "{\"error\":\"" + std::string(e.what()) + "\"}";
        }
        
        return res;
    });
    
    // Endpoint de diagnóstico
    CROW_ROUTE(app, "/health")
    ([]() {
        json health;
        health["status"] = "ok";
        health["version"] = "1.0.0";
        health["timestamp"] = std::time(nullptr);
        return crow::response(health.dump());
    });
    
    // Iniciar servidor
    std::cout << "Iniciando servidor API en puerto 8080..." << std::endl;
    app.port(8080).multithreaded().run();
    
    return 0;
}
EOF

# 7. Crear directorio data/knowledge para ejemplos
echo "Creando directorio de datos..."
mkdir -p ia_migrante_engine/data

# 8. Crear archivos de conocimiento de ejemplo
cat > ia_migrante_engine/data/knowledge_es.json << 'EOF'
{
  "visa_info": [
    "Las visas son permisos otorgados por el gobierno de EE.UU. para entrar al país. Existen diferentes tipos como turista (B1/B2), estudiante (F1), trabajo (H1B), entre otras. Para solicitar una visa, normalmente debe completar el formulario DS-160, pagar una cuota y asistir a una entrevista en el consulado."
  ],
  "green_card": [
    "La Green Card (Tarjeta de Residencia Permanente) permite a un extranjero vivir y trabajar permanentemente en Estados Unidos. Se puede obtener por familia, empleo, inversión, o asilo, entre otros caminos. El proceso normalmente comienza con una petición (como el I-130 para familiares o I-140 para empleo), seguido por el ajuste de estatus (I-485) o proceso consular."
  ],
  "citizenship": [
    "La ciudadanía estadounidense puede obtenerse por nacimiento en EE.UU., por tener padres estadounidenses, o por naturalización después de ser residente permanente durante al menos 5 años (3 años si está casado con un ciudadano estadounidense). Para naturalizarse, debe completar el formulario N-400, pasar una entrevista y un examen de inglés y educación cívica."
  ],
  "asylum": [
    "El asilo es una protección disponible para personas que han sufrido persecución o temen persecución en su país de origen debido a su raza, religión, nacionalidad, opinión política o pertenencia a determinado grupo social. Puede solicitarse dentro de EE.UU. (afirmativo) o como defensa contra la deportación (defensivo)."
  ],
  "daca": [
    "DACA (Acción Diferida para los Llegados en la Infancia) es un programa que protege temporalmente de la deportación a ciertos jóvenes indocumentados que llegaron a EE.UU. como niños. Proporciona autorización de trabajo pero no estatus legal permanente ni camino a la ciudadanía."
  ],
  "tps": [
    "El Estatus de Protección Temporal (TPS) es un programa que permite a nacionales de países designados permanecer en EE.UU. debido a condiciones temporales peligrosas en su país, como desastres naturales o conflictos armados. Proporciona protección contra la deportación y autorización de trabajo."
  ],
  "i-485": [
    "El formulario I-485 es la Solicitud de Registro de Residencia Permanente o Ajuste de Estatus. Se utiliza para solicitar la residencia permanente (Green Card) mientras está presente en los Estados Unidos. Generalmente, requiere una petición aprobada (como I-130 o I-140) y una visa disponible según el boletín de visas."
  ]
}
EOF

cat > ia_migrante_engine/data/knowledge_en.json << 'EOF'
{
  "visa_info": [
    "Visas are permits granted by the U.S. government to enter the country. There are different types such as tourist (B1/B2), student (F1), work (H1B), among others. To apply for a visa, you typically need to complete the DS-160 form, pay a fee, and attend an interview at the consulate."
  ],
  "green_card": [
    "The Green Card (Permanent Resident Card) allows a foreign national to live and work permanently in the United States. It can be obtained through family, employment, investment, or asylum, among other paths. The process typically begins with a petition (such as I-130 for family or I-140 for employment), followed by adjustment of status (I-485) or consular processing."
  ],
  "citizenship": [
    "U.S. citizenship can be obtained by birth in the U.S., by having U.S. citizen parents, or through naturalization after being a permanent resident for at least 5 years (3 years if married to a U.S. citizen). To naturalize, you must complete form N-400, pass an interview, and an English and civics exam."
  ],
  "asylum": [
    "Asylum is a protection available to people who have suffered persecution or fear persecution in their home country due to race, religion, nationality, political opinion, or membership in a particular social group. It can be requested within the U.S. (affirmative) or as a defense against deportation (defensive)."
  ],
  "daca": [
    "DACA (Deferred Action for Childhood Arrivals) is a program that temporarily protects certain undocumented young people who came to the U.S. as children from deportation. It provides work authorization but no permanent legal status or path to citizenship."
  ],
  "tps": [
    "Temporary Protected Status (TPS) is a program that allows nationals of designated countries to remain in the U.S. due to temporary dangerous conditions in their country, such as natural disasters or armed conflict. It provides protection from deportation and work authorization."
  ],
  "i-485": [
    "Form I-485 is the Application to Register Permanent Residence or Adjust Status. It is used to apply for permanent residence (Green Card) while present in the United States. It typically requires an approved petition (such as I-130 or I-140) and an available visa according to the visa bulletin."
  ]
}
EOF
