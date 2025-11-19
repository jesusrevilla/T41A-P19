-- ============================================
-- PROCEDURE: Rotar y Posicionar Figuras
-- ============================================

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
    UPDATE geometrias
    SET datos = jsonb_set(
                    jsonb_set(datos, '{rotacion}', to_jsonb(p_angulo)),
                    '{posicion}',
                    jsonb_build_object('x', p_x, 'y', p_y)
                ),
        metadata = COALESCE(metadata, '{}'::jsonb) || p_metadata
    WHERE pieza_id = p_pieza_id;
END;
$$;


-- ============================================
-- FUNCTION: Calcular utilización (dummy)
-- ============================================

CREATE OR REPLACE FUNCTION fn_calcular_utilizacion()
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    total_piezas INTEGER;
BEGIN
    -- Se usa COUNT para asegurar que la función regresa algo válido
    SELECT COUNT(*) INTO total_piezas FROM geometrias;

    RETURN total_piezas;
END;
$$;
