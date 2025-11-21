-- DESCRIPCION: Alta de materia prima, productos y geometrías

CREATE OR REPLACE FUNCTION sp_alta_materia_prima(
    p_numero_parte VARCHAR,
    p_ancho NUMERIC,
    p_alto NUMERIC,
    p_dist_min_piezas NUMERIC DEFAULT 0,
    p_dist_min_borde NUMERIC DEFAULT 0,
    p_stock_inicial INT DEFAULT 0
) RETURNS INTEGER AS $$
DECLARE
    v_id_nuevo INT;
BEGIN
    IF p_ancho <= 0 OR p_alto <= 0 THEN
        RAISE EXCEPTION 'Las dimensiones deben ser mayores a 0';
    END IF;

    INSERT INTO materia_prima (
        numero_parte, ancho, alto, distancia_min_piezas, distancia_min_borde, stock_disponible
    ) VALUES (
        p_numero_parte, p_ancho, p_alto, p_dist_min_piezas, p_dist_min_borde, p_stock_inicial
    ) RETURNING id_materia INTO v_id_nuevo;

    RETURN v_id_nuevo;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_alta_producto(
    p_numero_parte VARCHAR,
    p_descripcion TEXT
) RETURNS INTEGER AS $$
DECLARE
    v_id_prod INT;
BEGIN
    INSERT INTO productos (numero_parte, descripcion)
    VALUES (p_numero_parte, p_descripcion)
    RETURNING id_producto INTO v_id_prod;
    RETURN v_id_prod;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_agregar_pieza(
    p_id_producto INT,
    p_nombre_pieza VARCHAR,
    p_cantidad INT,
    p_area_base NUMERIC DEFAULT 0
) RETURNS INTEGER AS $$
DECLARE
    v_id_pieza INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        RAISE EXCEPTION 'El Producto ID % no existe', p_id_producto;
    END IF;

    INSERT INTO piezas (id_producto, nombre_pieza, cantidad_requerida, area_base)
    VALUES (p_id_producto, p_nombre_pieza, p_cantidad, p_area_base)
    RETURNING id_pieza INTO v_id_pieza;
    RETURN v_id_pieza;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_agregar_geometria(
    p_id_pieza INT,
    p_orden INT,
    p_tipo VARCHAR,
    p_json_params JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO geometrias (id_pieza, orden_secuencia, tipo_componente, parametros_geo)
    VALUES (p_id_pieza, p_orden, p_tipo, p_json_params);
END;
$$ LANGUAGE plpgsql;