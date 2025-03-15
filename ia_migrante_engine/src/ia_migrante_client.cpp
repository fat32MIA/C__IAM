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
