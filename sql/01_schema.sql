-- Tablas principales: roles, usuarios, materia_prima, productos, piezas, eventos

CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  nombre TEXT UNIQUE NOT NULL
);

INSERT INTO roles (nombre) VALUES ('Administrador') ON CONFLICT DO NOTHING;
INSERT INTO roles (nombre) VALUES ('Operador') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  creado_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS materia_prima (
  id SERIAL PRIMARY KEY,
  numero_parte TEXT UNIQUE NOT NULL,
  ancho NUMERIC NOT NULL CHECK (ancho > 0),
  alto NUMERIC NOT NULL CHECK (alto > 0),
  thickness NUMERIC DEFAULT 0,
  min_dist_piece NUMERIC DEFAULT 0,
  min_dist_edge NUMERIC DEFAULT 0,
  area NUMERIC GENERATED ALWAYS AS (ancho * alto) STORED,
  last_utilizacion NUMERIC DEFAULT 0,
  creado_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS productos (
  id SERIAL PRIMARY KEY,
  numero_parte TEXT UNIQUE NOT NULL,
  descripcion TEXT,
  creado_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS piezas (
  id SERIAL PRIMARY KEY,
  producto_id INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  cantidad INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  geometria JSONB NOT NULL,
  area NUMERIC NOT NULL DEFAULT 0,
  bbox JSONB,
  creado_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS eventos (
  id SERIAL PRIMARY KEY,
  pieza_id INTEGER REFERENCES piezas(id) ON DELETE CASCADE,
  evento JSONB NOT NULL,
  creado_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
