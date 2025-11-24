CREATE EXTENSION IF NOT EXISTS pgcrypto; --se usa para las contraseñas

-- Tabla de Roles
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL -- 'Administrador', 'Operador'
);

-- Tabla de Usuarios
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL, 
    rol_id INT REFERENCES roles(id),
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Materia Prima
CREATE TABLE materia_prima (
    numero_parte VARCHAR(50) PRIMARY KEY, 
    tipo_material VARCHAR(50) NOT NULL,
    dimensiones JSONB NOT NULL,       
    parametros_corte JSONB NOT NULL,  
    stock_disponible INT DEFAULT 0 CHECK (stock_disponible >= 0)
);

CREATE TABLE productos (
    numero_parte VARCHAR(50) PRIMARY KEY,
    descripcion TEXT NOT NULL,
    fecha_alta TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE piezas (
    id SERIAL PRIMARY KEY, 
    producto_numero_parte VARCHAR(50) REFERENCES productos(numero_parte) ON DELETE CASCADE,
    nombre_pieza VARCHAR(100) NOT NULL,
    cantidad_requerida INT DEFAULT 1
);

-- Tabla de Geometrías
CREATE TABLE geometrias_pieza (
    id SERIAL PRIMARY KEY,
    pieza_id INT REFERENCES piezas(id) ON DELETE CASCADE,
    orden_secuencia INT NOT NULL,
    tipo_segmento VARCHAR(20) CHECK (tipo_segmento IN ('LINEA', 'ARCO', 'CIRCULO', 'POLIGONO')),
    datos_geometricos JSONB NOT NULL 
);

-- Hoja de Corte 
CREATE TABLE hojas_corte (
    id SERIAL PRIMARY KEY,
    mp_numero_parte VARCHAR(50) REFERENCES materia_prima(numero_parte),
    usuario_id INT REFERENCES usuarios(id),
    
    -- Calculados automáticamente
    area_total_mm2 NUMERIC(15,2),
    area_ocupada_mm2 NUMERIC(15,2) DEFAULT 0,
    porcentaje_utilizacion NUMERIC(5,2) DEFAULT 0,
    
    estado VARCHAR(20) DEFAULT 'PLANIFICACION' CHECK (estado IN ('PLANIFICACION', 'EN_PROCESO', 'FINALIZADO')),
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Piezas Colocadas 
CREATE TABLE piezas_colocadas (
    id SERIAL PRIMARY KEY,
    hoja_corte_id INT REFERENCES hojas_corte(id) ON DELETE CASCADE,
    pieza_id INT REFERENCES piezas(id),
    
    -- Coordenadas y estado final 
    posicion_x NUMERIC(10,2) NOT NULL,
    posicion_y NUMERIC(10,2) NOT NULL,
    rotacion_grados NUMERIC(6,2) DEFAULT 0,
    
    geometria_final JSONB
);

-- Eventos de Optimización 
CREATE TABLE eventos_optimizacion (
    id SERIAL PRIMARY KEY,
    hoja_corte_id INT REFERENCES hojas_corte(id) ON DELETE CASCADE,
    tipo_evento VARCHAR(50), -- 'ROTACION', 'DESPLAZAMIENTO'
    datos_evento JSONB NOT NULL, 
    fecha_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
