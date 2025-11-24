-- -------------------------------------------------------------------------
-- 2. FUNCIONES Y PROCEDIMIENTOS ALMACENADOS
-- -------------------------------------------------------------------------

-- 2.1. Función Geométrica Simulada
CREATE OR REPLACE FUNCTION fn_calcular_area_geom(p_geometria TEXT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    -- Retorna un área fija simulada (100x100 = 10,000) para la prueba CI.
    RETURN 10000.0;
END;
$$;

-- 2.2. Función para Cálculo de Utilización (fn_calcular_utilizacion)
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(
    p_opt_corte_id BIGINT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_total_materia NUMERIC;
    v_area_utilizada NUMERIC := 0;
    v_largo NUMERIC;
    v_ancho NUMERIC;
BEGIN
    SELECT mp.dimension_largo, mp.dimension_ancho
    INTO v_largo, v_ancho
    FROM optimizacion_corte oc
    JOIN materia_prima mp ON oc.materia_prima_id = mp.materia_prima_id
    WHERE oc.opt_corte_id = p_opt_corte_id;

    v_area_total_materia := v_largo * v_ancho;

    IF v_area_total_materia = 0 THEN RETURN 0.0; END IF;

    SELECT COALESCE(SUM(fn_calcular_area_geom(pc.geometria_actual)), 0)
    INTO v_area_utilizada
    FROM piezas_colocadas pc
    WHERE pc.opt_corte_id = p_opt_corte_id;

    RETURN (v_area_utilizada / v_area_total_materia) * 100.0;
END;
$$;


-- 2.3. Procedimiento para Rotación y Posicionamiento (sp_rotar_posicionar_figuras)
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_colocada_id BIGINT,
    p_angulo_rotacion NUMERIC,
    p_posicion_x NUMERIC,
    p_posicion_y NUMERIC,
    p_evento_json JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_opt_corte_id BIGINT;
    v_geometria_original TEXT;
    v_nueva_geometria TEXT;
BEGIN
    SELECT pc.opt_corte_id, p.geometria_original
    INTO v_opt_corte_id, v_geometria_original
    FROM piezas_colocadas pc
    JOIN piezas p ON pc.pieza_id = p.pieza_id
    WHERE pc.pieza_colocada_id = p_pieza_colocada_id;

    IF v_opt_corte_id IS NULL THEN
        RAISE EXCEPTION 'La pieza colocada con ID % no existe.', p_pieza_colocada_id;
    END IF;

    -- Simulación de Transformación:
    v_nueva_geometria := v_geometria_original || 
                         ' [Rot:' || p_angulo_rotacion || ', Pos: ' || p_posicion_x || ',' || p_posicion_y || ']';


    -- Actualizar la posición y rotación
    UPDATE piezas_colocadas
    SET
        geometria_actual = v_nueva_geometria,
        rotacion_grados = p_angulo_rotacion,
        posicion_x = p_posicion_x,
        posicion_y = p_posicion_y
    WHERE pieza_colocada_id = p_pieza_colocada_id;

    -- Registrar el evento JSON
    INSERT INTO eventos_optimizacion (
        pieza_colocada_id, opt_corte_id, tipo_evento, payload
    )
    VALUES (
        p_pieza_colocada_id, v_opt_corte_id, 'ROTACION_POSICIONAMIENTO', p_evento_json
    );
END;
$$;

-- 2.4. Procedimiento para dar de alta de Materia Prima
CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
    p_numero_parte VARCHAR,
    p_dimension_largo NUMERIC,
    p_dimension_ancho NUMERIC,
    p_distancia_min_piezas NUMERIC,
    p_distancia_min_orilla NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO materia_prima (
        numero_parte,
        dimension_largo,
        dimension_ancho,
        distancia_min_piezas,
        distancia_min_orilla
    )
    VALUES (
        p_numero_parte,
        p_dimension_largo,
        p_dimension_ancho,
        p_distancia_min_piezas,
        p_distancia_min_orilla
    );

    RAISE NOTICE 'Materia prima "%" registrada correctamente.', p_numero_parte;
END;
$$;

-- 2.5. Procedimiento para dar de alta de productos
CREATE OR REPLACE PROCEDURE sp_alta_producto(
    p_numero_parte VARCHAR,
    p_descripcion TEXT,
    p_materia_prima_id INT,
    p_nombre_pieza VARCHAR,
    p_cantidad_elementos INT,
    p_geometria TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_producto_id INT;
BEGIN
    -- Insertar producto
    INSERT INTO productos (
        numero_parte,
        descripcion,
        materia_prima_base_id
    )
    VALUES (
        p_numero_parte,
        p_descripcion,
        p_materia_prima_id
    )
    RETURNING producto_id INTO v_producto_id;

    -- Crear la pieza base asociada al producto
    INSERT INTO piezas (
        producto_id,
        nombre_pieza,
        cantidad_elementos,
        geometria_original
    )
    VALUES (
        v_producto_id,
        p_nombre_pieza,
        p_cantidad_elementos,
        p_geometria
    );

    RAISE NOTICE 'Producto "%" y su pieza asociada registrados correctamente.', p_numero_parte;
END;
$$;
