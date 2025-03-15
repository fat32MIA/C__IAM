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
