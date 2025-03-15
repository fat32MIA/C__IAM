#!/bin/bash
# project_analysis.sh - Script para analizar el estado del proyecto IA Migrante

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}      ANÁLISIS COMPLETO DEL PROYECTO IA MIGRANTE         ${NC}"
echo -e "${BLUE}==========================================================${NC}"
echo -e "Fecha: $(date)"
echo -e "Directorio de análisis: $(pwd)"
echo ""

# Verificar la estructura de directorios
echo -e "${BLUE}[ ESTRUCTURA DE DIRECTORIOS ]${NC}"
EXPECTED_DIRS=(
    "api_gateway/include"
    "api_gateway/src"
    "ia_migrante_engine/include"
    "ia_migrante_engine/src"
    "ia_migrante_engine/data"
    "auth_service/include"
    "auth_service/src"
    "auth_service/db"
    "legal_ocr_service/include"
    "legal_ocr_service/src"
    "tts_service/include"
    "tts_service/src"
    "learning_service/include"
    "learning_service/src"
    "learning_service/models"
    "document_service/include"
    "document_service/src"
    "document_service/templates"
    "config"
    "scripts"
    "data"
    "bin"
    "build"
)

MISSING_DIRS=()
for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e " ✓ ${GREEN}$dir${NC}"
    else
        echo -e " ✗ ${RED}$dir${NC} (falta)"
        MISSING_DIRS+=("$dir")
    fi
done
echo ""

# Verificar archivos clave
echo -e "${BLUE}[ ARCHIVOS CLAVE ]${NC}"
EXPECTED_FILES=(
    "CMakeLists.txt"
    "config/config.json"
    "scripts/build.sh"
    "scripts/setup_db.sh"
    "scripts/run.sh"
    "api_gateway/src/main.cpp"
    "ia_migrante_engine/include/ia_migrante_client.h"
    "ia_migrante_engine/src/ia_migrante_client.cpp"
    "auth_service/include/auth_service.h"
    "auth_service/src/auth_service.cpp"
    "document_service/include/document_service_client.h"
    "document_service/src/document_service_client.cpp"
)

MISSING_FILES=()
for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e " ✓ ${GREEN}$file${NC}"
    else
        echo -e " ✗ ${RED}$file${NC} (falta)"
        MISSING_FILES+=("$file")
    fi
done
echo ""

# Analizar contenido de los directorios
echo -e "${BLUE}[ CONTENIDO DE DIRECTORIOS ]${NC}"
for dir in $(find . -type d -not -path '*/\.*' -not -path '*/build*' | sort); do
    count=$(find "$dir" -maxdepth 1 -type f | wc -l)
    if [ "$count" -eq 0 ] && [ "$dir" != "." ]; then
        echo -e " ${YELLOW}$dir${NC}: vacío"
    else
        echo -e " ${GREEN}$dir${NC}: $count archivos"
    fi
done
echo ""

# Analizar archivos de plantillas
echo -e "${BLUE}[ PLANTILLAS DE DOCUMENTOS ]${NC}"
if [ -d "document_service/templates" ]; then
    template_count=$(find "document_service/templates" -name "*.json" | wc -l)
    echo -e " Encontradas ${GREEN}$template_count${NC} plantillas JSON"
    # Listar algunas plantillas como ejemplo
    echo -e " Ejemplos:"
    find "document_service/templates" -name "*.json" | head -n 5 | while read template; do
        echo -e "   - ${YELLOW}$(basename "$template")${NC}"
    done
    if [ "$template_count" -gt 5 ]; then
        echo -e "   - ... y $(($template_count - 5)) más"
    fi
else
    echo -e " ${RED}No se encontró el directorio de plantillas${NC}"
fi
echo ""

