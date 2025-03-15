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
