DROP TABLE IF EXISTS eventos CASCADE;
DROP TABLE IF EXISTS geometrias CASCADE;
DROP TABLE IF EXISTS piezas CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS materia_prima CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

--*INTEGRANTES:
--177406 Salinas Carrillo Mauricio Josafat
--177139 Moreno Adrian
--177700 De la Rosa Rodríguez Erik
--*
-- Roles del sistema
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL
);

-- Usuarios del sistema
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    rol_id INT REFERENCES roles(id),
    activo BOOLEAN DEFAULT TRUE
);

-- Materia Prima (Láminas, tableros, etc.)
CREATE TABLE materia_prima (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    dimension_ancho NUMERIC(10,2) NOT NULL,
    dimension_alto NUMERIC(10,2) NOT NULL,
    distancia_min_piezas NUMERIC(10,2) DEFAULT 0,
    distancia_min_orilla NUMERIC(10,2) DEFAULT 0,
    area_total NUMERIC(10,2) GENERATED ALWAYS AS (dimension_ancho * dimension_alto) STORED
);

-- Productos finales
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    cantidad_piezas INT DEFAULT 1
);

-- Piezas individuales que componen un producto
CREATE TABLE piezas (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    materia_prima_id INT REFERENCES materia_prima(id), -- Asignación a una lámina
    nombre_pieza VARCHAR(100),
    posicion_x NUMERIC(10,2) DEFAULT 0,
    posicion_y NUMERIC(10,2) DEFAULT 0,
    rotacion_grados NUMERIC(5,2) DEFAULT 0
);

-- Geometría de la pieza (Definición de la forma)
-- Usamos JSONB para guardar coordenadas complejas (segmentos, arcos)
CREATE TABLE geometrias (
    id SERIAL PRIMARY KEY,
    pieza_id INT REFERENCES piezas(id) ON DELETE CASCADE,
    tipo_geometria VARCHAR(50), -- 'rectangulo', 'circulo', 'poligono'
    datos_forma JSONB NOT NULL, -- Ej: {"ancho": 10, "alto": 20} o {"radio": 5}
    area NUMERIC(10,2) -- Área calculada de la pieza individual
);

-- Bitácora de eventos JSON
CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    tipo_evento VARCHAR(50),
    payload JSONB,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    procesado BOOLEAN DEFAULT FALSE
);
