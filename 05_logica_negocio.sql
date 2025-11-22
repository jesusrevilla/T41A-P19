-- Procedimiento sp_rotar_posicionar_figuras
-- Recibe ID y JSON con nuevas coordenadas y rotación
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id INT,
    p_evento_json JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nueva_x NUMERIC;
    v_nueva_y NUMERIC;
    v_nuevo_angulo NUMERIC;
BEGIN
    -- Extraer datos del JSON
    v_nueva_x := (p_evento_json->>'x')::NUMERIC;
    v_nueva_y := (p_evento_json->>'y')::NUMERIC;
    v_nuevo_angulo := (p_evento_json->>'rotacion')::NUMERIC;

    -- Actualizar la pieza
    UPDATE piezas
    SET posicion_x = v_nueva_x,
        posicion_y = v_nueva_y,
        rotacion_grados = v_nuevo_angulo
    WHERE id = p_pieza_id;

    -- Registrar que el evento fue procesado
    RAISE NOTICE 'Pieza % actualizada: X=%, Y=%, Angulo=%', p_pieza_id, v_nueva_x, v_nueva_y, v_nuevo_angulo;
END;
$$;