# Análisis del CMakeLists.txt
echo -e "${BLUE}[ ANÁLISIS DE CMAKE ]${NC}"
if [ -f "CMakeLists.txt" ]; then
    echo -e " Verificando contenido de CMakeLists.txt:"
    
    # Verificar búsqueda de dependencias
    deps_found=0
    deps_list=("Boost" "OpenSSL" "CURL" "SQLite3" "Tesseract" "nlohmann_json")
    for dep in "${deps_list[@]}"; do
        if grep -q "find_package($dep" CMakeLists.txt; then
            echo -e "  ✓ ${GREEN}find_package($dep)${NC}"
            ((deps_found++))
        else
            echo -e "  ✗ ${RED}No se encontró find_package($dep)${NC}"
        fi
    done
    
    # Verificar inclusión de directorios
    inc_count=$(grep -c "include_directories" CMakeLists.txt)
    echo -e " Directorios de inclusión: ${YELLOW}$inc_count${NC}"
    
    # Verificar bibliotecas vinculadas
    libs_count=$(grep -c "target_link_libraries" CMakeLists.txt)
    echo -e " Vinculaciones de bibliotecas: ${YELLOW}$libs_count${NC}"
else
    echo -e " ${RED}No se encontró CMakeLists.txt${NC}"
fi
echo ""

# Verificar la base de datos
echo -e "${BLUE}[ BASE DE DATOS ]${NC}"
if [ -d "data" ]; then
    if [ -f "data/iam_database.db" ]; then
        echo -e " ✓ ${GREEN}Base de datos encontrada${NC}"
        
        if command -v sqlite3 &> /dev/null; then
            echo -e " Tablas en la base de datos:"
            tables=$(sqlite3 data/iam_database.db ".tables" 2>/dev/null)
            if [ -n "$tables" ]; then
                for table in $tables; do
                    echo -e "  - ${YELLOW}$table${NC}"
                    
                    # Mostrar esquema de cada tabla
                    echo -e "    Esquema: $(sqlite3 data/iam_database.db ".schema $table" | tr -d '\n' | tr -s ' ' | head -c 100)..."
                    
                    # Contar registros
                    count=$(sqlite3 data/iam_database.db "SELECT COUNT(*) FROM $table" 2>/dev/null || echo "N/A")
                    echo -e "    Registros: ${YELLOW}$count${NC}"
                done
            else
                echo -e "  ${RED}No se encontraron tablas${NC}"
            fi
        else
            echo -e "  ${YELLOW}No se puede analizar la base de datos (sqlite3 no está instalado)${NC}"
        fi
    else
        echo -e " ✗ ${RED}No se encontró el archivo de base de datos${NC}"
    fi
else
    echo -e " ✗ ${RED}No se encontró el directorio de datos${NC}"
fi
echo ""

# Verificar archivos de código fuente en la API Gateway
echo -e "${BLUE}[ ANÁLISIS DEL API GATEWAY ]${NC}"
if [ -f "api_gateway/src/main.cpp" ]; then
    echo -e " ✓ ${GREEN}main.cpp encontrado${NC}"
    
    # Contar endpoints definidos
    endpoint_count=$(grep -c "CROW_ROUTE" api_gateway/src/main.cpp)
    echo -e " Endpoints definidos: ${YELLOW}$endpoint_count${NC}"
    
    # Verificar servicios integrados
    echo -e " Verificando integración de servicios:"
    services=("AuthService" "IAMigranteClient" "OCRClient" "TTSClient" "DocumentServiceClient" "LearningEngine")
    
    for service in "${services[@]}"; do
        if grep -q "$service" api_gateway/src/main.cpp; then
            echo -e "  ✓ ${GREEN}$service integrado${NC}"
        else
            echo -e "  ✗ ${RED}$service no encontrado${NC}"
        fi
    done
else
    echo -e " ✗ ${RED}No se encontró api_gateway/src/main.cpp${NC}"
fi
echo ""

# Verificar los scripts del proyecto
echo -e "${BLUE}[ ANÁLISIS DE SCRIPTS ]${NC}"
if [ -d "scripts" ]; then
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            permissions=$(stat -c "%a" "$script")
            if [ "$permissions" -ge "700" ]; then
                echo -e " ✓ ${GREEN}$script${NC} (ejecutable)"
            else
                echo -e " ! ${YELLOW}$script${NC} (no ejecutable: $permissions)"
            fi
        fi
    done
