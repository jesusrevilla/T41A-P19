-- creat
CREATE TABLE rol (
  id SERIAL PRIMARY KEY,
  rol_nombre TEXT NOT NULL
);

INSERT INTO rol (rol_nombre) VALUES 
('administrador'),
('operador');

CREATE TABLE usuario (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  rol INTEGER NOT NULL,
  FOREIGN KEY (rol) REFERENCES rol(id)
);

CREATE TABLE materia_prima (
  id SERIAL PRIMARY KEY,
  ancho NUMERIC NOT NULL,
  alto NUMERIC NOT NULL,
  distancia_minima_entre_piezas NUMERIC NOT NULL,
  distancia_minima_a_orilla NUMERIC NOT NULL
);

CREATE TABLE producto (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  geometria BOX NOT NULL
);

CREATE TABLE pieza (
  id SERIAL PRIMARY KEY,
  producto_id INTEGER NOT NULL,
  descripcion TEXT NOT NULL,
  cantidad_elementos INTEGER NOT NULL,
  FOREIGN KEY (producto_id) REFERENCES producto(id)
);

/*
CREATE TABLE geometria (
  id SERIAL PRIMARY KEY,

);

CREATE TABLE evento (
  id SERIAL PRIMARY KEY,

);*/
