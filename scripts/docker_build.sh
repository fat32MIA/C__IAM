#!/bin/bash
# scripts/docker_build.sh

# Crear Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev \
    libssl-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libtesseract-dev \
    libleptonica-dev \
    libespeak-ng-dev \
    libpulse-dev \
    libjsoncpp-dev \
    nlohmann-json3-dev \
    pkg-config \
    wget \
    python3 \
    python3-pip \
    sqlite3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear directorios de trabajo
WORKDIR /app

# Copiar todo el código fuente
COPY . /app/

# Compilar el proyecto
RUN bash scripts/build.sh

# Exponer puerto
EXPOSE 8080

# Comando para iniciar
CMD ["bash", "scripts/run.sh", "--keep-alive"]
EOF

# Construir imagen Docker
docker build -t ia_migrante_api:latest .

echo "Imagen Docker construida como ia_migrante_api:latest"
echo "Puedes ejecutar el contenedor con:"
echo "docker run -p 8080:8080 ia_migrante_api:latest"
