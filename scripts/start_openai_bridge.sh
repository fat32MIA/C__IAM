#!/bin/bash

# Activar el entorno virtual
source openai_bridge/venv/bin/activate

# Verificar la API key de OpenAI
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  No se ha establecido OPENAI_API_KEY. Funcionando en modo de demostración."
    export OPENAI_API_KEY="sk-your-api-key-here" # Modo demo
fi

# Iniciar el servidor Flask
cd openai_bridge
echo "🚀 Iniciando OpenAI Bridge en http://localhost:5005"
python app.py
