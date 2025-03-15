#!/bin/bash
# scripts/run.sh

# Verificar que la base de datos existe
if [ ! -f "data/iam_database.db" ]; then
  echo "La base de datos no existe. Ejecutando script de configuración..."
  ./scripts/setup_db.sh
fi

# Verificar que el ejecutable existe
if [ ! -f "bin/iam_api" ]; then
  echo "Ejecutable no encontrado. Compilando..."
  ./scripts/build.sh
fi

# Ejecutar el servidor API
echo "Iniciando servidor API IA Migrante..."
./bin/iam_api
