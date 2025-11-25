-- DESCRIPCION: Estructura de tablas y relaciones

-- Limpieza inicial
DROP TABLE IF EXISTS eventos CASCADE;
DROP TABLE IF EXISTS cortes_optimizados CASCADE;
DROP TABLE IF EXISTS geometrias CASCADE;
DROP TABLE IF EXISTS piezas CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS materia_prima CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 1. Tablas de Seguridad
CREATE TABLE roles (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL CHECK (nombre_rol IN ('Administrador', 'Operador')),
    descripcion TEXT
);

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    id_rol INT NOT NULL REFERENCES roles(id_rol),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

-- 2. Inventario
CREATE TABLE materia_prima (
    id_materia SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    ancho NUMERIC(10, 2) NOT NULL CHECK (ancho > 0),
    alto NUMERIC(10, 2) NOT NULL CHECK (alto > 0),
    distancia_min_piezas NUMERIC(10, 2) DEFAULT 0,
    distancia_min_borde NUMERIC(10, 2) DEFAULT 0,
    area_total NUMERIC(12, 2) GENERATED ALWAYS AS (ancho * alto) STORED,
    stock_disponible INT DEFAULT 0
);

CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_alta TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE piezas (
    id_pieza SERIAL PRIMARY KEY,
    id_producto INT NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    nombre_pieza VARCHAR(50),
    cantidad_requerida INT DEFAULT 1,
    area_base NUMERIC(10, 2) 
);

-- 3. Geometría
CREATE TABLE geometrias (
    id_geometria SERIAL PRIMARY KEY,
    id_pieza INT NOT NULL REFERENCES piezas(id_pieza) ON DELETE CASCADE,
    orden_secuencia INT NOT NULL,
    tipo_componente VARCHAR(20) CHECK (tipo_componente IN ('LINEA', 'ARCO', 'CIRCULO')),
    parametros_geo JSONB NOT NULL 
);

-- 4. Operación
CREATE TABLE eventos (
    id_evento SERIAL PRIMARY KEY,
    tipo_evento VARCHAR(50),
    payload_json JSONB NOT NULL,
    procesado BOOLEAN DEFAULT FALSE,
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cortes_optimizados (
    id_corte SERIAL PRIMARY KEY,
    id_materia INT NOT NULL REFERENCES materia_prima(id_materia),
    id_pieza INT NOT NULL REFERENCES piezas(id_pieza),
    posicion_x NUMERIC(10, 2) NOT NULL,
    posicion_y NUMERIC(10, 2) NOT NULL,
    rotacion_grados NUMERIC(5, 2) DEFAULT 0,
    orden_colocacion INT,
    fecha_corte TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Datos mínimos requeridos
INSERT INTO roles (nombre_rol, descripcion) VALUES 
('Administrador', 'Acceso total al sistema'), 
('Operador', 'Acceso limitado a operaciones de corte');