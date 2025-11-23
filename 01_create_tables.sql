-- 01_crear_tablas.sql
-- Esquema y tablas base

CREATE SCHEMA IF NOT EXISTS corte;
SET search_path TO corte, public;

-- Para hash de contraseñas
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ====== TABLAS DE SEGURIDAD (LÓGICAS DE APLICACIÓN) ======
CREATE TABLE IF NOT EXISTS roles (
    id              SERIAL PRIMARY KEY,
    nombre          TEXT UNIQUE NOT NULL CHECK (nombre IN ('Administrador','Operador')),
    descripcion     TEXT
);

CREATE TABLE IF NOT EXISTS usuarios (
    id              SERIAL PRIMARY KEY,
    username        TEXT UNIQUE NOT NULL,
    email           TEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    rol_id          INT NOT NULL REFERENCES roles(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en       TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.actualizado_en := NOW();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_usuarios_updated ON usuarios;
CREATE TRIGGER trg_usuarios_updated
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ====== MATERIA PRIMA ======
CREATE TABLE IF NOT EXISTS materia_prima (
    id                              SERIAL PRIMARY KEY,
    numero_parte                    TEXT UNIQUE NOT NULL,
    descripcion                     TEXT,
    ancho                           NUMERIC(18,6) NOT NULL CHECK (ancho > 0),
    alto                            NUMERIC(18,6) NOT NULL CHECK (alto > 0),
    unidad                          TEXT NOT NULL DEFAULT 'mm' CHECK (unidad IN ('mm','cm','m')),
    distancia_minima_entre_piezas   NUMERIC(18,6) NOT NULL DEFAULT 0 CHECK (distancia_minima_entre_piezas >= 0),
    distancia_minima_a_orilla       NUMERIC(18,6) NOT NULL DEFAULT 0 CHECK (distancia_minima_a_orilla >= 0),
    utilizacion_pct                 NUMERIC(9,4) NOT NULL DEFAULT 0,
    creado_en                       TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en                  TIMESTAMP NOT NULL DEFAULT NOW()
);
DROP TRIGGER IF EXISTS trg_materia_prima_updated ON materia_prima;
CREATE TRIGGER trg_materia_prima_updated
BEFORE UPDATE ON materia_prima
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ====== PRODUCTOS Y PIEZAS ======
CREATE TABLE IF NOT EXISTS productos (
    id                      SERIAL PRIMARY KEY,
    numero_parte            TEXT UNIQUE NOT NULL,
    descripcion             TEXT,
    geometria_base          JSONB, -- Opcional: plantilla
    cantidad_elementos_por_pieza INT NOT NULL DEFAULT 1 CHECK (cantidad_elementos_por_pieza > 0),
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW()
);
DROP TRIGGER IF EXISTS trg_productos_updated ON productos;
CREATE TRIGGER trg_productos_updated
BEFORE UPDATE ON productos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS piezas (
    id                  SERIAL PRIMARY KEY,
    producto_id         INT NOT NULL REFERENCES productos(id) ON UPDATE CASCADE ON DELETE CASCADE,
    materia_prima_id    INT NULL REFERENCES materia_prima(id) ON UPDATE CASCADE ON DELETE SET NULL,
    etiqueta            TEXT,
    estado              TEXT NOT NULL DEFAULT 'nuevo' CHECK (estado IN ('nuevo','colocado','ajustado')),
    angulo_deg          DOUBLE PRECISION NOT NULL DEFAULT 0,       -- última rotación aplicada
    pos_x               NUMERIC(18,6) NOT NULL DEFAULT 0,          -- última traslación aplicada
    pos_y               NUMERIC(18,6) NOT NULL DEFAULT 0,
    -- BBox de la pieza (union de bbox de sus geometrias)
    bbox_xmin           NUMERIC(18,6),
    bbox_ymin           NUMERIC(18,6),
    bbox_xmax           NUMERIC(18,6),
    bbox_ymax           NUMERIC(18,6),
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW()
);
DROP TRIGGER IF EXISTS trg_piezas_updated ON piezas;
CREATE TRIGGER trg_piezas_updated
BEFORE UPDATE ON piezas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ====== GEOMETRÍAS ======
-- tipo: 'segmento','arco','poligono','circulo','rectangulo'
-- params: JSONB con estructura esperada por tipo
-- factor_area: +1 suma área, -1 resta (agujeros)
CREATE TABLE IF NOT EXISTS geometrias (
    id              SERIAL PRIMARY KEY,
    pieza_id        INT NOT NULL REFERENCES piezas(id) ON UPDATE CASCADE ON DELETE CASCADE,
    tipo            TEXT NOT NULL CHECK (tipo IN ('segmento','arco','poligono','circulo','rectangulo')),
    params          JSONB NOT NULL,
    factor_area     SMALLINT NOT NULL DEFAULT 1 CHECK (factor_area IN (-1,1)),
    area            NUMERIC(30,8) NOT NULL DEFAULT 0,
    bbox_xmin       NUMERIC(18,6),
    bbox_ymin       NUMERIC(18,6),
    bbox_xmax       NUMERIC(18,6),
    bbox_ymax       NUMERIC(18,6),
    orden           INT NOT NULL DEFAULT 1,
    creado_en       TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_geometrias_pieza ON geometrias(pieza_id);
CREATE INDEX IF NOT EXISTS idx_geometrias_params_gin ON geometrias USING GIN (params);

DROP TRIGGER IF EXISTS trg_geometrias_updated ON geometrias;
CREATE TRIGGER trg_geometrias_updated
BEFORE UPDATE ON geometrias
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ====== EVENTOS (JSON) ======
CREATE TABLE IF NOT EXISTS eventos (
    id              SERIAL PRIMARY KEY,
    pieza_id        INT NOT NULL REFERENCES piezas(id) ON UPDATE CASCADE ON DELETE CASCADE,
    tipo            TEXT NOT NULL,
    payload         JSONB NOT NULL,
    creado_en       TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_eventos_pieza ON eventos(pieza_id);
