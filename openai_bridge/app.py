from flask import Flask, request, jsonify
import openai
import os
import json
import logging
from logging.handlers import RotatingFileHandler

app = Flask(__name__)

# Configuración de logging
if not os.path.exists('logs'):
    os.mkdir('logs')
file_handler = RotatingFileHandler('logs/openai_bridge.log', maxBytes=10240, backupCount=10)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
))
file_handler.setLevel(logging.INFO)
app.logger.addHandler(file_handler)
app.logger.setLevel(logging.INFO)
app.logger.info('OpenAI Bridge startup')

# Configurar API key de OpenAI
openai.api_key = os.environ.get('OPENAI_API_KEY', 'sk-your-api-key-here')
if openai.api_key == 'sk-your-api-key-here':
    app.logger.warning('OPENAI_API_KEY no configurada o establecida al valor por defecto!')

# Cargar prompts
PROMPTS = {}
prompts_dir = os.path.join(os.path.dirname(__file__), 'prompts')
if os.path.exists(prompts_dir):
    for filename in os.listdir(prompts_dir):
        if filename.endswith('.json'):
            try:
                with open(os.path.join(prompts_dir, filename), 'r', encoding='utf-8') as f:
                    prompt_name = os.path.splitext(filename)[0]
                    PROMPTS[prompt_name] = json.load(f)
                    app.logger.info(f'Cargado prompt: {prompt_name}')
            except Exception as e:
                app.logger.error(f'Error al cargar prompt {filename}: {str(e)}')
else:
    app.logger.warning(f'Directorio de prompts no encontrado: {prompts_dir}')
    # Crear prompts básicos por defecto
    PROMPTS["immigration_query_es"] = {
        "role": "system",
        "content": "Eres un experto en leyes de inmigración de Estados Unidos."
    }
    PROMPTS["immigration_query_en"] = {
        "role": "system",
        "content": "You are an expert in U.S. immigration law."
    }
    PROMPTS["document_enhancement"] = {
        "role": "system",
        "content": "Eres un abogado de inmigración experto en redacción de documentos legales."
    }
    PROMPTS["case_analysis"] = {
        "role": "system",
        "content": "Eres un abogado de inmigración especializado en analizar casos complejos."
    }

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "version": "1.0.0"})

@app.route('/api/query', methods=['POST'])
def process_query():
    data = request.json
    if not data:
        return jsonify({"error": "No se proporcionaron datos"}), 400
    
    language = data.get('language', 'es')
    query = data.get('query', '')
    
    if not query:
        return jsonify({"error": "Consulta vacía"}), 400
    
    # Seleccionar el prompt adecuado según el idioma
    prompt_key = f"immigration_query_{language}" if f"immigration_query_{language}" in PROMPTS else "immigration_query_es"
    system_prompt = PROMPTS.get(prompt_key, {"role": "system", "content": "Eres un experto en leyes de inmigración."})
    
    try:
        app.logger.info(f'Procesando consulta: {query[:50]}...')
        
        # Para modo de demostración sin API key real
        if openai.api_key == 'sk-your-api-key-here':
            # Generar una respuesta simulada
            app.logger.warning('Usando respuesta simulada (no hay API key configurada)')
            answer = f"Esta es una respuesta simulada a su consulta sobre inmigración: '{query}'\n\n"
            answer += "1. Este es el primer punto importante sobre el tema.\n"
            answer += "2. Este es el segundo punto a considerar.\n\n"
            answer += "Recuerde que esta información es educativa y no constituye asesoramiento legal."
        else:
            # Llamada real a la API de OpenAI
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt["content"]},
                    {"role": "user", "content": query}
                ],
                temperature=0.7,
                max_tokens=1000
            )
            answer = response.choices[0].message['content']
        
        app.logger.info(f'Respuesta generada: {len(answer)} caracteres')
        
        return jsonify({
            "response": answer,
            "source": "openai",
            "confidence": 0.9
        })
    except Exception as e:
        app.logger.error(f'Error al procesar consulta: {str(e)}')
        return jsonify({"error": str(e)}), 500

