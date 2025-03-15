// document_service/include/document_service_client.h
#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <curl/curl.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

class DocumentServiceClient {
public:
    DocumentServiceClient(const std::string& baseUrl = "http://localhost:5001");
    ~DocumentServiceClient();
    
    struct DocumentRequest {
        std::string documentType;
        json parameters;
        std::string outputFormat;
    };
    
    struct DocumentResponse {
        bool success;
        std::string message;
        std::vector<uint8_t> documentData;
        std::string contentType;
    };
    
    // Métodos principales
    DocumentResponse generateDocument(const DocumentRequest& request);
    std::vector<std::string> getAvailableTemplates();
    std::vector<std::string> getTemplateQuestions(const std::string& templateId);
    
private:
    std::string baseUrl;
    static size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp);
    static size_t WriteMemoryCallback(void* contents, size_t size, size_t nmemb, void* userp);
    
    // Caché para respuestas
    struct CacheItem {
        std::vector<uint8_t> data;
        std::string contentType;
        time_t timestamp;
    };
    
    std::unordered_map<std::string, CacheItem> cache;
    std::mutex cacheMutex;
    
    // Utilidades HTTP
    std::string httpGet(const std::string& endpoint);
    std::pair<std::vector<uint8_t>, std::string> httpPostWithBinaryResponse(
        const std::string& endpoint, const std::string& jsonData);
};
