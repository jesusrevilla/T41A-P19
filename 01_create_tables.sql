
-- ROLES Y USUARIOS
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL,
    rol_id INTEGER REFERENCES roles(id)
);

-- MATERIA PRIMA
CREATE TABLE materia_prima (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) NOT NULL UNIQUE,
    ancho NUMERIC NOT NULL,
    alto NUMERIC NOT NULL,
    distancia_minima_piezas NUMERIC NOT NULL,
    distancia_minima_borde NUMERIC NOT NULL,
    fecha_registro TIMESTAMP DEFAULT NOW()
);

-- PRODUCTOS
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT NOT NULL,
    cantidad_elementos INTEGER NOT NULL CHECK (cantidad_elementos > 0)
);

-- PIEZAS
CREATE TABLE piezas (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER REFERENCES productos(id) ON DELETE CASCADE,
    nombre VARCHAR(100),
    ancho NUMERIC NOT NULL,
    alto NUMERIC NOT NULL
);

-- GEOMETRÍAS (segmentos, arcos, figuras)
CREATE TABLE geometrias (
    id SERIAL PRIMARY KEY,
    pieza_id INTEGER REFERENCES piezas(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    datos JSONB NOT NULL,      -- coordenadas, puntos, radios, etc.
    rotacion NUMERIC DEFAULT 0,
    posicion JSONB DEFAULT '{"x":0,"y":0}'
);

-- EVENTOS EN JSON
CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    pieza_id INTEGER REFERENCES piezas(id) ON DELETE CASCADE,
    evento JSONB NOT NULL,
    fecha TIMESTAMP DEFAULT NOW()
);

-- LOG DE UTILIZACIÓN
CREATE TABLE utilizacion (
    id SERIAL PRIMARY KEY,
    materia_prima_id INTEGER REFERENCES materia_prima(id) ON DELETE CASCADE,
    porcentaje NUMERIC NOT NULL,
    fecha TIMESTAMP DEFAULT NOW()
);
