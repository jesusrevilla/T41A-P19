-- Alta de Materia Prima (con número de parte)
CREATE OR REPLACE PROCEDURE sp_materia_prima_alta(
    p_numero_parte          VARCHAR,
    p_descripcion           TEXT,
    p_ancho_mm              NUMERIC,
    p_alto_mm               NUMERIC,
    p_dist_min_piezas_mm    NUMERIC,
    p_dist_min_borde_mm     NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO materia_prima (
        numero_parte,
        descripcion,
        ancho_mm,
        alto_mm,
        distancia_min_piezas_mm,
        distancia_min_borde_mm
    )
    VALUES (
        p_numero_parte,
        p_descripcion,
        p_ancho_mm,
        p_alto_mm,
        p_dist_min_piezas_mm,
        p_dist_min_borde_mm
    );
END;
$$;

-- Alta de Productos y piezas base
-- p_piezas_json: arreglo de objetos {nombre_pieza, indice_en_producto, area_mm2, tipo_geometria, datos}
CREATE OR REPLACE PROCEDURE sp_producto_alta_con_piezas(
    p_numero_parte          VARCHAR,
    p_descripcion           TEXT,
    p_elementos_por_pieza   INT,
    p_piezas_json           JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_producto_id   INT;
    v_pieza_json    JSONB;
    v_pieza_id      INT;
BEGIN
    INSERT INTO productos(numero_parte, descripcion, elementos_por_pieza)
    VALUES (p_numero_parte, p_descripcion, p_elementos_por_pieza)
    RETURNING id INTO v_producto_id;

    FOR v_pieza_json IN
        SELECT jsonb_array_elements(p_piezas_json)
    LOOP
        INSERT INTO piezas(
            producto_id,
            indice_en_producto,
            nombre_pieza
        )
        VALUES(
            v_producto_id,
            (v_pieza_json->>'indice_en_producto')::INT,
            v_pieza_json->>'nombre_pieza'
        )
        RETURNING id INTO v_pieza_id;

        INSERT INTO geometrias(
            pieza_id,
            tipo_geometria,
            datos,
            area_mm2
        )
        VALUES(
            v_pieza_id,
            v_pieza_json->>'tipo_geometria',
            v_pieza_json->'datos',
            (v_pieza_json->>'area_mm2')::NUMERIC
        );
    END LOOP;
END;
$$;
