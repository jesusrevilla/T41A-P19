CREATE TABLE usuarios(
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  rol INTEGER NOT NULL
);

CREATE TABLE materia_prima(
  id SERIAL PRIMARY KEY
);

CREATE TABLE productos(
  id SERIAL PRIMARY KEY,
  no_parte INTEGER NOT NULL,
  descripcion TEXT,
  geometria GEOMETRY(CurvePolygon, 0),
  cantidad_elementos INTEGER
);

CREATE TABLE piezas(

);

CREATE TABLE geometrias(

);

CREATE TABLE eventos(

);
