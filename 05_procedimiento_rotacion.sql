CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id      INT,
    p_angulo_deg    NUMERIC,
    p_pos_x_mm      NUMERIC,
    p_pos_y_mm      NUMERIC,
    p_evento_json   JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Actualiza la pieza (posición y rotación)
    UPDATE piezas
    SET angulo_deg = p_angulo_deg,
        posicion_x_mm = p_pos_x_mm,
        posicion_y_mm = p_pos_y_mm
    WHERE id = p_pieza_id;

    -- registrar meta-datos de rotación/posición en geometrías
    UPDATE geometrias
    SET datos = datos || jsonb_build_object(
        'ultima_rotacion_deg', p_angulo_deg,
        'ultima_posicion', jsonb_build_object('x', p_pos_x_mm, 'y', p_pos_y_mm)
    )
    WHERE pieza_id = p_pieza_id;

    -- Registra el evento
    INSERT INTO eventos(pieza_id, tipo_evento, payload, procesado)
    VALUES (p_pieza_id, 'rotacion_posicion_directa', p_evento_json, TRUE);
END;
$$;