else
    echo -e " ✗ ${RED}No se encontró el directorio de scripts${NC}"
fi
echo ""

# Verificar archivos de OpenAI Bridge (si existen)
echo -e "${BLUE}[ OPENAI BRIDGE ]${NC}"
if [ -d "openai_bridge" ]; then
    openai_files=$(find openai_bridge -type f | wc -l)
    echo -e " ${GREEN}$openai_files${NC} archivos encontrados en openai_bridge"
    
    # Listar archivos principales
    echo -e " Archivos principales:"
    find openai_bridge -type f -name "*.py" | while read file; do
        echo -e "  - ${YELLOW}$file${NC}"
    done
else
    echo -e " ${RED}No se encontró el directorio openai_bridge${NC}"
    echo -e " ${YELLOW}NOTA: El puente OpenAI es un requisito del proyecto y puede estar faltando${NC}"
fi
echo ""

# Resumen y recomendaciones
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}                       RESUMEN                           ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# Directorios faltantes
if [ ${#MISSING_DIRS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los directorios requeridos están presentes.${NC}"
else
    echo -e "${RED}✗ Faltan ${#MISSING_DIRS[@]} directorios:${NC}"
    for dir in "${MISSING_DIRS[@]}"; do
        echo -e "  - $dir"
    done
fi

# Archivos faltantes
if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los archivos clave están presentes.${NC}"
else
    echo -e "${RED}✗ Faltan ${#MISSING_FILES[@]} archivos:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo -e "  - $file"
    done
fi

# Verificar servicio de OpenAI Bridge
if [ ! -d "openai_bridge" ]; then
    echo -e "${RED}✗ Falta la implementación del OpenAI Bridge.${NC}"
fi

# Verificar número de plantillas
if [ -d "document_service/templates" ]; then
    template_count=$(find "document_service/templates" -name "*.json" | wc -l)
    if [ "$template_count" -lt 5 ]; then
        echo -e "${RED}✗ Se encontraron muy pocas plantillas ($template_count). Se recomiendan al menos 10.${NC}"
    else
        echo -e "${GREEN}✓ Se encontraron $template_count plantillas.${NC}"
    fi
fi

echo ""
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}                   RECOMENDACIONES                       ${NC}"
echo -e "${BLUE}==========================================================${NC}"

# Directorios faltantes
if [ ${#MISSING_DIRS[@]} -gt 0 ]; then
    echo -e "1. Crear los directorios faltantes:"
    for dir in "${MISSING_DIRS[@]}"; do
        echo -e "   mkdir -p $dir"
    done
fi

# OpenAI Bridge
if [ ! -d "openai_bridge" ]; then
    echo -e "2. Implementar el OpenAI Bridge según los requisitos."
    echo -e "   - Crear directorio: mkdir -p openai_bridge/{app,models,prompts}"
    echo -e "   - Crear archivo principal: touch openai_bridge/app.py"
fi

# CMake
if [ ! -f "CMakeLists.txt" ] || [ "$deps_found" -lt "${#deps_list[@]}" ]; then
    echo -e "3. Actualizar el archivo CMakeLists.txt para incluir todas las dependencias y servicios."
fi

# Base de datos
if [ ! -f "data/iam_database.db" ]; then
    echo -e "4. Configurar la base de datos ejecutando: ./scripts/setup_db.sh"
fi

echo ""
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}            CÓMO COMPLETAR EL PROYECTO                   ${NC}"
echo -e "${BLUE}==========================================================${NC}"

echo -e "1. Asegúrate de implementar todos los componentes faltantes"
echo -e "2. Actualiza el archivo main.cpp para integrar todos los servicios"
echo -e "3. Implementa el puente OpenAI si aún no lo has hecho"
echo -e "4. Verifica que las tablas de la base de datos estén correctamente configuradas"
echo -e "5. Prueba cada endpoint individualmente"
echo -e "6. Realiza pruebas de integración entre los diferentes servicios"
echo -e "7. Ejecuta el proyecto completo con: ./scripts/run.sh"

echo ""
echo -e "${BLUE}==========================================================${NC}"
