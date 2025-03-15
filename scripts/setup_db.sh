#!/bin/bash
# scripts/setup_db.sh

set -e  # Detener en caso de error

echo "=== Creando estructura de base de datos ==="
mkdir -p data

# Crear el esquema de la base de datos
sqlite3 data/iam_database.db << 'INNEREOF'
-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Tabla de suscripciones
CREATE TABLE IF NOT EXISTS subscriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    tier TEXT NOT NULL,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP,
    auto_renew BOOLEAN DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabla de API keys
CREATE TABLE IF NOT EXISTS api_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    api_key TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP,
    is_active BOOLEAN DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabla de uso
CREATE TABLE IF NOT EXISTS usage_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    action_type TEXT NOT NULL,
    units_used INTEGER DEFAULT 1,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabla de cuotas por nivel
CREATE TABLE IF NOT EXISTS quotas (
    tier TEXT PRIMARY KEY,
    daily_queries INTEGER NOT NULL,
    monthly_documents INTEGER NOT NULL,
    openai_usage INTEGER NOT NULL,
    monthly_ocr INTEGER NOT NULL,
    monthly_tts_minutes INTEGER NOT NULL,
    has_advanced_features BOOLEAN DEFAULT 0
);

-- Tabla para caché de consultas
CREATE TABLE IF NOT EXISTS query_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query_hash TEXT NOT NULL UNIQUE,
    query_text TEXT NOT NULL,
    response_text TEXT NOT NULL,
    confidence FLOAT,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    use_count INTEGER DEFAULT 1,
    valid_until TIMESTAMP
);

-- Tabla para aprendizaje
CREATE TABLE IF NOT EXISTS learning_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query_id INTEGER,
    user_id INTEGER NOT NULL,
    feedback_score INTEGER,
    feedback_text TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (query_id) REFERENCES query_cache(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabla para patrones aprendidos
CREATE TABLE IF NOT EXISTS learned_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_type TEXT NOT NULL,
    pattern_text TEXT NOT NULL,
    response_template TEXT NOT NULL,
    confidence FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP,
    use_count INTEGER DEFAULT 0
);

-- Inicializar cuotas por nivel si no existen
INSERT OR IGNORE INTO quotas (tier, daily_queries, monthly_documents, openai_usage, monthly_ocr, monthly_tts_minutes, has_advanced_features)
VALUES 
    ('free', 10, 2, 5, 5, 10, 0),
    ('basic', 50, 20, 30, 50, 60, 0),
    ('professional', 200, 100, 200, 200, 300, 1),
    ('enterprise', 1000, 500, 1000, 1000, 1000, 1);

-- Usuario administrador inicial
INSERT OR IGNORE INTO users (id, username, password_hash) 
VALUES (1, 'admin', 'admin123');

-- Suscripción admin
INSERT OR IGNORE INTO subscriptions (user_id, tier, end_date) 
VALUES (1, 'enterprise', datetime('now', '+10 years'));

-- API key del admin
INSERT OR IGNORE INTO api_keys (user_id, api_key)
VALUES (1, 'iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3');
INNEREOF

echo "=== Base de datos configurada con éxito ==="
echo "Usuario administrador: admin"
echo "Contraseña: admin123"
echo "API Key: iam_7f8e92a3b5c6d4e2a1f9b8c7d6e5f4a3"
