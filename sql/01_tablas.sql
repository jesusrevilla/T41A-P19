CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL,
    id_rol INT REFERENCES roles(id)
);

CREATE TABLE materia_prima (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    ancho NUMERIC NOT NULL,
    alto NUMERIC NOT NULL,
    distancia_entre_piezas NUMERIC DEFAULT 1,
    distancia_borde NUMERIC DEFAULT 1
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    numero_parte VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    cantidad_elementos INT DEFAULT 1
);

CREATE TABLE piezas (
    id SERIAL PRIMARY KEY,
    id_producto INT REFERENCES productos(id),
    area NUMERIC DEFAULT 0
);

CREATE TABLE geometrias (
    id SERIAL PRIMARY KEY,
    id_pieza INT REFERENCES piezas(id),
    datos JSON NOT NULL
);

CREATE TABLE eventos (
    id SERIAL PRIMARY KEY,
    id_pieza INT REFERENCES piezas(id),
    evento JSON NOT NULL,
    fecha TIMESTAMP DEFAULT NOW()
);
