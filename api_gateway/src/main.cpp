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
