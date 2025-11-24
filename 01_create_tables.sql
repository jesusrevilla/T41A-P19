CREATE TABLE roles (
    rol_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE usuarios (
    usuario_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol_id INTEGER NOT NULL REFERENCES roles(rol_id)
);

-- Tablas de Materia Prima y Productos
CREATE TABLE materia_prima (
    materia_prima_id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    dimension_largo NUMERIC NOT NULL CHECK (dimension_largo > 0),
    dimension_ancho NUMERIC NOT NULL CHECK (dimension_ancho > 0),
    distancia_min_piezas NUMERIC NOT NULL DEFAULT 0,
    distancia_min_orilla NUMERIC NOT NULL DEFAULT 0
);

CREATE TABLE productos (
    producto_id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    materia_prima_base_id INTEGER NOT NULL REFERENCES materia_prima(materia_prima_id)
);

-- Tablas de Piezas y Optimización
CREATE TABLE piezas (
    pieza_id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES productos(producto_id),
    nombre_pieza VARCHAR(100) NOT NULL,
    cantidad_elementos INTEGER NOT NULL DEFAULT 1 CHECK (cantidad_elementos >= 1),
    geometria_original TEXT NOT NULL
);

CREATE TABLE optimizacion_corte (
    opt_corte_id BIGSERIAL PRIMARY KEY,
    materia_prima_id INTEGER NOT NULL REFERENCES materia_prima(materia_prima_id),
    estado VARCHAR(50) NOT NULL DEFAULT 'En curso',
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    utilizacion_porcentaje NUMERIC DEFAULT 0.0 CHECK (utilizacion_porcentaje >= 0 AND utilizacion_porcentaje <= 100)
);

CREATE TABLE piezas_colocadas (
    pieza_colocada_id BIGSERIAL PRIMARY KEY,
    opt_corte_id BIGINT NOT NULL REFERENCES optimizacion_corte(opt_corte_id),
    pieza_id INTEGER NOT NULL REFERENCES piezas(pieza_id),
    geometria_actual TEXT NOT NULL,
    rotacion_grados NUMERIC DEFAULT 0.0,
    posicion_x NUMERIC DEFAULT 0.0,
    posicion_y NUMERIC DEFAULT 0.0
);

-- Tabla de Eventos (Uso de JSONB)
CREATE TABLE eventos_optimizacion (
    evento_id BIGSERIAL PRIMARY KEY,
    pieza_colocada_id BIGINT REFERENCES piezas_colocadas(pieza_colocada_id),
    opt_corte_id BIGINT NOT NULL REFERENCES optimizacion_corte(opt_corte_id),
    tipo_evento VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    fecha_evento TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
