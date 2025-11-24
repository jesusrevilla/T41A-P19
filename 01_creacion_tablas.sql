DROP TABLE IF EXISTS eventos CASCADE;
DROP TABLE IF EXISTS configuraciones CASCADE;
DROP TABLE IF EXISTS geometrias CASCADE;
DROP TABLE IF EXISTS piezas CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS materia_prima CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- ROLES LÓGICOS
CREATE TABLE roles (
    id              SERIAL PRIMARY KEY,
    nombre_rol      VARCHAR(50) UNIQUE NOT NULL
);

-- USUARIOS DEL SISTEMA
CREATE TABLE usuarios (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    username        VARCHAR(50) UNIQUE NOT NULL,
    email           VARCHAR(120) UNIQUE NOT NULL,
    rol_id          INT REFERENCES roles(id),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- MATERIA PRIMA LAMINAR
CREATE TABLE materia_prima (
    id                      SERIAL PRIMARY KEY,
    numero_parte            VARCHAR(50) UNIQUE NOT NULL,
    descripcion             TEXT,
    ancho_mm                NUMERIC(10,2) NOT NULL,
    alto_mm                 NUMERIC(10,2) NOT NULL,
    distancia_min_piezas_mm NUMERIC(10,2) NOT NULL,
    distancia_min_borde_mm  NUMERIC(10,2) NOT NULL,
    area_total_mm2          NUMERIC(20,2) GENERATED ALWAYS AS (ancho_mm * alto_mm) STORED,
    porcentaje_utilizacion  NUMERIC(5,2) NOT NULL DEFAULT 0
);

-- PRODUCTOS
CREATE TABLE productos (
    id                      SERIAL PRIMARY KEY,
    numero_parte            VARCHAR(50) UNIQUE NOT NULL,
    descripcion             TEXT NOT NULL,
    elementos_por_pieza     INT NOT NULL DEFAULT 1
);

-- PIEZAS (cada instancia colocada de un producto)
CREATE TABLE piezas (
    id                  SERIAL PRIMARY KEY,
    producto_id         INT NOT NULL REFERENCES productos(id),
    materia_prima_id    INT REFERENCES materia_prima(id),
    indice_en_producto  INT NOT NULL DEFAULT 1,
    nombre_pieza        VARCHAR(100) NOT NULL,
    posicion_x_mm       NUMERIC(10,2) DEFAULT 0,
    posicion_y_mm       NUMERIC(10,2) DEFAULT 0,
    angulo_deg          NUMERIC(7,2) DEFAULT 0
);

-- GEOMETRÍA DE LAS PIEZAS
CREATE TABLE geometrias (
    id                  SERIAL PRIMARY KEY,
    pieza_id            INT NOT NULL REFERENCES piezas(id) ON DELETE CASCADE,
    tipo_geometria      VARCHAR(30) NOT NULL,  -- 'segmento','arco','figura_cerrada', etc.
    datos               JSONB NOT NULL,        -- coordenadas, radios, etc.
    area_mm2            NUMERIC(20,2) NOT NULL
);

-- CONFIGURACIÓN GLOBAL (por ejemplo parámetros de optimización)
CREATE TABLE configuraciones (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(50) UNIQUE NOT NULL,
    parametros      JSONB NOT NULL,
    actualizado_en  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- EVENTOS JSON
CREATE TABLE eventos (
    id              SERIAL PRIMARY KEY,
    pieza_id        INT REFERENCES piezas(id),
    tipo_evento     VARCHAR(50) NOT NULL,      -- 'rotacion','ajuste','layout', etc.
    payload         JSONB NOT NULL,
    procesado       BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
