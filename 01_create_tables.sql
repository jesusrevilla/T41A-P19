DROP TABLE IF EXISTS eventos CASCADE;
DROP TABLE IF EXISTS geometrias CASCADE;
DROP TABLE IF EXISTS piezas CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS materia_prima CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- ROLES
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL
);

-- USUARIOS
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    rol_id INT REFERENCES roles(id)
);

-- MATERIA PRIMA
CREATE TABLE materia_prima (
    id SERIAL PRIMARY KEY,
    numero_parte TEXT UNIQUE NOT NULL,
    ancho NUMERIC,
    alto NUMERIC,
    distancia_entre_piezas NUMERIC,
    distancia_borde NUMERIC
);

-- PRODUCTOS
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    numero_parte TEXT UNIQUE NOT NULL,
    descripcion TEXT,
    cantidad_piezas INT
);

-- PIEZAS
CREATE TABLE piezas (
    id SERIAL PRIMARY KEY,
    producto_id INT REFERENCES productos(id),
    nombre TEXT NOT NULL
);

-- GEOMETRÍAS DE PIEZAS
CREATE TABLE geometrias (
    id SERIAL PRIMARY KEY,
    pieza_id INT REFERENCES piezas(id),
    tipo TEXT NOT NULL, -- recta, arco, figura
    datos JSONB NOT NULL
);

-- EVENTOS JSON
CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    pieza_id INT REFERENCES piezas(id),
    evento JSONB,
    fecha TIMESTAMP DEFAULT NOW()
);
