-- creat
CREATE TABLE rol (
  id SERIAL PRIMARY KEY,
  rol_nombre TEXT NOT NULL
);

CREATE TABLE usuario (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  rol INTEGER NOT NULL,
  FOREIGN KEY (rol) REFERENCES rol(id)
);

CREATE TABLE materia_prima (
  id SERIAL PRIMARY KEY,
  num_parte VARCHAR(50) UNIQUE NOT NULL,
  ancho NUMERIC NOT NULL,
  alto NUMERIC NOT NULL,
  distancia_minima_entre_piezas NUMERIC NOT NULL,
  distancia_minima_a_orilla NUMERIC NOT NULL,
  area_total NUMERIC(15,2) GENERATED ALWAYS AS (alto * ancho) STORED
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
  nombre_pieza TEXT NOT NULL,
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
  id_materiap INT REFENRENCES materia_prima(id),
  id_usuario INT REFENRENCES usuario (id),
  fecha_hora TIMESTAMP,
  tipo_evento TEXT,
  Descripcion TEXT
);*/
