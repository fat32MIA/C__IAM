#!/bin/bash
# diagnostico.sh - Script para diagnosticar el proyecto IA Migrante API

echo "====== DIAGNÓSTICO DEL PROYECTO IA MIGRANTE ======"
echo "Fecha: $(date)"
echo "Directorio: $(pwd)"
echo ""

# Verificar directorios
echo "=== ESTRUCTURA DE DIRECTORIOS ==="
for dir in api_gateway/{include,src} ia_migrante_engine/{include,src,data} auth_service/{include,src,db} legal_ocr_service/{include,src} tts_service/{include,src} learning_service/{include,src,models} config scripts data bin build; do
  if [ -d "$dir" ]; then
    echo "✓ $dir existe"
  else
    echo "✗ $dir NO existe"
  fi
done
echo ""

# Verificar archivos esenciales
echo "=== ARCHIVOS ESENCIALES ==="
for file in CMakeLists.txt config/config.json scripts/{build.sh,setup_db.sh,run.sh} api_gateway/src/main.cpp; do
  if [ -f "$file" ]; then
    echo "✓ $file existe"
  else
    echo "✗ $file NO existe"
  fi
done
echo ""

# Verificar dependencias
echo "=== DEPENDENCIAS INSTALADAS ==="
for cmd in g++ cmake sqlite3; do
  if command -v $cmd &> /dev/null; then
    echo "✓ $cmd está instalado"
  else
    echo "✗ $cmd NO está instalado"
  fi
done
echo ""

# Verificar compilación
echo "=== ESTADO DE COMPILACIÓN ==="
if [ -f "bin/iam_api" ]; then
  echo "✓ Ejecutable bin/iam_api existe"
  echo "  - $(file bin/iam_api)"
else
  echo "✗ Ejecutable bin/iam_api NO existe"
fi
echo ""

# Verificar base de datos
echo "=== BASE DE DATOS ==="
if [ -f "data/iam_database.db" ]; then
  echo "✓ Base de datos existe"
  echo "  - Tamaño: $(du -h data/iam_database.db | cut -f1)"
  
  if command -v sqlite3 &> /dev/null; then
    echo "  - Tablas:"
    sqlite3 data/iam_database.db ".tables" 2>/dev/null || echo "    No se pueden mostrar tablas"
  fi
else
  echo "✗ Base de datos NO existe"
fi
echo ""

echo "====== ACCIONES RECOMENDADAS ======"
echo "1. Si faltan directorios: mkdir -p <directorio_faltante>"
echo "2. Si falta el ejecutable: ./scripts/build.sh"
echo "3. Si falta la base de datos: ./scripts/setup_db.sh"
echo "4. Si faltan dependencias: apt-get install <dependencia>"
echo ""
