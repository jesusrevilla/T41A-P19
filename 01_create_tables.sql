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

CREATE TABLE geometrias (
    id_geometria SERIAL PRIMARY KEY,
    id_pieza INT NOT NULL,
    -- Aquí usamos el tipo nativo de PostgreSQL
    -- Usamos 'POLYGON' porque permite calcular áreas para tu función de utilización
    forma_geometrica POLYGON NOT NULL,
    -- Metadatos útiles para optimización
    es_figura_cerrada BOOLEAN DEFAULT TRUE,
    -- Relación: Si borras la pieza, se borra su geometría
    CONSTRAINT fk_pieza FOREIGN KEY (id_pieza) 
    REFERENCES pieza(id) ON DELETE CASCADE
);

CREATE TABLE evento (
  id SERIAL PRIMARY KEY NOT NULL,
  id_materiap INT REFERENCES materia_prima(id) NOT NULL,
  id_usuario INT REFERENCES usuario (id) NOT NULL,
  fecha_hora TIMESTAMP NOT NULL,
  tipo_evento TEXT NOT NULL,
  Descripcion TEXT NOT NULL
);
