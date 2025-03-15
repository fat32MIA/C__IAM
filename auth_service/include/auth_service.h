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
