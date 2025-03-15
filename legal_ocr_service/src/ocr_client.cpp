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
