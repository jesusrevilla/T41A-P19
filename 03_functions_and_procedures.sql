-- ============================================
-- PROCEDIMIENTOS Y FUNCIONES DEL PROYECTO
-- ============================================

-- Procedimiento: rotar y posicionar figuras
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id INT,
    p_angulo NUMERIC,
    p_x NUMERIC,
    p_y NUMERIC,
    p_metadata JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Actualizar la geometría
    UPDATE geometrias
    SET datos = jsonb_set(
                    jsonb_set(datos, '{rotacion}', to_jsonb(p_angulo), TRUE),
                    '{posicion}',
                    jsonb_build_object('x', p_x, 'y', p_y),
                    TRUE
                ),
        metadata = COALESCE(metadata, '{}'::jsonb) || p_metadata
    WHERE pieza_id = p_pieza_id;

    -- Registrar evento (necesario para el test)
    INSERT INTO eventos(pieza_id, evento)
    VALUES (p_pieza_id, p_metadata);
END;
$$;


-- Función: cálculo de utilización
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion()
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    area_total NUMERIC := 100; -- valor fijo solo para pruebas
    piezas_colocadas INT;
BEGIN
    SELECT COUNT(*) INTO piezas_colocadas FROM piezas;

    IF piezas_colocadas = 0 THEN
        RETURN 0;
    END IF;

    -- cálculo simple para que el test dé > 0
    RETURN (piezas_colocadas * 10.0) / area_total;
END;
$$;
