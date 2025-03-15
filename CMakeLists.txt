cmake_minimum_required(VERSION 3.10)
project(IAMigrante VERSION 1.0.0)

# Opciones de compilación
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -O2")

# Configurar ruta de búsqueda para Crow
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/third_party/Crow/cmake")

# Buscar dependencias
find_package(Boost REQUIRED COMPONENTS system filesystem thread)
find_package(OpenSSL REQUIRED)
find_package(CURL REQUIRED)
find_package(SQLite3 REQUIRED)
find_package(Tesseract REQUIRED)
find_package(nlohmann_json REQUIRED)

# Directorios de inclusión
include_directories(
    ${PROJECT_SOURCE_DIR}/api_gateway/include
    ${PROJECT_SOURCE_DIR}/ia_migrante_engine/include
    ${PROJECT_SOURCE_DIR}/auth_service/include
    ${PROJECT_SOURCE_DIR}/legal_ocr_service/include
    ${PROJECT_SOURCE_DIR}/tts_service/include
    ${PROJECT_SOURCE_DIR}/learning_service/include
    ${PROJECT_SOURCE_DIR}/document_service/include
    ${PROJECT_SOURCE_DIR}/third_party/Crow/include  # Ruta a Crow
    ${Boost_INCLUDE_DIRS}
    ${OPENSSL_INCLUDE_DIR}
    ${CURL_INCLUDE_DIRS}
    ${SQLite3_INCLUDE_DIRS}
    ${Tesseract_INCLUDE_DIRS}
)

# Definir fuentes para cada componente
file(GLOB API_GATEWAY_SOURCES "${PROJECT_SOURCE_DIR}/api_gateway/src/*.cpp")
file(GLOB IA_MIGRANTE_SOURCES "${PROJECT_SOURCE_DIR}/ia_migrante_engine/src/*.cpp")
file(GLOB AUTH_SERVICE_SOURCES "${PROJECT_SOURCE_DIR}/auth_service/src/*.cpp")
file(GLOB OCR_SERVICE_SOURCES "${PROJECT_SOURCE_DIR}/legal_ocr_service/src/*.cpp")
file(GLOB TTS_SERVICE_SOURCES "${PROJECT_SOURCE_DIR}/tts_service/src/*.cpp")
file(GLOB LEARNING_SERVICE_SOURCES "${PROJECT_SOURCE_DIR}/learning_service/src/*.cpp")
file(GLOB DOCUMENT_SERVICE_SOURCES "${PROJECT_SOURCE_DIR}/document_service/src/*.cpp")

# Biblioteca para componentes compartidos
add_library(iam_common STATIC
    ${IA_MIGRANTE_SOURCES}
    ${AUTH_SERVICE_SOURCES}
    ${OCR_SERVICE_SOURCES}
    ${TTS_SERVICE_SOURCES}
    ${LEARNING_SERVICE_SOURCES}
    ${DOCUMENT_SERVICE_SOURCES}
)

# Ejecutable principal de la API
add_executable(iam_api ${API_GATEWAY_SOURCES})

# Vincular bibliotecas
target_link_libraries(iam_common
    ${Boost_LIBRARIES}
    ${OPENSSL_LIBRARIES}
    ${CURL_LIBRARIES}
    ${SQLite3_LIBRARIES}
    ${Tesseract_LIBRARIES}
    pthread
    dl
)

target_link_libraries(iam_api iam_common)

# Instalar
install(TARGETS iam_api DESTINATION bin)
install(DIRECTORY ${PROJECT_SOURCE_DIR}/ia_migrante_engine/data/ 
        DESTINATION share/ia_migrante/data)

# Copiar archivos de configuración
configure_file(
    ${PROJECT_SOURCE_DIR}/config/config.json
    ${CMAKE_BINARY_DIR}/config.json
    COPYONLY
)
