-- Alta de Materia Prima
CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
    p_num_parte VARCHAR,
    p_ancho NUMERIC,
    p_alto NUMERIC,
    p_min_piezas NUMERIC,
    p_min_orilla NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO materia_prima (numero_parte, dimension_ancho, dimension_alto, distancia_min_piezas, distancia_min_orilla)
    VALUES (p_num_parte, p_ancho, p_alto, p_min_piezas, p_min_orilla);
END;
$$;

-- Alta de Productos y su primera pieza base
CREATE OR REPLACE PROCEDURE sp_alta_producto(
    p_num_parte VARCHAR,
    p_desc TEXT,
    p_cantidad INT,
    p_tipo_geom VARCHAR,
    p_datos_geom JSONB,
    p_area_pieza NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_prod_id INT;
    v_pieza_id INT;
BEGIN
    -- Crear Producto
    INSERT INTO productos (numero_parte, descripcion, cantidad_piezas)
    VALUES (p_num_parte, p_desc, p_cantidad)
    RETURNING id INTO v_prod_id;

    -- Crear Pieza Base 
    INSERT INTO piezas (producto_id, nombre_pieza)
    VALUES (v_prod_id, 'Pieza Base ' || p_num_parte)
    RETURNING id INTO v_pieza_id;

    -- Asignar Geometría
    INSERT INTO geometrias (pieza_id, tipo_geometria, datos_forma, area)
    VALUES (v_pieza_id, p_tipo_geom, p_datos_geom, p_area_pieza);
END;
$$;