@app.route('/api/documents/enhance', methods=['POST'])
def enhance_document():
    data = request.json
    if not data:
        return jsonify({"error": "No se proporcionaron datos"}), 400
    
    document_text = data.get('document', '')
    document_type = data.get('document_type', '')
    focus = data.get('focus', '')
    
    if not document_text:
        return jsonify({"error": "Texto del documento vacío"}), 400
    
    # Obtener el prompt para mejora de documentos
    prompt_key = "document_enhancement"
    system_prompt = PROMPTS.get(prompt_key, {"role": "system", "content": "Eres un experto en redacción de documentos legales de inmigración."})
    
    # Crear el prompt completo
    user_prompt = f"TIPO DE DOCUMENTO: {document_type}\nENFOQUE: {focus}\n\nDOCUMENTO ORIGINAL:\n{document_text}\n\nPor favor, mejora este documento legal manteniendo todos los hechos exactamente como se presentan, pero mejorando su estructura, persuasividad, precisión legal, claridad y profesionalismo."
    
    try:
        app.logger.info(f'Procesando mejora de documento: {document_type} - {len(document_text)} caracteres')
        
        # Para modo de demostración sin API key real
        if openai.api_key == 'sk-your-api-key-here':
            # Generar una respuesta simulada
            app.logger.warning('Usando respuesta simulada (no hay API key configurada)')
            enhanced_document = f"[Documento mejorado de tipo {document_type}]\n\n" + document_text
            # Pequeñas mejoras simuladas
            enhanced_document = enhanced_document.replace("muy", "extremadamente")
            enhanced_document = enhanced_document.replace("bueno", "excelente")
            enhanced_document += "\n\n[Fin del documento mejorado]"
        else:
            # Llamada real a la API de OpenAI
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo-16k",
                messages=[
                    {"role": "system", "content": system_prompt["content"]},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.5,
                max_tokens=4000
            )
            enhanced_document = response.choices[0].message['content']
        
        app.logger.info(f'Documento mejorado: {len(enhanced_document)} caracteres')
        
        return jsonify({
            "enhanced_document": enhanced_document,
            "source": "openai"
        })
    except Exception as e:
        app.logger.error(f'Error al mejorar documento: {str(e)}')
        return jsonify({"error": str(e)}), 500

@app.route('/api/cases/analyze', methods=['POST'])
def analyze_case():
    data = request.json
    if not data:
        return jsonify({"error": "No se proporcionaron datos"}), 400
    
    case_details = data.get('case_details', '')
    
    if not case_details:
        return jsonify({"error": "Detalles del caso vacíos"}), 400
    
    # Obtener el prompt para análisis de casos
    prompt_key = "case_analysis"
    system_prompt = PROMPTS.get(prompt_key, {"role": "system", "content": "Eres un abogado de inmigración especializado en analizar casos complejos."})
    
    try:
        app.logger.info(f'Analizando caso: {len(case_details)} caracteres')
        
        # Para modo de demostración sin API key real
        if openai.api_key == 'sk-your-api-key-here':
            # Generar una respuesta simulada
            app.logger.warning('Usando respuesta simulada (no hay API key configurada)')
            analysis = "EVALUACIÓN GENERAL\nEste caso involucra aspectos importantes de inmigración que requieren análisis detallado.\n\n"
            analysis += "OPCIONES LEGALES\n1. Primera opción legal.\n2. Segunda opción legal.\n\n"
            analysis += "ANÁLISIS DE RIESGOS\nExisten varios riesgos a considerar...\n\n"
            analysis += "ESTRATEGIA RECOMENDADA\nBasado en el análisis, recomendamos...\n\n"
            analysis += "PASOS PRÁCTICOS\n1. Primer paso a seguir.\n2. Segundo paso a seguir."
        else:
            # Llamada real a la API de OpenAI
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo-16k",
                messages=[
                    {"role": "system", "content": system_prompt["content"]},
                    {"role": "user", "content": f"DETALLES DEL CASO:\n{case_details}\n\nPor favor, proporciona un análisis detallado de este caso de inmigración."}
                ],
                temperature=0.5,
                max_tokens=3000
            )
            analysis = response.choices[0].message['content']
        
        app.logger.info(f'Análisis generado: {len(analysis)} caracteres')
        
        # Estructurar la respuesta en secciones
        sections = {
            "overview": "N/A",
            "legal_options": "N/A",
            "risks": "N/A",
            "recommended_strategy": "N/A",
            "next_steps": "N/A"
        }
        
        # Intento simple de extraer secciones
        if "EVALUACIÓN GENERAL" in analysis:
            parts = analysis.split("EVALUACIÓN GENERAL", 1)
            if len(parts) > 1:
                sections["overview"] = parts[1].split("\n\n", 1)[0].strip()
        
        if "OPCIONES LEGALES" in analysis:
            parts = analysis.split("OPCIONES LEGALES", 1)
            if len(parts) > 1:
                sections["legal_options"] = parts[1].split("\n\n", 1)[0].strip()
        
        if "ANÁLISIS DE RIESGOS" in analysis:
            parts = analysis.split("ANÁLISIS DE RIESGOS", 1)
            if len(parts) > 1:
                sections["risks"] = parts[1].split("\n\n", 1)[0].strip()
        
        if "ESTRATEGIA RECOMENDADA" in analysis:
            parts = analysis.split("ESTRATEGIA RECOMENDADA", 1)
            if len(parts) > 1:
                sections["recommended_strategy"] = parts[1].split("\n\n", 1)[0].strip()
        
        if "PASOS PRÁCTICOS" in analysis:
            parts = analysis.split("PASOS PRÁCTICOS", 1)
            if len(parts) > 1:
                sections["next_steps"] = parts[1].split("\n\n", 1)[0].strip()
        
        return jsonify({
            "full_analysis": analysis,
            "sections": sections,
            "source": "openai"
        })
    except Exception as e:
        app.logger.error(f'Error al analizar caso: {str(e)}')
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5005)
