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
