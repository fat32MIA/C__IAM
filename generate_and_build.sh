#!/bin/bash

echo "============================================"
echo "Generando archivos para IA Migrante API..."
echo "============================================"

# Ejecutar el script de generación de archivos
bash generar_archivos.sh

echo "============================================"
echo "Instalando dependencias necesarias..."
echo "============================================"

apt-get update
apt-get install -y build-essential cmake libboost-all-dev libssl-dev \
                   libsqlite3-dev libcurl4-openssl-dev \
                   libtesseract-dev libleptonica-dev \
                   libespeak-ng-dev libpulse-dev \
                   libjsoncpp-dev nlohmann-json3-dev sqlite3

echo "============================================"
echo "Compilando el proyecto..."
echo "============================================"

# Construir el proyecto
./scripts/build.sh

echo "============================================"
echo "Configurando la base de datos..."
echo "============================================"

# Configurar base de datos
./scripts/setup_db.sh

echo "============================================"
echo "¡Compilación completada!"
echo "Para iniciar el servidor: ./scripts/run.sh"
echo "============================================"
