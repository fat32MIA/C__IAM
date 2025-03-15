#!/bin/bash
# scripts/diagnostico.sh
# Script para diagnosticar el estado del proyecto IA Migrante API

echo "====== DIAGNÓSTICO DEL PROYECTO IA MIGRANTE ======"
echo "Fecha: $(date)"
echo "Directorio actual: $(pwd)"
echo ""

# Función para verificar directorios
check_directories() {
  echo "=== Verificando estructura de directorios ==="
  DIRECTORIOS=(
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
    "config"
    "scripts"
    "data"
    "bin"
    "build"
  )

  for dir in "${DIRECTORIOS[@]}"; do
    if [ -d "$dir" ]; then
      echo "✓ Directorio $dir existe"
    else
      echo "✗ Directorio $dir NO existe"
    fi
  done
  echo ""
}

# Función para verificar archivos esenciales
check_essential_files() {
  echo "=== Verificando archivos esenciales ==="
  ARCHIVOS=(
    "CMakeLists.txt"
    "config/config.json"
    "scripts/build.sh"
    "scripts/setup_db.sh"
    "scripts/run.sh"
    "api_gateway/src/main.cpp"
  )

  for file in "${ARCHIVOS[@]}"; do
    if [ -f "$file" ]; then
      echo "✓ Archivo $file existe"
    else
      echo "✗ Archivo $file NO existe"
    fi
  done
  echo ""
}

# Verificar si hay archivos en directorios clave
check_dir_content() {
  echo "=== Verificando contenido de directorios clave ==="
  DIRS_TO_CHECK=(
    "api_gateway/include"
    "api_gateway/src"
    "ia_migrante_engine/include"
    "ia_migrante_engine/src"
    "auth_service/include"
    "auth_service/src"
    "legal_ocr_service/include"
    "legal_ocr_service/src"
    "tts_service/include"
    "tts_service/src"
    "learning_service/include"
    "learning_service/src"
  )

  for dir in "${DIRS_TO_CHECK[@]}"; do
    if [ -d "$dir" ]; then
      file_count=$(find "$dir" -type f | wc -l)
      if [ $file_count -gt 0 ]; then
        echo "✓ Directorio $dir contiene $file_count archivo(s)"
      else
        echo "⚠ Directorio $dir está vacío"
      fi
    fi
  done
  echo ""
}

# Verificar dependencias del sistema
check_dependencies() {
  echo "=== Verificando dependencias del sistema ==="
  DEPENDENCIES=(
    "g++"
    "cmake"
    "sqlite3"
    "pkg-config"
  )

  for dep in "${DEPENDENCIES[@]}"; do
    if command -v $dep &> /dev/null; then
      echo "✓ Dependencia $dep está instalada"
      if [ "$dep" = "g++" ]; then
        echo "  - Versión: $(g++ --version | head -n 1)"
      elif [ "$dep" = "cmake" ]; then
        echo "  - Versión: $(cmake --version | head -n 1)"
      elif [ "$dep" = "sqlite3" ]; then
        echo "  - Versión: $(sqlite3 --version)"
      fi
    else
      echo "✗ Dependencia $dep NO está instalada"
    fi
  done
  echo ""

  # Verificar bibliotecas del sistema
  echo "=== Verificando bibliotecas del sistema ==="
  LIBRARIES=(
    "libboost"
    "libssl"
    "libsqlite3"
    "libcurl"
    "libtesseract"
    "libleptonica"
    "libespeak-ng"
    "libjsoncpp"
  )

  for lib in "${LIBRARIES[@]}"; do
    if ldconfig -p | grep -q "$lib"; then
      echo "✓ Biblioteca $lib está instalada"
    else
      echo "⚠ Biblioteca $lib podría no estar instalada (no encontrada con ldconfig)"
    fi
  done
  echo ""
}

# Verificar estado de compilación
check_build_status() {
  echo "=== Verificando estado de compilación ==="
  if [ -f "bin/iam_api" ]; then
    echo "✓ Ejecutable bin/iam_api existe"
    file_info=$(file bin/iam_api)
    echo "  - Información: $file_info"
    permissions=$(ls -l bin/iam_api)
    echo "  - Permisos: $permissions"
  else
    echo "✗ Ejecutable bin/iam_api NO existe"
  fi

  if [ -d "build" ]; then
    build_files=$(find build -type f | wc -l)
    echo "✓ Directorio build contiene $build_files archivo(s)"
  fi
  echo ""
}

# Verificar base de datos
check_database() {
  echo "=== Verificando base de datos ==="
  if [ -f "data/iam_database.db" ]; then
    echo "✓ Base de datos data/iam_database.db existe"
    db_size=$(du -h data/iam_database.db | cut -f1)
    echo "  - Tamaño: $db_size"
    
    if command -v sqlite3 &> /dev/null; then
      echo "  - Tablas en la base de datos:"
      tables=$(sqlite3 data/iam_database.db ".tables")
      if [ -n "$tables" ]; then
        echo "    $tables"
      else
        echo "    No se encontraron tablas"
      fi
      
      users_count=$(sqlite3 data/iam_database.db "SELECT COUNT(*) FROM users 2>/dev/null" || echo "Error: tabla users no existe")
      echo "  - Número de usuarios: $users_count"
    else
      echo "  - No se puede verificar el contenido (sqlite3 no está instalado)"
    fi
  else
    echo "✗ Base de datos data/iam_database.db NO existe"
  fi
  echo ""
}

# Verificar configuración
check_config() {
  echo "=== Verificando archivos de configuración ==="
  if [ -f "config/config.json" ]; then
    echo "✓ Archivo config/config.json existe"
    if command -v jq &> /dev/null; then
      echo "  - Validando JSON..."
      if jq empty config/config.json 2>/dev/null; then
        echo "    JSON válido"
        echo "  - Secciones configuradas:"
        jq 'keys[]' config/config.json 2>/dev/null | tr -d '"'
      else
        echo "    ⚠ JSON inválido"
      fi
    else
      echo "  - No se puede validar JSON (jq no está instalado)"
    fi
  else
    echo "✗ Archivo config/config.json NO existe"
  fi
  echo ""
}

# Ejecutar todas las verificaciones
check_directories
check_essential_files
check_dir_content
check_dependencies
check_build_status
check_database
check_config

echo "====== FIN DEL DIAGNÓSTICO ======"
echo "Recomendaciones:"
echo "1. Si faltan directorios o archivos esenciales, créalos."
echo "2. Si el ejecutable no existe, ejecuta ./scripts/build.sh"
echo "3. Si la base de datos no existe, ejecuta ./scripts/setup_db.sh"
echo "4. Si faltan dependencias, instálalas con apt-get install"
echo ""
echo "Para un análisis más detallado de problemas específicos,"
echo "ejecuta los comandos individuales recomendados en este diagnóstico."
