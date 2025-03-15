C_api_IAM: API Gateway para el Sistema IA Migrante
Descripción General
C_api_IAM es un API Gateway unificado diseñado para integrar y expandir los servicios de la plataforma principal IA Migrante. Este sistema proporciona una capa de integración que conecta los siguientes componentes:

IA Migrante API principal (servicio externo existente)
Servicio de Documentos Legales (puerto 5001)
OpenAI Bridge (implementado para mejorar y analizar contenido)
OCR Legal (para procesamiento de documentos)
TTS (Conversión de texto a voz)
Sistema de Aprendizaje (mejora continua basada en interacciones)
Propósito del Sistema
Esta API Gateway sirve como punto único de acceso que:

Unifica múltiples servicios bajo una sola interfaz
Proporciona autenticación y autorización centralizada
Gestiona cuotas de uso por nivel de suscripción
Enriquece las capacidades de la API principal de IA Migrante
Requisitos
Sistema operativo: Linux
Python 3.8+ (para el componente OpenAI Bridge)
C++ (para el componente principal)
SQLite3
Acceso a la API principal de IA Migrante
Instalación y Configuración
Clonar el repositorio:
bash

Copy
git clone https://github.com/su-usuario/C_api_IAM.git
cd C_api_IAM
Compilar el sistema:
bash

Copy
./scripts/build.sh
Configurar la base de datos:
bash

Copy
./scripts/setup_db.sh
Iniciar los Servicios
Inicie el servidor API Gateway principal:
bash

Copy
./scripts/run.sh
Inicie el OpenAI Bridge (en una terminal separada):
bash

Copy
export OPENAI_API_KEY=su_api_key_aquí  # Opcional, si no se proporciona funcionará en modo simulación
./scripts/start_openai_bridge.sh
El API Gateway estará disponible en http://localhost:8080 y el OpenAI Bridge en http://localhost:5005.

Uso de la API Gateway
Autenticación
La API Gateway requiere autenticación mediante JWT tokens o API Keys.

bash

Copy
# Autenticación con usuario y contraseña
curl -X POST http://localhost:8080/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username":"admin", "password":"admin123"}'

# Uso de API Key (más recomendado para integración)
curl -X GET http://localhost:8080/api/v1/user \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3"
Consultas sobre Inmigración (Conexión con IA Migrante API)
Esta función se integra con la API principal de IA Migrante para proporcionar respuestas enriquecidas.

bash

Copy
curl -X POST http://localhost:8080/api/v1/immigration/query \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "¿Cuáles son los requisitos para una visa K1?",
    "language": "es"
  }'
Documentos Legales (151 plantillas incluidas)
El sistema incluye 151 plantillas listas para usar que se integran con el servicio de documentos en el puerto 5001.

bash

Copy
# Listar todas las plantillas disponibles
curl -X GET http://localhost:8080/api/v1/documents/templates \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3"

# Obtener preguntas para una plantilla específica
curl -X GET http://localhost:8080/api/v1/documents/templates/i130_spouse_1/questions \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3"

# Generar un documento usando una plantilla
curl -X POST http://localhost:8080/api/v1/documents/generate \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3" \
  -H "Content-Type: application/json" \
  -d '{
    "document_type": "i130_spouse_1",
    "parameters": {
      "nombre_completo_del_peticionario": "Juan Pérez",
      "número_de_seguro_social_del_peticionario": "123-45-6789"
    },
    "output_format": "pdf"
  }' \
  --output documento.pdf
Funcionalidad de OCR para Documentos Legales
bash

Copy
curl -X POST http://localhost:8080/api/v1/documents/ocr \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3" \
  -H "Content-Type: application/json" \
  -d '{
    "file_data": "base64_encoded_file_data_here",
    "file_type": "pdf"
  }'
Text-to-Speech (TTS)
bash

Copy
curl -X POST http://localhost:8080/api/v1/tts \
  -H "X-API-Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Este texto será convertido a archivo de audio.",
    "voice": "es_female",
    "format": "mp3"
  }' \
  --output audio.mp3
OpenAI Bridge (Mejora de Contenido)
El OpenAI Bridge proporciona servicios avanzados de IA que complementan la API principal.

bash

Copy
# Mejorar documentos legales
curl -X POST http://localhost:5005/api/documents/enhance \
  -H "Content-Type: application/json" \
  -d '{
    "document": "Solicitud de ajuste de estatus para Juan Pérez.",
    "document_type": "I-485 Cover Letter",
    "focus": "Persuasivo"
  }'

# Analizar casos complejos
curl -X POST http://localhost:5005/api/cases/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "case_details": "Cliente de México, 32 años, entró sin inspección en 2015."
  }'
Integración con la API Principal de IA Migrante
Este sistema está diseñado para funcionar como una extensión de la API principal de IA Migrante. Para configurar la conexión:

Asegúrese de que la API principal de IA Migrante esté operativa
Actualice el archivo config/config.json con la URL correcta:
json

Copy
{
  "ia_migrante_api": {
    "url": "https://api.iamigrante.com",
    "api_key": "su_api_key_de_ia_migrante"
  }
}
Verificación del Sistema
Para comprobar que todos los componentes estén funcionando:

bash

Copy
./simple_test.sh
Este script probará los principales componentes y mostrará un resumen del estado del sistema.

Modelo de Datos
El sistema utiliza una base de datos SQLite con las siguientes tablas principales:

users: Usuarios del sistema
subscriptions: Niveles de suscripción
api_keys: Claves API para autenticación
usage_records: Registro de uso para facturación
query_cache: Caché de consultas frecuentes
learned_patterns: Patrones aprendidos del uso
Diferencias con la API Principal
Esta API Gateway complementa a la API principal de IA Migrante:

Característica	API Principal IA Migrante	API Gateway C_api_IAM
Enfoque	Consultas de inmigración	Integración de servicios
Motor de conocimiento	Completo, actualizado	Basado en caché y aprendizaje
Documentos	Básicos	151 plantillas especializadas
OCR	No incluido	Incluido
TTS	No incluido	Incluido
OpenAI	No integrado	Integrado
Autenticación	Simple	JWT + API Keys
Suscripciones	No gestiona	Sistema completo
Contacto y Soporte
Para soporte técnico sobre esta API Gateway:

Email: soporte-gateway@iamigrante.com
Para consultas sobre la API principal de IA Migrante:

Email: soporte@iamigrante.com
Sitio web: https://iamigrante.com
© 2025 IA Migrante Team. Todos los derechos reservados.




Retry

