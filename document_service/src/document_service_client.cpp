// document_service/src/document_service_client.cpp
#include "document_service_client.h"
#include <iostream>
#include <sstream>
#include <chrono>

DocumentServiceClient::DocumentServiceClient(const std::string& baseUrl) : baseUrl(baseUrl) {
    curl_global_init(CURL_GLOBAL_ALL);
}

DocumentServiceClient::~DocumentServiceClient() {
    curl_global_cleanup();
}

std::vector<std::string> DocumentServiceClient::getAvailableTemplates() {
    std::vector<std::string> templates;
    try {
        std::string response = httpGet("/templates");
        json jsonResponse = json::parse(response);
        
        if (jsonResponse.contains("templates") && jsonResponse["templates"].is_array()) {
            for (const auto& item : jsonResponse["templates"]) {
                templates.push_back(item.get<std::string>());
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Error al obtener plantillas: " << e.what() << std::endl;
    }
    return templates;
}

std::vector<std::string> DocumentServiceClient::getTemplateQuestions(const std::string& templateId) {
    std::vector<std::string> questions;
    try {
        std::string endpoint = "/templates/" + templateId + "/questions";
        std::string response = httpGet(endpoint);
        json jsonResponse = json::parse(response);
        
        if (jsonResponse.contains("questions") && jsonResponse["questions"].is_array()) {
            for (const auto& item : jsonResponse["questions"]) {
                questions.push_back(item.get<std::string>());
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Error al obtener preguntas de plantilla: " << e.what() << std::endl;
    }
    return questions;
}

DocumentServiceClient::DocumentResponse DocumentServiceClient::generateDocument(const DocumentRequest& request) {
    DocumentResponse response;
    response.success = false;
    
    try {
        // Crear JSON para la solicitud
        json requestJson;
        requestJson["document_type"] = request.documentType;
        requestJson["parameters"] = request.parameters;
        requestJson["output_format"] = request.outputFormat;
        
        // Verificar caché
        std::string cacheKey = requestJson.dump();
        {
            std::lock_guard<std::mutex> lock(cacheMutex);
            auto it = cache.find(cacheKey);
            if (it != cache.end()) {
                // Verificar si la caché todavía es válida (menos de 1 hora)
                time_t now = time(nullptr);
                if (now - it->second.timestamp < 3600) {
                    response.success = true;
                    response.documentData = it->second.data;
                    response.contentType = it->second.contentType;
                    return response;
                }
            }
        }
        
        // Enviar solicitud POST
        auto [data, contentType] = httpPostWithBinaryResponse("/generate", requestJson.dump());
        
        if (!data.empty()) {
            response.success = true;
            response.documentData = data;
            response.contentType = contentType;
            
            // Guardar en caché
            {
                std::lock_guard<std::mutex> lock(cacheMutex);
                CacheItem cacheItem;
                cacheItem.data = data;
                cacheItem.contentType = contentType;
                cacheItem.timestamp = time(nullptr);
                cache[cacheKey] = cacheItem;
            }
        } else {
            response.message = "Error al generar documento: respuesta vacía";
        }
    } catch (const std::exception& e) {
        response.message = std::string("Error al generar documento: ") + e.what();
    }
    
    return response;
}

// Implementación de funciones auxiliares
size_t DocumentServiceClient::WriteCallback(void* contents, size_t size, size_t nmemb, void* userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

size_t DocumentServiceClient::WriteMemoryCallback(void* contents, size_t size, size_t nmemb, void* userp) {
    size_t realsize = size * nmemb;
    auto* mem = (std::pair<std::vector<uint8_t>, std::string>*)userp;
    
    size_t currentSize = mem->first.size();
    mem->first.resize(currentSize + realsize);
    memcpy(mem->first.data() + currentSize, contents, realsize);
    
    return realsize;
}

std::string DocumentServiceClient::httpGet(const std::string& endpoint) {
    CURL* curl = curl_easy_init();
    std::string readBuffer;
    std::string url = baseUrl + endpoint;
    
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10);
        
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            throw std::runtime_error(curl_easy_strerror(res));
        }
        
        curl_easy_cleanup(curl);
    } else {
        throw std::runtime_error("Error al inicializar CURL");
    }
    
    return readBuffer;
}

std::pair<std::vector<uint8_t>, std::string> DocumentServiceClient::httpPostWithBinaryResponse(
    const std::string& endpoint, const std::string& jsonData) {
    
    CURL* curl = curl_easy_init();
    std::pair<std::vector<uint8_t>, std::string> result;
    std::string url = baseUrl + endpoint;
    
    if (curl) {
        struct curl_slist* headers = nullptr;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, jsonData.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &result);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30);
        
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            throw std::runtime_error(curl_easy_strerror(res));
        }
        
        // Obtener el tipo de contenido
        char* content_type;
        res = curl_easy_getinfo(curl, CURLINFO_CONTENT_TYPE, &content_type);
        if (res == CURLE_OK && content_type) {
            result.second = content_type;
        }
        
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
    } else {
        throw std::runtime_error("Error al inicializar CURL");
    }
    
    return result;
}
